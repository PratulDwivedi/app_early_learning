CREATE OR REPLACE FUNCTION edu.fn_get_gurdians(
    p_page_index integer DEFAULT 1, 
    p_page_size integer DEFAULT 10, 
    p_search_text text DEFAULT NULL::text
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Modified Date : 01-Mar-2026
Description   : Fetch paginated list of guardians with their students.
                Pass p_page_index = 0 to retrieve all records without pagination.
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_gurdians();
SELECT edu.fn_get_gurdians(p_page_index := 0);
SELECT edu.fn_get_gurdians(p_page_index := 2, p_page_size := 10);
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
        -- ── Get Request Context ───────────────────────────────
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_gurdians');

        -- ── Validations ───────────────────────────────────────

        IF p_page_index < 0 THEN
            RAISE EXCEPTION 'page_index must be >= 0 (use 0 to load all records).';
        END IF;

        IF p_page_size < 1 THEN
            RAISE EXCEPTION 'page_size must be >= 1.';
        END IF;

        -- ── Check Admin ───────────────────────────────────────
        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;

        IF NOT v_is_admin THEN
            RAISE EXCEPTION 'ACCESS_DENIED';
        END IF;

        v_offset := CASE WHEN p_page_index = 0 THEN 0 ELSE (p_page_index - 1) * p_page_size END;

        -- ── Total Count (With Search Filter) ──────────────────

        SELECT COUNT(*)
        INTO v_total_records
        FROM public.profiles p
        WHERE p.tenant_id = v_tenant_id
          AND p.is_active = true
          AND (
                p_search_text IS NULL
                OR p.full_name ILIKE '%' || p_search_text || '%'
                OR p.email     ILIKE '%' || p_search_text || '%'
              );

        -- ── Paginated Result ───────────────────────────────────

        SELECT COALESCE(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
        INTO v_result
        FROM (
            SELECT
                p.full_name,
                p.email,
                p.data,
                COALESCE(
                    (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'id',           s.id,
                                'first_name',   s.first_name,
                                'last_name',    s.last_name,
                                'grade',        s.grade,
                                'dob',          s.dob,
                                'school_name',  s.school_name,
                                'avatar_url',   s.avatar_url,
                                'data',         s.data
                            )
                            ORDER BY s.first_name
                        )
                        FROM edu.students s
                        WHERE s.guardian_id = p.uid
                          AND s.tenant_id   = v_tenant_id
                          AND s.is_active   = true
                    ),
                    '[]'::jsonb
                ) AS students
            FROM public.profiles p
            WHERE p.tenant_id = v_tenant_id
              AND p.is_active = true
              AND (
                    p_search_text IS NULL
                    OR p.full_name ILIKE '%' || p_search_text || '%'
                    OR p.email     ILIKE '%' || p_search_text || '%'
                  )
            ORDER BY p.full_name
            LIMIT  CASE WHEN p_page_index = 0 THEN NULL ELSE p_page_size END
            OFFSET v_offset
        ) t;

        -- ── Return Success ─────────────────────────────────────

        RETURN public.fn_response_success(
            p_data          := v_result,
            p_message       := 'Guardians retrieved successfully.',
            p_total_records := v_total_records,
            p_page_size     := p_page_size,
            p_page_index    := p_page_index
        );

    EXCEPTION WHEN OTHERS THEN

        IF SQLERRM = 'ACCESS_DENIED' THEN
            RETURN public.fn_response_error(
                p_function_name := 'edu.fn_get_gurdians',
                p_message       := 'Access denied. Admin privileges required.',
                p_data          := '{}'::jsonb,
                p_tenant_id     := v_tenant_id,
                p_user_id       := v_user_id
            );
        END IF;

        RETURN public.fn_response_error(
            p_function_name := 'edu.fn_get_gurdians',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$
