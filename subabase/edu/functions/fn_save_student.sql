CREATE OR REPLACE FUNCTION edu.fn_save_student(p_id bigint DEFAULT NULL::bigint, p_first_name text DEFAULT NULL::text, p_last_name text DEFAULT NULL::text, p_grade smallint DEFAULT NULL::smallint, p_dob date DEFAULT NULL::date, p_avatar_url text DEFAULT NULL::text, p_data jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
============================================================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Modified Date : 20-Feb-2026
Description   : Insert or update a student record.
============================================================================================
*/
DECLARE
    v_id        bigint;
    v_tenant_id bigint;
    v_user_id   bigint;
    v_caller_id bigint;
    v_result    jsonb;
BEGIN
    BEGIN
        SELECT tenant_id, user_id, caller_id
        INTO v_tenant_id, v_user_id, v_caller_id
        FROM fn_get_request_context('edu.fn_save_student');

        IF p_id IS NULL OR p_id = 0 THEN
            PERFORM pg_advisory_xact_lock(1111111101);
            SELECT COALESCE(MAX(id), 0) + 1 INTO v_id FROM edu.students;

            INSERT INTO edu.students (
                id, first_name, last_name, grade, dob,
                guardian_id, avatar_url, data,
                tenant_id, is_active, created_by, created_at
            ) VALUES (
                v_id, p_first_name, p_last_name, p_grade, p_dob,
                v_user_id, p_avatar_url, p_data,
                v_tenant_id, TRUE, v_user_id, now()
            );
        ELSE
            UPDATE edu.students SET
                first_name  = p_first_name,
                last_name   = p_last_name,
                grade       = p_grade,
                dob         = p_dob,
                avatar_url  = p_avatar_url,
                data = p_data,
                updated_by  = v_user_id,
                updated_at  = now()
            WHERE id = p_id AND tenant_id = v_tenant_id
            RETURNING id INTO v_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Student ID % not found or access denied.', p_id;
            END IF;
        END IF;

        SELECT to_jsonb(s) INTO v_result FROM edu.students s WHERE s.id = v_id;

        RETURN fn_response_success(
            p_data          := v_result,
            p_message       := format('Student ID %s saved successfully.', v_id),
            p_total_records := 1, p_page_size := 1, p_page_index := 1
        );

    EXCEPTION WHEN OTHERS THEN
        RETURN fn_response_error(
            p_function_name := 'edu.fn_save_student',
            p_message       := SQLERRM,
            p_data          := '{}'::jsonb,
            p_tenant_id     := v_tenant_id,
            p_user_id       := v_user_id
        );
    END;
END;
$function$
