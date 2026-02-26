CREATE OR REPLACE FUNCTION edu.fn_complete_session(
  p_session_id    bigint  DEFAULT NULL,
  p_status        text    DEFAULT 'COMPLETED',   -- 'COMPLETED' | 'ABANDONED'
  p_data          jsonb   DEFAULT NULL,
  p_metadata      jsonb   DEFAULT NULL
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
Description   : Completes or abandons an IN_PROGRESS session.
                Recalculates attempted/correct/incorrect/skipped
                from session_responses before closing.
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_complete_session(p_session_id := 1, p_status := 'COMPLETED');
================================================
*/
DECLARE
  v_tenant_id   bigint;
  v_user_id     bigint;
  v_caller_id   bigint;
  v_attempted   integer;
  v_correct     integer;
  v_incorrect   integer;
  v_skipped     integer;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_complete_session');

    -- ── Validations ──────────────────────────────────────────

    IF p_session_id IS NULL THEN
      RAISE EXCEPTION 'session_id is required.';
    END IF;

    IF p_status NOT IN ('COMPLETED', 'ABANDONED') THEN
      RAISE EXCEPTION 'Invalid status %. Must be COMPLETED or ABANDONED.', p_status;
    END IF;

    -- Ensure session exists, belongs to tenant, and is still IN_PROGRESS
    IF NOT EXISTS (
      SELECT 1 FROM edu.sessions
      WHERE id        = p_session_id
        AND tenant_id = v_tenant_id
        AND status    = 'IN_PROGRESS'
    ) THEN
      RAISE EXCEPTION 'Session ID % not found, already closed, or access denied.', p_session_id;
    END IF;

    -- ── Recalculate stats from session_responses ──────────────
    -- attempted = answered (student_answer IS NOT NULL)
    -- skipped   = student_answer IS NULL
    -- correct / incorrect from is_correct flag

    SELECT
      COUNT(*)                                          AS attempted,
      COUNT(*) FILTER (WHERE is_correct = true)         AS correct,
      COUNT(*) FILTER (WHERE is_correct = false)        AS incorrect,
      COUNT(*) FILTER (WHERE student_answer IS NULL)    AS skipped
    INTO v_attempted, v_correct, v_incorrect, v_skipped
    FROM edu.session_responses
    WHERE session_id = p_session_id
      AND tenant_id  = v_tenant_id;

    -- ── Close the session ────────────────────────────────────

    UPDATE edu.sessions SET
      status      = p_status,
      attempted   = v_attempted,
      correct     = v_correct,
      incorrect   = v_incorrect,
      skipped     = v_skipped,
      data        = p_data,
      metadata    = p_metadata,
      updated_by  = v_user_id,
      updated_at  = now()
    WHERE id        = p_session_id
      AND tenant_id = v_tenant_id;

    RETURN public.fn_response_success(
      p_data := jsonb_build_object(
        'session_id',  p_session_id,
        'status',      p_status,
        'attempted',   v_attempted,
        'correct',     v_correct,
        'incorrect',   v_incorrect,
        'skipped',     v_skipped
      ),
      p_message       := format('Session %s marked as %s.', p_session_id, p_status),
      p_total_records := 1,
      p_page_size     := 1,
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_complete_session',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$;