CREATE OR REPLACE FUNCTION edu.fn_get_student_sessions(
  p_student_id   bigint
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Created Date  : 01-Mar-2026
Modified Date : 01-Mar-2026
Description   : Retrieve all sessions for a given student.
                Admin    → any student's sessions
                Guardian → own students' sessions only

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_student_sessions(p_student_id := 1);
==================================================
*/
DECLARE
    v_tenant_id  bigint;
    v_user_id    bigint;
    v_caller_id  bigint;
    v_result     jsonb;
    v_is_admin   boolean := false;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_student_sessions');

        -- ── Check Admin ───────────────────────────────────────

        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;

        -- ── Result ────────────────────────────────────────────

        SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT
                ss.id,
                ss.student_id,
                ss.total_questions,
                ss.attempted,
                ss.correct,
                ss.incorrect,
                ss.skipped,
                ss.status,
                ss.data,
                ss.created_at,
                ss.updated_at
            FROM edu.sessions ss
            INNER JOIN edu.students s ON ss.student_id = s.id
            WHERE s.tenant_id  = v_tenant_id
              AND s.is_active  = true
              AND ss.student_id = p_student_id
              AND (v_is_admin = true OR s.guardian_id = v_user_id)
            ORDER BY ss.id DESC
        ) t;

        RETURN public.fn_response_success(
            p_data    := v_result,
            p_message := 'Student sessions retrieved successfully.'
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_get_student_sessions',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;