CREATE OR REPLACE FUNCTION edu.fn_analytics_raw_data(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_analytics_raw_data();
SELECT edu.fn_analytics_raw_data(p_student_id := 1);
-- ── 9. Raw Data Export (Table/Download) ───────────────────────
*/
DECLARE
    v_tenant_id  bigint;
    v_user_id    bigint;
    v_caller_id  bigint;
    v_result     jsonb;
    v_total      int;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_analytics_raw_data');

        SELECT
            COALESCE(jsonb_agg(
                jsonb_build_object(
                    'session_id',      session_id,
                    'student_id',      student_id,
                    'grade',           grade,
                    'session_status',  session_status,
                    'total_questions', total_questions,
                    'attempted',       attempted,
                    'correct',         correct,
                    'skipped',         skipped,
                    'question_type',   question_type_name,
                    'question_id',     question_id,
                    'question',        question_name,
                    'is_correct',      is_correct,
                    'time_taken_sec',  time_taken_sec,
                    'attempt_count',   attempt_count
                ) ORDER BY session_id, question_id
            ), '[]'::jsonb),
            COUNT(*)::int
        INTO v_result, v_total
        FROM edu.fn_analytics_base(v_tenant_id, p_student_id, p_question_type_id);

        RETURN public.fn_response_success(
            p_data          := v_result,
            p_message       := 'Raw analytics data retrieved successfully.',
            p_total_records := v_total,
            p_page_size     := v_total,
            p_page_index    := 1
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_analytics_raw_data',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;