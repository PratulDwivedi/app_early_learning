CREATE OR REPLACE FUNCTION edu.fn_analytics_session_summary(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_session_summary();
SELECT edu.fn_analytics_session_summary(p_student_id := 1);
-- ── 3. Per Session Summary (Stacked Bar) ──────────────────────
*/
DECLARE
    v_tenant_id  bigint;
    v_user_id    bigint;
    v_caller_id  bigint;
    v_result     jsonb;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_analytics_session_summary');

        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'session_id',      session_id,
                'status',          session_status,
                'total_questions', total_questions,
                'attempted',       attempted,
                'correct',         correct,
                'skipped',         skipped,
                'wrong',           attempted - correct
            ) ORDER BY session_id
        ), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT DISTINCT
                session_id, session_status,
                total_questions, attempted, correct, skipped
            FROM edu.fn_analytics_base(v_tenant_id, p_student_id, p_question_type_id)
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Session summary retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_session_summary',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;