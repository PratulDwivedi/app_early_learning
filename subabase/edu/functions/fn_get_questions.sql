CREATE OR REPLACE FUNCTION edu.fn_get_questions (
  p_question_type_id  bigint   DEFAULT NULL::bigint,
  p_id                bigint   DEFAULT NULL::bigint,
  p_page_index        integer  DEFAULT 1,
  p_page_size         integer  DEFAULT 20
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    :
Created Date  :
Description   : Fetch paginated list of questions joined with question_types.
                Pagination (p_page_index / p_page_size) is applied PER question_type
                using ROW_NUMBER() PARTITION BY question_type_id.
                Output is a single flat data array.

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';

SELECT edu.fn_get_questions();
SELECT edu.fn_get_questions(p_question_type_id := 1);
SELECT edu.fn_get_questions(p_question_type_id := 1, p_page_index := 2, p_page_size := 10);
SELECT edu.fn_get_questions(p_id := 42);
================================================
*/
DECLARE
  v_tenant_id     bigint;
  v_user_id       bigint;
  v_caller_id     bigint;
  v_result        jsonb;
  v_total_records int;
  v_offset        int;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_get_questions');

    -- ── Validations ───────────────────────────────────────────

    IF p_page_index < 1 THEN
      RAISE EXCEPTION 'page_index must be >= 1.';
    END IF;

    IF p_page_size < 1 OR p_page_size > 100 THEN
      RAISE EXCEPTION 'page_size must be between 1 and 100.';
    END IF;

    v_offset := (p_page_index - 1) * p_page_size;

    -- ── Total count (distinct questions that would appear across all types) ───

    SELECT COUNT(*)
    INTO v_total_records
    FROM edu.questions q
    WHERE q.tenant_id  = v_tenant_id
      AND q.is_active  = true
      AND (p_question_type_id IS NULL OR q.question_type_id = p_question_type_id)
      AND (p_id        IS NULL OR q.id = p_id);

    -- ── Paginated result partitioned by question_type_id ─────────────────────

    SELECT COALESCE(jsonb_agg(row), '[]'::jsonb)
    INTO v_result
    FROM (
      SELECT jsonb_build_object(
        -- question fields
        'id',                     q.id,
        'question_type_id',       q.question_type_id,
        'name',                   q.name,
        'name_audio_prompt',      q.name_audio_prompt,
        'options',                q.options,
        'options_audio_prompt',   q.options_audio_prompt,
        'correct_answer',         q.correct_answer,
        'hint',                   q.hint,
        'image_url',              q.image_url,
        'sort_order',             q.sort_order,
        'data',                   q.data,
        'is_active',              q.is_active,
        'created_at',             q.created_at,
        'updated_at',             q.updated_at,
        -- question_type fields
        'question_type',          jsonb_build_object(
                                    'id',       qt.id,
                                    'name',     qt.name,
                                    'icon_url', qt.icon_url,
                                    'data',     qt.data
                                  )
      ) AS row
      FROM (
        SELECT q.*,
               ROW_NUMBER() OVER (
                 PARTITION BY q.question_type_id
                 ORDER BY q.sort_order ASC, q.id ASC
               ) AS rn
        FROM edu.questions q
        WHERE q.tenant_id  = v_tenant_id
          AND q.is_active  = true
          AND (p_question_type_id IS NULL OR q.question_type_id = p_question_type_id)
          AND (p_id        IS NULL OR q.id = p_id)
      ) q
      INNER JOIN edu.question_types qt
        ON  qt.id        = q.question_type_id
        AND qt.tenant_id = v_tenant_id
        AND qt.is_active = true
      WHERE q.rn > v_offset
        AND q.rn <= (v_offset + p_page_size)
      ORDER BY qt.id ASC, q.sort_order ASC, q.id ASC
    ) t;

    RETURN public.fn_response_success(
      p_data          := v_result,
      p_message       := 'Questions retrieved successfully.',
      p_total_records := v_total_records,
      p_page_size     := p_page_size,
      p_page_index    := p_page_index
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_get_questions',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$;