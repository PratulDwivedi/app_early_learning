CREATE OR REPLACE FUNCTION edu.fn_get_students(
  p_id          bigint   DEFAULT NULL::bigint,
  p_page_index  integer  DEFAULT 1,
  p_page_size   integer  DEFAULT 20
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedia
Modified Date : 20-Feb-2026
Description   : Retrieve students (paginated).
                Admin (data->>'is_admin' = true) → all students
                Guardian                         → own students only
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_students();
SELECT edu.fn_get_students(p_page_index := 2, p_page_size := 10);
SELECT edu.fn_get_students(p_id := 42);
==================================================
*/
DECLARE
    v_tenant_id     bigint;
    v_user_id       bigint;
    v_caller_id     bigint;
    v_result        jsonb;
    v_is_admin      boolean := false;
    v_total_records int;
    v_offset        int;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_students');

        -- ── Validations ───────────────────────────────────────

        IF p_page_index < 1 THEN
            RAISE EXCEPTION 'page_index must be >= 1.';
        END IF;

        IF p_page_size < 1 OR p_page_size > 100 THEN
            RAISE EXCEPTION 'page_size must be between 1 and 100.';
        END IF;

        -- Check is_admin from profiles.data
        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;

        v_offset := (p_page_index - 1) * p_page_size;

        -- ── Total count ───────────────────────────────────────

        SELECT COUNT(*)
        INTO v_total_records
        FROM edu.students s
        INNER JOIN public.profiles p ON s.guardian_id = p.uid
        WHERE s.tenant_id = v_tenant_id
          AND s.is_active = true
          AND (p_id IS NULL OR s.id = p_id)
          AND (v_is_admin = true OR s.guardian_id = v_user_id);

        -- ── Paginated result ──────────────────────────────────

        SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT s.id, s.first_name, s.last_name, s.grade, s.dob,
                   s.guardian_id, s.teacher_id, s.school_name,
                   s.avatar_url, s.is_active, s.created_at,
                   p.full_name, p.email
            FROM edu.students s
            INNER JOIN public.profiles p ON s.guardian_id = p.uid
            WHERE s.tenant_id = v_tenant_id
              AND s.is_active = true
              AND (p_id IS NULL OR s.id = p_id)
              AND (v_is_admin = true OR s.guardian_id = v_user_id)
            ORDER BY s.first_name
            LIMIT  p_page_size
            OFFSET v_offset
        ) t;

        RETURN public.fn_response_success(
            p_data          := v_result,
            p_message       := 'Students retrieved successfully.',
            p_total_records := v_total_records,
            p_page_size     := p_page_size,
            p_page_index    := p_page_index
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_get_students',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$;