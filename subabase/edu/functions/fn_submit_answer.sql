CREATE OR REPLACE FUNCTION edu.fn_submit_answer(
  p_session_id      bigint  DEFAULT NULL,
  p_question_id     bigint  DEFAULT NULL,
  p_student_answer  text    DEFAULT NULL,   -- NULL = skipped
  p_time_taken_sec  integer DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    :
Created Date  :
Description   : Records student answer for a question in a session.
                - Validates session is IN_PROGRESS
                - Validates question belongs to session question set
                - Auto-grades against correct_answer
                - Upserts session_responses (handles re-attempts)
                - Records student_id directly on session_responses
                - Refreshes session counters
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_submit_answer(
  p_session_id     := 1,
  p_question_id    := 5,
  p_student_answer := 'Apple',
  p_time_taken_sec := 8
);
================================================
*/
DECLARE
  v_tenant_id       bigint;
  v_user_id         bigint;
  v_caller_id       bigint;
  v_correct_answer  text;
  v_is_correct      boolean;
  v_response_id     bigint;
  v_attempt_count   smallint;
  v_question_order  smallint;
  v_session_data    jsonb;
  v_student_id      bigint;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_submit_answer');

    -- ── Validations ──────────────────────────────────────────

    IF p_session_id IS NULL THEN
      RAISE EXCEPTION 'session_id is required.';
    END IF;

    IF p_question_id IS NULL THEN
      RAISE EXCEPTION 'question_id is required.';
    END IF;

    -- Session must exist, belong to tenant and be IN_PROGRESS
    -- Also fetch student_id and session data in one shot
    SELECT student_id, data
    INTO v_student_id, v_session_data
    FROM edu.sessions
    WHERE id        = p_session_id
      AND tenant_id = v_tenant_id
      AND status    = 'IN_PROGRESS';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Session ID % is not active or access denied.', p_session_id;
    END IF;

    -- Question must be part of this session's generated question_ids
    -- stored in sessions.data->'question_ids' by fn_start_session
    IF NOT (v_session_data->'question_ids' @> to_jsonb(p_question_id)) THEN
      RAISE EXCEPTION 'Question ID % does not belong to session %.', p_question_id, p_session_id;
    END IF;

    -- Fetch correct answer for auto-grading
    SELECT correct_answer
    INTO v_correct_answer
    FROM edu.questions
    WHERE id        = p_question_id
      AND tenant_id = v_tenant_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Question ID % not found or inactive.', p_question_id;
    END IF;

    -- ── Auto-grade ────────────────────────────────────────────
    -- NULL answer = skipped, is_correct stays NULL

    IF p_student_answer IS NOT NULL THEN
      v_is_correct := (trim(lower(p_student_answer)) = trim(lower(v_correct_answer)));
    ELSE
      v_is_correct := NULL;
    END IF;

    -- ── Derive question_order from session question_ids array ──

    SELECT (pos - 1)::smallint
    INTO v_question_order
    FROM jsonb_array_elements(v_session_data->'question_ids')
      WITH ORDINALITY AS t(val, pos)
    WHERE val::bigint = p_question_id;

    -- ── Upsert session_responses ──────────────────────────────

    SELECT id, attempt_count
    INTO v_response_id, v_attempt_count
    FROM edu.session_responses
    WHERE session_id  = p_session_id
      AND question_id = p_question_id
      AND tenant_id   = v_tenant_id;

    IF FOUND THEN
      -- Re-attempt: overwrite answer, bump attempt_count
      UPDATE edu.session_responses SET
        student_answer  = p_student_answer,
        is_correct      = v_is_correct,
        time_taken_sec  = p_time_taken_sec,
        attempt_count   = v_attempt_count + 1,
        updated_at      = now()
      WHERE id = v_response_id;

    ELSE
      -- First attempt: insert new record
      INSERT INTO edu.session_responses (
        session_id,
        student_id,
        question_id,
        question_order,
        student_answer,
        is_correct,
        time_taken_sec,
        attempt_count,
        tenant_id,
        created_at
      ) VALUES (
        p_session_id,
        v_student_id,
        p_question_id,
        v_question_order,
        p_student_answer,
        v_is_correct,
        p_time_taken_sec,
        1,
        v_tenant_id,
        now()
      )
      RETURNING id INTO v_response_id;

    END IF;

    -- ── Refresh session counters ──────────────────────────────

    UPDATE edu.sessions SET
      attempted  = (
        SELECT COUNT(*)
        FROM edu.session_responses
        WHERE session_id = p_session_id
          AND student_answer IS NOT NULL
      ),
      correct    = (
        SELECT COUNT(*)
        FROM edu.session_responses
        WHERE session_id = p_session_id
          AND is_correct = true
      ),
      incorrect  = (
        SELECT COUNT(*)
        FROM edu.session_responses
        WHERE session_id = p_session_id
          AND is_correct = false
      ),
      skipped    = (
        SELECT COUNT(*)
        FROM edu.session_responses
        WHERE session_id = p_session_id
          AND student_answer IS NULL
      ),
      updated_by = v_user_id,
      updated_at = now()
    WHERE id = p_session_id;

    -- ── Return response ───────────────────────────────────────

    RETURN public.fn_response_success(
      p_data := jsonb_build_object(
        'response_id',    v_response_id,
        'session_id',     p_session_id,
        'student_id',     v_student_id,
        'question_id',    p_question_id,
        'question_order', v_question_order,
        'student_answer', p_student_answer,
        'is_correct',     v_is_correct,
        'attempt_count',  COALESCE(v_attempt_count + 1, 1),
        'time_taken_sec', p_time_taken_sec,
        -- only reveal correct answer when student got it wrong
        'correct_answer', CASE
                            WHEN v_is_correct = false THEN v_correct_answer
                            ELSE NULL
                          END
      ),
      p_message := CASE
        WHEN p_student_answer IS NULL THEN 'Question skipped.'
        WHEN v_is_correct             THEN 'Great job! That is correct!'
        ELSE                               'Good try! Keep going!'
      END,
      p_total_records := 1,
      p_page_size     := 1,
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_submit_answer',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$;