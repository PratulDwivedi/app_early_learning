CREATE OR REPLACE FUNCTION edu.fn_save_questions(
  p_questions jsonb DEFAULT NULL   -- array of question objects
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
/*
============================================================================================
Created By    : Pratul Dwivedi
Created Date  : 25-Feb-26
Description   : Bulk insert/update questions from a JSONB array.
                Each element mirrors the params of fn_save_question.
                Processes all rows and collects per-row errors — does NOT
                stop on first failure so caller gets a full error report.
                Rolls back ALL rows if any error occurs (single transaction).

  Sample input:
  [
    {
      "question_type_id": 1,
      "name": "What sound does A make?",
      "name_audio_prompt": "audio/q1.mp3",
      "options": "Apple,Ant,Ball,Cat",
      "options_audio_prompt": "audio/opts1.mp3",
      "correct_answer": "Apple",
      "hint": "Starts with A",
      "image_url": "img/apple.png",
      "sort_order": 1,
      "data": {}
    },
    {
      "question_type_id": 2,
      "name": "Which letter is this?",
      "correct_answer": "B",
      "sort_order": 2
    }
  ]
============================================================================================
*/
DECLARE
  v_tenant_id     bigint;
  v_user_id       bigint;
  v_caller_id     bigint;
  v_row           jsonb;
  v_idx           int := 0;
  v_inserted      int := 0;
  v_updated       int := 0;
  v_failed        int := 0;
  v_errors        jsonb := '[]'::jsonb;
  v_id            bigint;
  v_question_type_id  bigint;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM fn_get_request_context('edu.fn_save_questions');

    -- ── Basic input validation ────────────────────────────────────

    IF p_questions IS NULL OR jsonb_array_length(p_questions) = 0 THEN
      RAISE EXCEPTION 'p_questions array is required and cannot be empty.';
    END IF;

    IF jsonb_array_length(p_questions) > 500 THEN
      RAISE EXCEPTION 'Bulk upload limit is 500 questions per call. Received %.', jsonb_array_length(p_questions);
    END IF;

    -- ── Loop through each row ─────────────────────────────────────

    FOR v_row IN SELECT jsonb_array_elements(p_questions)
    LOOP
      v_idx := v_idx + 1;

      BEGIN
        v_question_type_id := (v_row->>'question_type_id')::bigint;

        -- Row level validations
        IF v_question_type_id IS NULL THEN
          RAISE EXCEPTION 'question_type_id is required.';
        END IF;

        IF v_row->>'correct_answer' IS NULL OR trim(v_row->>'correct_answer') = '' THEN
          RAISE EXCEPTION 'correct_answer is required.';
        END IF;

        -- Validate question_type belongs to tenant
        IF NOT EXISTS (
          SELECT 1 FROM edu.question_types
          WHERE id = v_question_type_id
            AND tenant_id = v_tenant_id
            AND is_active = true
        ) THEN
          RAISE EXCEPTION 'question_type_id % not found or inactive for this tenant.', v_question_type_id;
        END IF;

        v_id := (v_row->>'id')::bigint;

        -- ── Insert ───────────────────────────────────────────────

        IF v_id IS NULL OR v_id = 0 THEN

          INSERT INTO edu.questions (
            question_type_id,
            name,
            name_audio_prompt,
            options,
            options_audio_prompt,
            correct_answer,
            hint,
            image_url,
            sort_order,
            data,
            is_active,
            tenant_id,
            created_by,
            created_at
          ) VALUES (
            v_question_type_id,
            v_row->>'name',
            v_row->>'name_audio_prompt',
            v_row->>'options',
            v_row->>'options_audio_prompt',
            v_row->>'correct_answer',
            v_row->>'hint',
            v_row->>'image_url',
            COALESCE((v_row->>'sort_order')::smallint, 0),
            v_row->'data',
            TRUE,
            v_tenant_id,
            v_user_id,
            now()
          )
          RETURNING id INTO v_id;

          v_inserted := v_inserted + 1;

        -- ── Update ───────────────────────────────────────────────

        ELSE

          UPDATE edu.questions SET
            question_type_id      = v_question_type_id,
            name                  = v_row->>'name',
            name_audio_prompt     = v_row->>'name_audio_prompt',
            options               = v_row->>'options',
            options_audio_prompt  = v_row->>'options_audio_prompt',
            correct_answer        = v_row->>'correct_answer',
            hint                  = v_row->>'hint',
            image_url             = v_row->>'image_url',
            sort_order            = COALESCE((v_row->>'sort_order')::smallint, 0),
            data                  = v_row->'data',
            updated_by            = v_user_id,
            updated_at            = now()
          WHERE id = v_id
            AND tenant_id = v_tenant_id;

          IF NOT FOUND THEN
            RAISE EXCEPTION 'Question ID % not found or access denied.', v_id;
          END IF;

          v_updated := v_updated + 1;

        END IF;

      -- ── Per-row error: collect and continue ───────────────────

      EXCEPTION WHEN OTHERS THEN
        v_failed := v_failed + 1;
        v_errors := v_errors || jsonb_build_array(
          jsonb_build_object(
            'row',     v_idx,
            'input',   v_row,
            'error',   SQLERRM
          )
        );
      END;

    END LOOP;

    -- ── If any row failed, roll back everything ───────────────────

    IF v_failed > 0 THEN
      RAISE EXCEPTION 'BULK_PARTIAL_FAILURE';
    END IF;

    RETURN fn_response_success(
      p_data := jsonb_build_object(
        'inserted', v_inserted,
        'updated',  v_updated,
        'total',    v_inserted + v_updated
      ),
      p_message       := format('%s inserted, %s updated successfully.', v_inserted, v_updated),
      p_total_records := v_inserted + v_updated,
      p_page_size     := v_inserted + v_updated,
      p_page_index    := 1
    );

  EXCEPTION
    -- Return collected row errors to caller
    WHEN OTHERS THEN
      IF SQLERRM = 'BULK_PARTIAL_FAILURE' THEN
        RETURN fn_response_error(
          p_function_name := 'edu.fn_save_questions',
          p_message       := format('%s row(s) failed. All changes rolled back.', v_failed),
          p_data          := jsonb_build_object(
            'inserted', v_inserted,
            'updated',  v_updated,
            'failed',   v_failed,
            'errors',   v_errors
          ),
          p_tenant_id := v_tenant_id,
          p_user_id   := v_user_id
        );
      END IF;

      RETURN fn_response_error(
        p_function_name := 'edu.fn_save_questions',
        p_message       := SQLERRM,
        p_data          := '{}'::jsonb,
        p_tenant_id     := v_tenant_id,
        p_user_id       := v_user_id
      );
  END;
END;
$function$;