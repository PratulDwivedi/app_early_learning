CREATE OR REPLACE FUNCTION edu.fn_start_session(p_student_id bigint DEFAULT NULL::bigint, p_question_type_id bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : 
Created Date  : 
Description   : Starts a new session for a student.
                Fetches grade from edu.students.
                Blocks if student already has an IN_PROGRESS session.
                If student has an ABANDONED session for same question_type_id,
                resumes the same question set from session.data->>'question_ids'.
                Otherwise generates a fresh set, excluding already-correct questions,
                capped by question_types.data->>'no_of_questions_in_set'.
                Stores generated question_ids in session.data for resume support.
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_start_session(p_student_id := 1, p_question_type_id := 2);
================================================
*/
DECLARE
  v_tenant_id           bigint;
  v_user_id             bigint;
  v_caller_id           bigint;
  v_grade               smallint;
  v_session_id          bigint;
  v_questions           jsonb;
  v_question_ids        bigint[];
  v_no_of_questions     int;
  v_abandoned_session   record;
  v_is_resumed          boolean := false;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_start_session');

    -- ── Validations ──────────────────────────────────────────

    IF p_student_id IS NULL THEN
      RAISE EXCEPTION 'student_id is required.';
    END IF;

    IF p_question_type_id IS NULL THEN
      RAISE EXCEPTION 'question_type_id is required.';
    END IF;

    -- Validate question_type exists, belongs to tenant, read no_of_questions rule
    SELECT
      COALESCE((data->>'no_of_questions_in_set')::int, 10)  -- default 10 if rule not set
    INTO v_no_of_questions
    FROM edu.question_types
    WHERE id        = p_question_type_id
      AND tenant_id = v_tenant_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'question_type_id % not found or inactive for this tenant.', p_question_type_id;
    END IF;

    -- Fetch grade from students (also validates student + tenant)
    SELECT grade
    INTO v_grade
    FROM edu.students
    WHERE id        = p_student_id
      AND tenant_id = v_tenant_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Student ID % not found or inactive for this tenant.', p_student_id;
    END IF;

    -- Block if student already has an IN_PROGRESS session
    /*
    IF EXISTS (
      SELECT 1 FROM edu.sessions
      WHERE student_id = p_student_id
        AND tenant_id  = v_tenant_id
        AND status     = 'IN_PROGRESS'
    ) THEN
      RAISE EXCEPTION 'Student ID % already has an IN_PROGRESS session.', p_student_id;
    END IF;
*/
    -- ── Check for ABANDONED session (resume path) ─────────────
    -- If student abandoned a session for the same question_type_id,
    -- reuse the same question_ids stored in session.data

    SELECT id, data
    INTO v_abandoned_session
    FROM edu.sessions
    WHERE student_id = p_student_id
      AND tenant_id  = v_tenant_id
      AND status     = 'ABANDONED'
      AND (data->>'question_type_id')::bigint = p_question_type_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF FOUND AND v_abandoned_session.data ? 'question_ids' THEN
      -- Resume: pull stored question_ids from abandoned session
      SELECT ARRAY(
        SELECT jsonb_array_elements_text(v_abandoned_session.data->'question_ids')::bigint
      ) INTO v_question_ids;

      v_is_resumed := true;
    ELSE
      -- ── Fresh session: generate new question set ───────────
      -- Exclude questions student already answered correctly in any past session

      SELECT ARRAY(
        SELECT q.id
        FROM edu.questions q
        WHERE q.question_type_id = p_question_type_id
          AND q.tenant_id        = v_tenant_id
          AND q.is_active        = true
          -- exclude already correctly answered questions
          AND q.id NOT IN (
            SELECT sr.question_id
            FROM edu.session_responses sr
            INNER JOIN edu.sessions ses
              ON  ses.id         = sr.session_id
              AND ses.tenant_id  = v_tenant_id
            WHERE ses.student_id = p_student_id
              AND sr.is_correct  = true
              AND sr.tenant_id   = v_tenant_id
          )
        -- ORDER BY q.sort_order, q.id
        ORDER BY random()
        LIMIT v_no_of_questions            -- cap by rule from question_types.data
      ) INTO v_question_ids;

    END IF;

    -- ── Insert new session ───────────────────────────────────

    INSERT INTO edu.sessions (
      student_id,
      grade,
      total_questions,
      status,
      data,
      tenant_id,
      created_by,
      created_at
    ) VALUES (
      p_student_id,
      v_grade,
      COALESCE(array_length(v_question_ids, 1), 0),
      'IN_PROGRESS',
      jsonb_build_object(
        'question_type_id',  p_question_type_id,
        'question_ids',      to_jsonb(v_question_ids),   -- ← stored for resume
        'is_resumed',        v_is_resumed,
        'abandoned_session_id',
          CASE WHEN v_is_resumed THEN v_abandoned_session.id ELSE NULL END
      ),
      v_tenant_id,
      v_user_id,
      now()
    )
    RETURNING id INTO v_session_id;

    -- ── Fetch full question objects for the generated ids ─────

    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id',                   q.id,
        'name',                 q.name,
        'name_audio_prompt',    q.name_audio_prompt,
        'options',              q.options,
        'options_audio_prompt', q.options_audio_prompt,
        'hint',                 q.hint,
        'image_url',            q.image_url,
        'sort_order',           q.sort_order
        -- correct_answer intentionally excluded
      )
      ORDER BY q.sort_order, q.id
    ), '[]'::jsonb)
    INTO v_questions
    FROM edu.questions q
    WHERE q.id = ANY(v_question_ids)
      AND q.tenant_id = v_tenant_id;

    RETURN public.fn_response_success(
      p_data := jsonb_build_object(
        'session_id',         v_session_id,
        'student_id',         p_student_id,
        'grade',              v_grade,
        'status',             'IN_PROGRESS',
        'question_type_id',   p_question_type_id,
        'is_resumed',         v_is_resumed,
        'total_questions',    COALESCE(array_length(v_question_ids, 1), 0),
        'questions',          v_questions
      ),
      p_message := format(
        'Session %s %s for student %s with %s questions.',
        v_session_id,
        CASE WHEN v_is_resumed THEN 'resumed' ELSE 'started' END,
        p_student_id,
        COALESCE(array_length(v_question_ids, 1), 0)
      ),
      p_total_records := COALESCE(array_length(v_question_ids, 1), 0),
      p_page_size     := COALESCE(array_length(v_question_ids, 1), 0),
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_start_session',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$
