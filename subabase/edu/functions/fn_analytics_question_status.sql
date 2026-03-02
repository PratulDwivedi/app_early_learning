CREATE OR REPLACE FUNCTION edu.fn_analytics_question_status(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_question_status();
SELECT edu.fn_analytics_question_status(p_student_id := 1);
-- ── 1. Question Status (Pie) ──────────────────────────────────
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
        FROM public.fn_get_request_context('edu.fn_analytics_question_status');

        SELECT jsonb_build_array(

            jsonb_build_object('name', 'New - Never Answered', 'value', (
                SELECT COUNT(DISTINCT q.id)
                FROM edu.questions q
                INNER JOIN edu.question_types qt ON qt.id = q.question_type_id
                WHERE q.tenant_id  = v_tenant_id
                  AND q.is_active  = true
                  AND qt.is_active = true
                  AND (p_question_type_id IS NULL OR q.question_type_id = p_question_type_id)
                  AND NOT EXISTS (
                      SELECT 1 FROM edu.fn_analytics_base(p_student_id, p_question_type_id) b
                      WHERE b.question_id = q.id
                  )
            )),

            jsonb_build_object('name', 'Answered Correctly', 'value', (
                SELECT COUNT(*) FROM (
                    SELECT DISTINCT ON (student_id, question_id) is_correct
                    FROM edu.fn_analytics_base(p_student_id, p_question_type_id)
                    ORDER BY student_id, question_id, created_at DESC
                ) t WHERE is_correct = true
            )),

            jsonb_build_object('name', 'Answered Wrong', 'value', (
                SELECT COUNT(*) FROM (
                    SELECT DISTINCT ON (student_id, question_id)
                        student_id, question_id, is_correct
                    FROM edu.fn_analytics_base(p_student_id, p_question_type_id)
                    ORDER BY student_id, question_id, created_at DESC
                ) latest
                WHERE latest.is_correct = false
                  AND NOT EXISTS (
                      SELECT 1
                      FROM edu.fn_analytics_base(p_student_id, p_question_type_id) b
                      WHERE b.student_id  = latest.student_id
                        AND b.question_id = latest.question_id
                        AND b.is_correct  = true
                  )
            )),

            jsonb_build_object('name', 'Forgotten', 'value', (
                SELECT COUNT(*) FROM (
                    SELECT DISTINCT ON (student_id, question_id)
                        student_id, question_id, is_correct
                    FROM edu.fn_analytics_base(p_student_id, p_question_type_id)
                    ORDER BY student_id, question_id, created_at DESC
                ) latest
                WHERE latest.is_correct = false
                  AND EXISTS (
                      SELECT 1
                      FROM edu.fn_analytics_base(p_student_id, p_question_type_id) b
                      WHERE b.student_id  = latest.student_id
                        AND b.question_id = latest.question_id
                        AND b.is_correct  = true
                  )
            ))

        ) INTO v_result;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Question status retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_question_status',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;