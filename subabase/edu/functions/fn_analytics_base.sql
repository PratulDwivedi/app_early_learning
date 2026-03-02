CREATE OR REPLACE FUNCTION edu.fn_analytics_base(
    p_tenant_id         bigint,
    p_student_id        bigint  DEFAULT NULL,
    p_question_type_id  bigint  DEFAULT NULL
)
RETURNS TABLE(
    question_id         bigint,
    is_correct          boolean,
    time_taken_sec      int,
    attempt_count       int,
    created_at          timestamptz,
    student_id          bigint,
    grade               smallint,
    session_id          bigint,
    session_status      text,
    total_questions     int,
    attempted           int,
    correct             int,
    skipped             int,
    question_name       text,
    question_type_id    bigint,
    question_type_name  text
)
LANGUAGE plpgsql SECURITY DEFINER AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : Pratul Dwivedi
Created Date  : 01-Mar-2026
Modified Date : 01-Mar-2026
Description   : Base analytics data — raw flat rows.
                Context-free: caller must pass p_tenant_id explicitly.
                Uses RETURNS TABLE to avoid external type dependency.

SELECT * FROM edu.fn_analytics_base(p_tenant_id := 5);
SELECT * FROM edu.fn_analytics_base(p_tenant_id := 5, p_student_id := 10);
SELECT * FROM edu.fn_analytics_base(p_tenant_id := 5, p_student_id := 10, p_question_type_id := 1);
================================================
*/
BEGIN
    RETURN QUERY
    SELECT
        sr.question_id::bigint,
        sr.is_correct::boolean,
        sr.time_taken_sec::int,
        sr.attempt_count::int,
        sr.created_at::timestamptz,
        s.student_id::bigint,
        s.grade::smallint,
        s.id::bigint,
        s.status::text,
        s.total_questions::int,
        s.attempted::int,
        s.correct::int,
        s.skipped::int,
        q.name::text,
        q.question_type_id::bigint,
        qt.name::text
    FROM edu.sessions s
    INNER JOIN edu.students         kid ON kid.id           = s.student_id
                                       AND kid.tenant_id    = p_tenant_id
                                       AND kid.is_active    = true
    INNER JOIN edu.session_responses sr  ON sr.session_id   = s.id
                                       AND sr.tenant_id     = p_tenant_id
    INNER JOIN edu.questions         q   ON q.id            = sr.question_id
                                       AND q.tenant_id      = p_tenant_id
                                       AND q.is_active      = true
    INNER JOIN edu.question_types    qt  ON qt.id           = q.question_type_id
                                       AND qt.tenant_id     = p_tenant_id
                                       AND qt.is_active     = true
    WHERE s.tenant_id = p_tenant_id
      AND (p_student_id       IS NULL OR s.student_id       = p_student_id)
      AND (p_question_type_id IS NULL OR q.question_type_id = p_question_type_id);

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'edu.fn_analytics_base: %', SQLERRM;
END;
$function$;