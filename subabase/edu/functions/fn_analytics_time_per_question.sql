CREATE OR REPLACE FUNCTION edu.fn_analytics_time_per_question(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_time_per_question();
SELECT edu.fn_analytics_time_per_question(p_student_id := 1);
-- ── 4. Avg Time per Question (Horizontal Bar) ─────────────────
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
        FROM public.fn_get_request_context('edu.fn_analytics_time_per_question');

        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'question',       question_name,
                'question_type',  question_type_name,
                'avg_time_sec',   ROUND(avg_time::numeric, 2),
                'total_attempts', total_attempts
            ) ORDER BY avg_time DESC
        ), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT
                question_name,
                question_type_name,
                AVG(time_taken_sec) AS avg_time,
                COUNT(*)            AS total_attempts
            FROM edu.fn_analytics_base(v_tenant_id, p_student_id, p_question_type_id)
            GROUP BY question_name, question_type_name
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Time per question retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_time_per_question',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;