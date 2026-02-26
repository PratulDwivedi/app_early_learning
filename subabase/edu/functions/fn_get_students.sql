CREATE OR REPLACE FUNCTION edu.fn_get_students(
    p_id bigint default null::bigint
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedia
Modified Date : 20-Feb-2026
Description   : Retrieve students.
                Admin (data->>'is_admin' = true) → all students
                Guardian                         → own students only

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
select edu.fn_get_students()
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
        FROM public.fn_get_request_context('edu.fn_get_students');

        -- ✅ Check is_admin from profiles.data using profiles.id (bigint)
        SELECT COALESCE((data->>'is_admin')::boolean, false)
        INTO v_is_admin
        FROM public.profiles
        WHERE uid = v_user_id;   -- id is bigint, same as v_user_id

        SELECT jsonb_agg(to_jsonb(t))
        INTO v_result
        FROM (
            SELECT s.id, s.first_name, s.last_name, s.grade, s.dob,
                   s.guardian_id, s.teacher_id, s.school_name,
                   s.avatar_url, s.is_active, s.created_at ,
                   p.full_name, p.email
            FROM edu.students s inner join profiles p
            on s.guardian_id = p.uid
            WHERE  (p_id IS NULL OR s.id = p_id)
              AND s.tenant_id = v_tenant_id
              AND s.is_active = true
              AND (v_is_admin = true OR s.guardian_id = v_user_id)
            ORDER BY s.first_name
        ) t;

        RETURN public.fn_response_success(
            p_data          := COALESCE(v_result, '[]'::jsonb),
            p_message       := 'Students retrieved successfully.',
            p_total_records := COALESCE(jsonb_array_length(v_result), 0),
            p_page_size     := 1,
            p_page_index    := 1
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
$function$
