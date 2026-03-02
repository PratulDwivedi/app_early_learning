CREATE OR REPLACE FUNCTION edu.fn_analytics_attempt_distribution(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_attempt_distribution();
SELECT edu.fn_analytics_attempt_distribution(p_student_id := 1);
-- ── 5. Attempt Distribution (Pie) ─────────────────────────────
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
        FROM public.fn_get_request_context('edu.fn_analytics_attempt_distribution');

        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'attempts_needed', attempt_bucket,
                'question_count',  question_count
            ) ORDER BY attempt_bucket
        ), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT
                attempt_bucket,
                COUNT(*) AS question_count
            FROM (
                SELECT
                    CASE
                        WHEN attempt_count = 1 THEN '1 Attempt'
                        WHEN attempt_count = 2 THEN '2 Attempts'
                        ELSE '3+ Attempts'
                    END AS attempt_bucket
                FROM edu.fn_analytics_base(v_tenant_id, p_student_id, p_question_type_id)
            ) buckets
            GROUP BY attempt_bucket
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Attempt distribution retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_attempt_distribution',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;