CREATE OR REPLACE FUNCTION edu.fn_get_student_summary(
    p_student_id BIGINT DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
============================================================================================
Copyright     : Tech-Techi, 2026
Created By    : Pratul Dwivedi
Modified Date : 25-Feb-2026
Description   : fn_get_student_summary - Returns a summary of student question responses
                grouped into: New (Never Answered), Answered Correctly, Answered Wrong,
                and Forgotten (previously correct, later answered wrong).
Parameters    : p_student_id - Optional filter for a specific student

-- All students (no filter)
SELECT edu.fn_get_student_summary();

-- Specific student
SELECT edu.fn_get_student_summary(p_student_id := 42);

============================================================================================
*/
DECLARE
    v_result        JSONB;
    v_tenant_id     INTEGER;
    v_user_id       INTEGER;
    v_caller_id     INTEGER;

    v_new           INTEGER := 0;
    v_correct       INTEGER := 0;
    v_wrong         INTEGER := 0;
    v_forgotten     INTEGER := 0;
BEGIN
    BEGIN
        -- Get tenant/user/caller context
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM fn_get_request_context('fn_get_student_summary');

        -- -------------------------------------------------------------------------
        -- New - Never Answered
        -- Questions that exist but have never been attempted by the student
        -- -------------------------------------------------------------------------
        SELECT COUNT(DISTINCT q.id)
        INTO v_new
        FROM edu.questions q
        WHERE q.is_active = true
          AND q.tenant_id = v_tenant_id
          AND NOT EXISTS (
              SELECT 1
              FROM edu.session_responses sr
              WHERE sr.question_id = q.id
                AND (p_student_id IS NULL OR sr.student_id = p_student_id)
                AND sr.tenant_id = v_tenant_id
          );

        -- -------------------------------------------------------------------------
        -- Answered Correctly
        -- Questions where the student's LATEST response is correct
        -- -------------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_correct
        FROM (
            SELECT DISTINCT ON (sr.question_id)
                   sr.question_id,
                   sr.is_correct
            FROM edu.session_responses sr
            WHERE sr.tenant_id = v_tenant_id
              AND (p_student_id IS NULL OR sr.student_id = p_student_id)
              AND sr.is_correct IS NOT NULL
            ORDER BY sr.question_id, sr.created_at DESC
        ) latest
        WHERE latest.is_correct = true;

        -- -------------------------------------------------------------------------
        -- Answered Wrong
        -- Questions where the student's LATEST response is incorrect
        -- and they have NEVER answered it correctly before
        -- -------------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_wrong
        FROM (
            SELECT DISTINCT ON (sr.question_id)
                   sr.question_id,
                   sr.is_correct
            FROM edu.session_responses sr
            WHERE sr.tenant_id = v_tenant_id
              AND (p_student_id IS NULL OR sr.student_id = p_student_id)
              AND sr.is_correct IS NOT NULL
            ORDER BY sr.question_id, sr.created_at DESC
        ) latest
        WHERE latest.is_correct = false
          AND NOT EXISTS (
              SELECT 1
              FROM edu.session_responses sr2
              WHERE sr2.question_id  = latest.question_id
                AND sr2.is_correct   = true
                AND sr2.tenant_id    = v_tenant_id
                AND (p_student_id IS NULL OR sr2.student_id = p_student_id)
          );

        -- -------------------------------------------------------------------------
        -- Forgotten
        -- Questions where the student answered correctly at some point
        -- but the LATEST response is incorrect
        -- -------------------------------------------------------------------------
        SELECT COUNT(*)
        INTO v_forgotten
        FROM (
            SELECT DISTINCT ON (sr.question_id)
                   sr.question_id,
                   sr.is_correct
            FROM edu.session_responses sr
            WHERE sr.tenant_id = v_tenant_id
              AND (p_student_id IS NULL OR sr.student_id = p_student_id)
              AND sr.is_correct IS NOT NULL
            ORDER BY sr.question_id, sr.created_at DESC
        ) latest
        WHERE latest.is_correct = false
          AND EXISTS (
              SELECT 1
              FROM edu.session_responses sr2
              WHERE sr2.question_id  = latest.question_id
                AND sr2.is_correct   = true
                AND sr2.tenant_id    = v_tenant_id
                AND (p_student_id IS NULL OR sr2.student_id = p_student_id)
          );

        -- -------------------------------------------------------------------------
        -- Build result
        -- -------------------------------------------------------------------------
        v_result := jsonb_build_array(
            jsonb_build_object('name', 'New - Never Answered',  'value', v_new),
            jsonb_build_object('name', 'Answered Correctly',    'value', v_correct),
            jsonb_build_object('name', 'Answered Wrong',        'value', v_wrong),
            jsonb_build_object('name', 'Forgotten',             'value', v_forgotten)
        );

        RETURN fn_response_success(
            p_data          := v_result,
            p_message       := 'retrieved successfully',
            p_total_records := jsonb_array_length(v_result),
            p_page_size     := 1,
            p_page_index    := 1
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN fn_response_error(
            p_function_name := 'fn_get_student_summary',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;
