CREATE OR REPLACE FUNCTION edu.fn_analytics_grade_breakdown(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_grade_breakdown();
SELECT edu.fn_analytics_grade_breakdown(p_student_id := 1);
-- ── 8. Grade Breakdown (Grouped Bar) ─────────────────────────
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
        FROM public.fn_get_request_context('edu.fn_analytics_grade_breakdown');

        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'grade',   grade,
                'correct', correct,
                'wrong',   wrong,
                'total',   total
            ) ORDER BY grade
        ), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT
                grade,
                SUM(CASE WHEN is_correct = true  THEN 1 ELSE 0 END) AS correct,
                SUM(CASE WHEN is_correct = false THEN 1 ELSE 0 END) AS wrong,
                COUNT(*)                                             AS total
            FROM edu.fn_analytics_base(v_tenant_id, p_student_id, p_question_type_id)
            GROUP BY grade
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Grade breakdown retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_grade_breakdown',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;