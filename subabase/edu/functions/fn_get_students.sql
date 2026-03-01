CREATE OR REPLACE FUNCTION edu.fn_get_students(
  p_id           bigint   DEFAULT NULL::bigint,
  p_page_index   integer  DEFAULT 1,
  p_page_size    integer  DEFAULT 10,
  p_search_text  text     DEFAULT NULL::text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedia
Modified Date : 01-Mar-2026
Description   : Retrieve students (paginated).
                Admin (data->>'is_admin' = true) → all students
                Guardian                         → own students only
                p_search_text                    → filters by student
                                                   first/last name,
                                                   school, or guardian
                                                   email/full name
                p_page_index = 0                 → return all records
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_students();
SELECT edu.fn_get_students(p_page_index := 0);
SELECT edu.fn_get_students(p_page_index := 2, p_page_size := 10);
SELECT edu.fn_get_students(p_id := 42);
SELECT edu.fn_get_students(p_search_text := 'john');
SELECT edu.fn_get_students(p_search_text := 'john', p_page_index := 1, p_page_size := 5);
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
    v_page_size     int     := 10;
    v_search_text   text;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_students');

        -- ── Validations ───────────────────────────────────────

        IF p_page_index < 0 THEN
            RAISE EXCEPTION 'page_index must be >= 0 (use 0 to load all records).';
        END IF;

        IF v_page_size < 1 OR v_page_size > 100 THEN
            RAISE EXCEPTION 'page_size must be between 1 and 100.';
        END IF;

        -- Normalize search text: trim and lowercase for case-insensitive matching
        v_search_text := NULLIF(TRIM(LOWER(p_search_text)), '');

        -- Check is_admin from profiles.data
        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;

        v_offset := CASE WHEN p_page_index = 0 THEN 0 ELSE (p_page_index - 1) * v_page_size END;

        -- ── Total count ───────────────────────────────────────

        SELECT COUNT(*)
        INTO v_total_records
        FROM edu.students s
        INNER JOIN public.profiles p ON s.guardian_id = p.uid
        WHERE s.tenant_id = v_tenant_id
          AND s.is_active = true
          AND (p_id IS NULL OR s.id = p_id)
          AND (v_is_admin = true OR s.guardian_id = v_user_id)
          AND (
              v_search_text IS NULL
              OR LOWER(s.first_name)   LIKE '%' || v_search_text || '%'
              OR LOWER(s.last_name)    LIKE '%' || v_search_text || '%'
              OR LOWER(s.school_name)  LIKE '%' || v_search_text || '%'
              OR LOWER(p.full_name)    LIKE '%' || v_search_text || '%'
              OR LOWER(p.email)        LIKE '%' || v_search_text || '%'
          );

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
              AND (
                  v_search_text IS NULL
                  OR LOWER(s.first_name)   LIKE '%' || v_search_text || '%'
                  OR LOWER(s.last_name)    LIKE '%' || v_search_text || '%'
                  OR LOWER(s.school_name)  LIKE '%' || v_search_text || '%'
                  OR LOWER(p.full_name)    LIKE '%' || v_search_text || '%'
                  OR LOWER(p.email)        LIKE '%' || v_search_text || '%'
              )
            ORDER BY s.first_name
            LIMIT  CASE WHEN p_page_index = 0 THEN NULL ELSE v_page_size END
            OFFSET v_offset
        ) t;

        RETURN public.fn_response_success(
            p_data          := v_result,
            p_message       := 'Students retrieved successfully.',
            p_total_records := v_total_records,
            p_page_size     := v_page_size,
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