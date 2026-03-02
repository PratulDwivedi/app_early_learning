CREATE OR REPLACE FUNCTION edu.fn_get_student_analytics(
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Created Date  : 01-Mar-2026
Modified Date : 01-Mar-2026
Description   : Master analytics function — calls all stat functions
                and returns everything in one response.

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_student_analytics();
SELECT edu.fn_get_student_analytics(p_student_id := 1);
SELECT edu.fn_get_student_analytics(p_student_id := 1, p_question_type_id := 2);
================================================
*/
DECLARE
    v_tenant_id             bigint;
    v_user_id               bigint;
    v_caller_id             bigint;

    v_question_status       jsonb;
    v_by_question_type      jsonb;
    v_session_summary       jsonb;
    v_time_per_question     jsonb;
    v_attempt_distribution  jsonb;
    v_session_trend         jsonb;
    v_hardest_questions     jsonb;
    v_grade_breakdown       jsonb;
    v_raw_data              jsonb;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_student_analytics');

        -- ── 1. Question Status (Pie) ──────────────────────────

        SELECT (data->>'data')::jsonb
        INTO v_question_status
        FROM (
            SELECT edu.fn_analytics_question_status(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 2. By Question Type (Grouped Bar) ─────────────────

        SELECT (data->>'data')::jsonb
        INTO v_by_question_type
        FROM (
            SELECT edu.fn_analytics_by_question_type(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 3. Session Summary (Stacked Bar) ──────────────────

        SELECT (data->>'data')::jsonb
        INTO v_session_summary
        FROM (
            SELECT edu.fn_analytics_session_summary(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 4. Time per Question (Horizontal Bar) ─────────────

        SELECT (data->>'data')::jsonb
        INTO v_time_per_question
        FROM (
            SELECT edu.fn_analytics_time_per_question(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 5. Attempt Distribution (Pie) ─────────────────────

        SELECT (data->>'data')::jsonb
        INTO v_attempt_distribution
        FROM (
            SELECT edu.fn_analytics_attempt_distribution(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 6. Session Trend (Line/Column) ────────────────────

        SELECT (data->>'data')::jsonb
        INTO v_session_trend
        FROM (
            SELECT edu.fn_analytics_session_trend(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 7. Hardest Questions (Bar/Table) ──────────────────

        SELECT (data->>'data')::jsonb
        INTO v_hardest_questions
        FROM (
            SELECT edu.fn_analytics_hardest_questions(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 8. Grade Breakdown (Grouped Bar) ──────────────────

        SELECT (data->>'data')::jsonb
        INTO v_grade_breakdown
        FROM (
            SELECT edu.fn_analytics_grade_breakdown(p_student_id, p_question_type_id) AS data
        ) t;

        -- ── 9. Raw Data Export, for future use ────────────────────────────────
        /*
        SELECT (data->>'data')::jsonb
        INTO v_raw_data
        FROM (
            SELECT edu.fn_analytics_raw_data(p_student_id, p_question_type_id) AS data
        ) t;
        */
        -- ── Return all in one response ────────────────────────

        RETURN public.fn_response_success(
            p_data := jsonb_build_object(
                'question_status',      v_question_status,
                'by_question_type',     v_by_question_type,
                'session_summary',      v_session_summary,
                'time_per_question',    v_time_per_question,
                'attempt_distribution', v_attempt_distribution,
                'session_trend',        v_session_trend,
                'hardest_questions',    v_hardest_questions,
                'grade_breakdown',      v_grade_breakdown,
                'raw_data',             v_raw_data
            ),
            p_message := 'Analytics retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_get_student_analytics',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;