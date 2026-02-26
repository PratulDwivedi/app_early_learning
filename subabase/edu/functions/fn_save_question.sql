CREATE OR REPLACE FUNCTION edu.fn_save_question(
  p_id                    bigint  DEFAULT NULL,
  p_question_type_id      bigint  DEFAULT NULL,
  p_name                  text    DEFAULT NULL,
  p_name_audio_prompt     text    DEFAULT NULL,
  p_options               text    DEFAULT NULL,
  p_options_audio_prompt  text    DEFAULT NULL,
  p_correct_answer        text    DEFAULT NULL,
  p_hint                  text    DEFAULT NULL,
  p_image_url             text    DEFAULT NULL,
  p_sort_order            smallint DEFAULT 0,
  p_data                  jsonb   DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
/*
============================================================================================
Created By    : Pratul Dwivedi
Created Date  : 25-Feb-26
Description   : Insert or update a single question.
                Validates question_type_id exists and belongs to the same tenant.
============================================================================================
*/
DECLARE
  v_id          bigint;
  v_tenant_id   bigint;
  v_user_id     bigint;
  v_caller_id   bigint;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM fn_get_request_context('edu.fn_save_question');

    -- ── Validations ──────────────────────────────────────────────

    IF p_question_type_id IS NULL THEN
      RAISE EXCEPTION 'question_type_id is required.';
    END IF;

    IF p_correct_answer IS NULL OR trim(p_correct_answer) = '' THEN
      RAISE EXCEPTION 'correct_answer is required.';
    END IF;

    -- Ensure question_type belongs to same tenant
    IF NOT EXISTS (
      SELECT 1 FROM edu.question_types
      WHERE id = p_question_type_id
        AND tenant_id = v_tenant_id
        AND is_active = true
    ) THEN
      RAISE EXCEPTION 'question_type_id % not found or inactive for this tenant.', p_question_type_id;
    END IF;

    -- ── Insert ───────────────────────────────────────────────────

    IF p_id IS NULL OR p_id = 0 THEN

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
        p_question_type_id,
        p_name,
        p_name_audio_prompt,
        p_options,
        p_options_audio_prompt,
        p_correct_answer,
        p_hint,
        p_image_url,
        p_sort_order,
        p_data,
        TRUE,
        v_tenant_id,
        v_user_id,
        now()
      )
      RETURNING id INTO v_id;

    -- ── Update ───────────────────────────────────────────────────

    ELSE

      UPDATE edu.questions SET
        question_type_id      = p_question_type_id,
        name                  = p_name,
        name_audio_prompt     = p_name_audio_prompt,
        options               = p_options,
        options_audio_prompt  = p_options_audio_prompt,
        correct_answer        = p_correct_answer,
        hint                  = p_hint,
        image_url             = p_image_url,
        sort_order            = p_sort_order,
        data                  = p_data,
        updated_by            = v_user_id,
        updated_at            = now()
      WHERE id = p_id
        AND tenant_id = v_tenant_id
      RETURNING id INTO v_id;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Question ID % not found or access denied.', p_id;
      END IF;

    END IF;

    RETURN fn_response_success(
      p_data          := jsonb_build_object('id', v_id),
      p_message       := format('Question ID %s saved successfully.', v_id),
      p_total_records := 1,
      p_page_size     := 1,
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN fn_response_error(
      p_function_name := 'edu.fn_save_question',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$;