CREATE OR REPLACE FUNCTION edu.fn_start_session(p_student_id bigint DEFAULT NULL::bigint, p_session_id bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
/*
================================================
Copyright     : Early Learning App, 2026
Created By    : 
Created Date  : 
Modified Date : 01-Mar-2026
Description   : Starts or resumes a session for a student.
                Questions loaded across ALL question types.
                total_questions and total_duration_minutes read
                from edu.configs.data.

                Modes:
                  p_session_id = NULL  → Start fresh session (or resume ABANDONED)
                  p_session_id = given → Resume specific session by ID,
                                         only if status is IN_PROGRESS or ABANDONED

SET LOCAL request.jwt.claim.sub = 'c8ae012c-e272-4651-8162-72ca91a85000';
SELECT edu.fn_start_session(p_student_id := 1);
SELECT edu.fn_start_session(p_student_id := 1, p_session_id := 5);
================================================
*/
DECLARE
  v_tenant_id             bigint;
  v_user_id               bigint;
  v_caller_id             bigint;
  v_grade                 smallint;
  v_session_id            bigint;
  v_session_status        text;
  v_questions             jsonb;
  v_question_ids          bigint[];
  v_no_of_questions       int;
  v_duration_minutes      int;
  v_abandoned_session     record;
  v_existing_session      record;
  v_is_resumed            boolean := false;
BEGIN
  BEGIN
    SELECT tenant_id, user_id, caller_id
    INTO v_tenant_id, v_user_id, v_caller_id
    FROM public.fn_get_request_context('edu.fn_start_session');

    -- ── Validations ──────────────────────────────────────────

    IF p_student_id IS NULL THEN
      RAISE EXCEPTION 'student_id is required.';
    END IF;

    -- ── Read config ──────────────────────────────────────────

    SELECT
      COALESCE((data->>'total_questions')::int,        10),
      COALESCE((data->>'total_duration_minutes')::int, 30)
    INTO v_no_of_questions, v_duration_minutes
    FROM edu.configs
    WHERE tenant_id = v_tenant_id
    LIMIT 1;

    IF NOT FOUND THEN
      v_no_of_questions  := 10;
      v_duration_minutes := 30;
    END IF;

    -- ── Validate student ─────────────────────────────────────

    SELECT grade
    INTO v_grade
    FROM edu.students
    WHERE id        = p_student_id
      AND tenant_id = v_tenant_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Student ID % not found or inactive for this tenant.', p_student_id;
    END IF;

    -- ── Resume specific session by p_session_id ──────────────

    IF p_session_id IS NOT NULL THEN

      SELECT id, status, data
      INTO v_existing_session
      FROM edu.sessions
      WHERE id         = p_session_id
        AND student_id = p_student_id
        AND tenant_id  = v_tenant_id;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Session ID % not found for student % in this tenant.', p_session_id, p_student_id;
      END IF;

      IF v_existing_session.status = 'COMPLETED' THEN
        RAISE EXCEPTION 'Session ID % is already COMPLETED and cannot be resumed.', p_session_id;
      END IF;

      IF NOT (v_existing_session.status IN ('IN_PROGRESS', 'ABANDONED')) THEN
        RAISE EXCEPTION 'Session ID % has status % and cannot be resumed.', p_session_id, v_existing_session.status;
      END IF;

      -- Pull question_ids stored in session.data
      SELECT ARRAY(
        SELECT jsonb_array_elements_text(v_existing_session.data->'question_ids')::bigint
      ) INTO v_question_ids;

      -- Mark session as IN_PROGRESS if it was ABANDONED
      IF v_existing_session.status = 'ABANDONED' THEN
        UPDATE edu.sessions
        SET status     = 'IN_PROGRESS',
            updated_at = now()
        WHERE id = p_session_id;
      END IF;

      v_session_id   := p_session_id;
      v_is_resumed   := true;
      v_session_status := 'IN_PROGRESS';

    ELSE

      -- ── Check for ABANDONED session (auto-resume path) ──────

      SELECT id, data
      INTO v_abandoned_session
      FROM edu.sessions
      WHERE student_id = p_student_id
        AND tenant_id  = v_tenant_id
        AND status     = 'ABANDONED'
      ORDER BY created_at DESC
      LIMIT 1;

      IF FOUND AND v_abandoned_session.data ? 'question_ids' THEN
        -- Resume last abandoned session
        SELECT ARRAY(
          SELECT jsonb_array_elements_text(v_abandoned_session.data->'question_ids')::bigint
        ) INTO v_question_ids;

        v_session_id   := v_abandoned_session.id;
        v_is_resumed   := true;
        v_session_status := 'IN_PROGRESS';

        UPDATE edu.sessions
        SET status     = 'IN_PROGRESS',
            updated_at = now()
        WHERE id = v_session_id;

      ELSE

-- ── Fresh session: proportional questions per type ────

        -- Step 1: Count available questions per type (excluding already correct)
        -- Step 2: Calculate each type's proportion of total available
        -- Step 3: Allocate v_no_of_questions proportionally, pick random per type

        SELECT ARRAY(
          WITH

          -- Questions already answered correctly by this student
          correct_qids AS (
            SELECT sr.question_id
            FROM edu.session_responses sr
            INNER JOIN edu.sessions ses
              ON  ses.id        = sr.session_id
              AND ses.tenant_id = v_tenant_id
            WHERE ses.student_id = p_student_id
              AND sr.is_correct  = true
              AND sr.tenant_id   = v_tenant_id
          ),

          -- Available questions per type (excluding correct ones)
          type_counts AS (
            SELECT
              q.question_type_id,
              COUNT(q.id)::numeric AS type_total
            FROM edu.questions q
            WHERE q.tenant_id = v_tenant_id
              AND q.is_active  = true
              AND q.id NOT IN (SELECT question_id FROM correct_qids)
            GROUP BY q.question_type_id
          ),

          -- Grand total across all types
          grand_total AS (
            SELECT SUM(type_total) AS total FROM type_counts
          ),

          -- Proportional allocation per type
          -- Use ROUND to get nearest int, floor minimum 1 if type has any questions
          type_allocation AS (
            SELECT
              tc.question_type_id,
              tc.type_total,
              GREATEST(1, ROUND((tc.type_total / gt.total) * v_no_of_questions)) AS allocated
            FROM type_counts tc
            CROSS JOIN grand_total gt
          ),

          -- Pick random questions per type up to allocated count
          picked AS (
            SELECT
              q.id,
              ROW_NUMBER() OVER (
                PARTITION BY q.question_type_id
                ORDER BY random()
              ) AS rn,
              ta.allocated
            FROM edu.questions q
            INNER JOIN type_allocation ta ON ta.question_type_id = q.question_type_id
            WHERE q.tenant_id = v_tenant_id
              AND q.is_active  = true
              AND q.id NOT IN (SELECT question_id FROM correct_qids)
          )

          SELECT id
          FROM picked
          WHERE rn <= allocated

        ) INTO v_question_ids;
        
        INSERT INTO edu.sessions (
          student_id,
          grade,
          total_questions,
          status,
          data,
          tenant_id,
          created_by,
          created_at
        ) VALUES (
          p_student_id,
          v_grade,
          COALESCE(array_length(v_question_ids, 1), 0),
          'IN_PROGRESS',
          jsonb_build_object(
            'question_ids',           to_jsonb(v_question_ids),
            'is_resumed',             false,
            'total_duration_minutes', v_duration_minutes
          ),
          v_tenant_id,
          v_user_id,
          now()
        )
        RETURNING id INTO v_session_id;

        v_session_status := 'IN_PROGRESS';

      END IF;
    END IF;

    -- ── Fetch full question objects ───────────────────────────

    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id',                   q.id,
        'question_type_id',     q.question_type_id,
        'name',                 q.name,
        'name_audio_prompt',    q.name_audio_prompt,
        'options',              q.options,
        'options_audio_prompt', q.options_audio_prompt,
        'hint',                 q.hint,
        'image_url',            q.image_url,
        'sort_order',           q.sort_order,
        'is_confirmation_type', (qt.data->>'is_confirmation_type')::boolean
        -- correct_answer intentionally excluded
      )
      ORDER BY q.sort_order, q.id
    ), '[]'::jsonb)
    INTO v_questions
    FROM edu.questions q inner join edu.question_types qt
    on q.question_type_id = qt.id
    WHERE q.id = ANY(v_question_ids)
      AND q.tenant_id = v_tenant_id
    LIMIT v_no_of_questions ;

    RETURN public.fn_response_success(
      p_data := jsonb_build_object(
        'session_id',             v_session_id,
        'student_id',             p_student_id,
        'grade',                  v_grade,
        'status',                 v_session_status,
        'is_resumed',             v_is_resumed,
        'total_questions',        COALESCE(array_length(v_question_ids, 1), 0),
        'total_duration_minutes', v_duration_minutes,
        'questions',              v_questions,
        'no_of_questions', v_no_of_questions
      ),
      p_message := format(
        'Session %s %s for student %s with %s questions.',
        v_session_id,
        CASE WHEN v_is_resumed THEN 'resumed' ELSE 'started' END,
        p_student_id,
        COALESCE(array_length(v_question_ids, 1), 0)
      ),
      p_total_records := COALESCE(array_length(v_question_ids, 1), 0),
      p_page_size     := COALESCE(array_length(v_question_ids, 1), 0),
      p_page_index    := 1
    );

  EXCEPTION WHEN OTHERS THEN
    RETURN public.fn_response_error(
      p_function_name := 'edu.fn_start_session',
      p_message       := SQLERRM,
      p_data          := '{}'::jsonb,
      p_tenant_id     := v_tenant_id,
      p_user_id       := v_user_id
    );
  END;
END;
$function$
