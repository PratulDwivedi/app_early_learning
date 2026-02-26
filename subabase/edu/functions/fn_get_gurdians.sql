CREATE OR REPLACE FUNCTION edu.fn_get_gurdians() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Modified Date : 20-Feb-2026
Description   : 
SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_get_gurdians()
==================================================
*/
DECLARE
    v_tenant_id bigint;
    v_user_id   bigint;
    v_caller_id bigint;
    v_result    jsonb;
    v_is_admin  boolean := false;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM public.fn_get_request_context('edu.fn_get_gurdians');

        -- Check is_admin from profiles.data
        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;

        -- ✅ Admin guard — raise immediately, caught by EXCEPTION block below
        IF NOT v_is_admin THEN
            RAISE EXCEPTION 'ACCESS_DENIED';
        END IF;

        SELECT jsonb_agg(to_jsonb(t))
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
            FROM profiles p
            WHERE p.tenant_id = v_tenant_id
              AND p.is_active = true
            ORDER BY p.full_name
        ) t;

        RETURN public.fn_response_success(
            p_data          := COALESCE(v_result, '[]'::jsonb),
            p_message       := 'Guardians retrieved successfully.',
            p_total_records := COALESCE(jsonb_array_length(v_result), 0),
            p_page_size     := 1,
            p_page_index    := 1
        );

    EXCEPTION WHEN OTHERS THEN
        -- ✅ Return clean access denied message instead of raw SQL error
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
$function$;