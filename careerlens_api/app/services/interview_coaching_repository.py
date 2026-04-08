import json

from sqlalchemy import text

from app.config import settings
from app.db import SessionLocal
from app.schemas.interview_coaching import (
    CoachingKickoffResult,
    CoachingQuestion,
    InterviewSessionView,
    InterviewTurnView,
    TurnCoachingResult,
    TurnEvaluation,
)
from app.schemas.profile import StructuredProfile, normalize_stored_profile


class InterviewNotFoundError(ValueError):
    pass


class InterviewStateError(ValueError):
    pass


class InterviewCoachingRepository:
    _STAGE_SEQUENCE = (
        "intro",
        "motivation",
        "behavioral",
        "role_fit",
        "technical",
        "wrap_up",
    )

    def fetch_current_profile(self, *, user_id: str) -> StructuredProfile:
        with SessionLocal.begin() as session:
            row = session.execute(
                text(
                    """
                    select authoritative_profile
                    from public.profiles
                    where id = :user_id
                    """
                ),
                {"user_id": user_id},
            ).mappings().first()

            if row is None:
                raise ValueError(f"Profile not found for user_id={user_id}")

            return StructuredProfile.model_validate(
                normalize_stored_profile(row["authoritative_profile"])
            )

    def create_session(
        self,
        *,
        user_id: str,
        raw_job_text: str,
        location: str,
        kickoff: CoachingKickoffResult,
    ) -> InterviewSessionView:
        with SessionLocal.begin() as session:
            session_row = session.execute(
                text(
                    """
                    insert into public.interview_coaching_sessions (
                        user_id,
                        raw_job_text,
                        location,
                        current_readiness_score,
                        session_summary,
                        focus_areas,
                        performance_trend,
                        ai_model,
                        current_stage,
                        ready_to_finish
                    )
                    values (
                        :user_id,
                        :raw_job_text,
                        :location,
                        :current_readiness_score,
                        :session_summary,
                        cast(:focus_areas as jsonb),
                        cast(:performance_trend as jsonb),
                        :ai_model,
                        :current_stage,
                        :ready_to_finish
                    )
                    returning id
                    """
                ),
                {
                    "user_id": user_id,
                    "raw_job_text": raw_job_text,
                    "location": location or None,
                    "current_readiness_score": kickoff.readiness_score,
                    "session_summary": kickoff.session_summary,
                    "focus_areas": json.dumps(kickoff.focus_areas),
                    "performance_trend": json.dumps([kickoff.readiness_score]),
                    "ai_model": settings.openai_model,
                    "current_stage": "intro",
                    "ready_to_finish": False,
                },
            ).mappings().one()

            session.execute(
                text(
                    """
                    insert into public.interview_coaching_turns (
                        session_id,
                        turn_no,
                        question_payload
                    )
                    values (
                        :session_id,
                        1,
                        cast(:question_payload as jsonb)
                    )
                    """
                ),
                {
                    "session_id": session_row["id"],
                    "question_payload": kickoff.first_question.model_dump_json(),
                },
            )

        return self.fetch_session_state(
            user_id=user_id,
            session_id=str(session_row["id"]),
        )

    def fetch_session_state(
        self,
        *,
        user_id: str,
        session_id: str,
    ) -> InterviewSessionView:
        with SessionLocal.begin() as session:
            session_row = session.execute(
                text(
                    """
                    select
                        id,
                        current_readiness_score,
                        session_summary,
                        focus_areas,
                        performance_trend,
                        completed_at,
                        current_stage,
                        ready_to_finish,
                        completion_reason
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

            if session_row is None:
                raise InterviewNotFoundError("Interview session not found.")

            turn_rows = session.execute(
                text(
                    """
                    select
                        id,
                        turn_no,
                        question_payload,
                        answer_text,
                        evaluation_payload
                    from public.interview_coaching_turns
                    where session_id = cast(:session_id as uuid)
                    order by turn_no asc
                    """
                ),
                {"session_id": session_id},
            ).mappings().all()

        turns: list[InterviewTurnView] = []
        current_question = None
        session_completed = session_row["completed_at"] is not None

        for row in turn_rows:
            question = CoachingQuestion.model_validate(row["question_payload"])
            evaluation = (
                TurnEvaluation.model_validate(row["evaluation_payload"])
                if row["evaluation_payload"]
                else None
            )
            answer_text = row["answer_text"] or ""
            turn_view = InterviewTurnView(
                turn_id=str(row["id"]),
                turn_no=row["turn_no"],
                question=question,
                answer=answer_text,
                evaluation=evaluation,
            )
            turns.append(turn_view)

            if not session_completed and not answer_text and current_question is None:
                current_question = question

        if not session_completed and current_question is None:
            raise InterviewStateError(
                "Interview session is missing its active question. Please start a new session."
            )

        is_complete = session_completed

        return InterviewSessionView(
            session_id=str(session_row["id"]),
            readiness_score=session_row["current_readiness_score"] or 1,
            performance_trend=list(session_row["performance_trend"] or []),
            session_summary=session_row["session_summary"] or "",
            focus_areas=list(session_row["focus_areas"] or []),
            current_question=current_question,
            turns=turns,
            is_session_complete=is_complete,
            current_stage=session_row["current_stage"] or "intro",
            ready_to_finish=bool(session_row["ready_to_finish"]),
            completion_reason=session_row["completion_reason"],
        )

    def fetch_turn_context(
        self,
        *,
        user_id: str,
        session_id: str,
    ) -> dict:
        session_state = self.fetch_session_state(user_id=user_id, session_id=session_id)
        session_row = None
        with SessionLocal.begin() as session:
            session_row = session.execute(
                text(
                    """
                    select raw_job_text, location
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

        if session_row is None:
            raise InterviewNotFoundError("Interview session not found.")
        if session_state.current_question is None:
            raise InterviewStateError("Interview session is already complete.")

        current_turn_id = next(
            (
                turn.turn_id
                for turn in session_state.turns
                if not turn.answer.strip()
            ),
            None,
        )

        prior_turns = [
            {
                "turn_no": turn.turn_no,
                "question": turn.question.model_dump(),
                "answer": turn.answer,
                "evaluation": turn.evaluation.model_dump() if turn.evaluation else None,
            }
            for turn in session_state.turns
            if turn.answer
        ]

        return {
            "raw_job_text": session_row["raw_job_text"],
            "location": session_row["location"] or "",
            "session_summary": session_state.session_summary,
            "current_question": session_state.current_question.model_dump(),
            "answered_turn_count": len(prior_turns),
            "prior_turns": prior_turns,
            "current_stage": session_state.current_stage or "intro",
            "next_stage": self._next_stage(session_state.current_stage or "intro"),
            "ready_to_finish": bool(session_state.ready_to_finish),
            "current_turn_id": current_turn_id,
        }

    def save_turn_result(
        self,
        *,
        user_id: str,
        session_id: str,
        answer_text: str,
        result: TurnCoachingResult,
        expected_turn_id: str | None = None,
    ) -> InterviewSessionView:
        with SessionLocal.begin() as session:
            session_row = session.execute(
                text(
                    """
                    select
                        current_stage,
                        ready_to_finish,
                        performance_trend,
                        completed_at
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    for update
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

            if session_row is None:
                raise InterviewNotFoundError("Interview session not found.")
            if session_row["completed_at"] is not None:
                raise InterviewStateError("Interview session is already complete.")

            current_turn = session.execute(
                text(
                    """
                    select id, turn_no, question_payload
                    from public.interview_coaching_turns
                    where session_id = cast(:session_id as uuid)
                      and answer_text is null
                    order by turn_no asc
                    limit 1
                    for update
                    """
                ),
                {"session_id": session_id},
            ).mappings().first()

            if current_turn is None:
                raise InterviewStateError("No active interview question was found.")
            if expected_turn_id and str(current_turn["id"]) != expected_turn_id:
                raise InterviewStateError(
                    "This session moved to a different question. Refresh and answer the current question instead."
                )

            trend = list(session_row["performance_trend"] or [])
            trend.append(result.evaluation.readiness_score)
            current_stage = session_row["current_stage"] or "intro"
            next_stage = self._next_stage(current_stage)
            ready_to_finish = bool(session_row["ready_to_finish"]) or next_stage == "wrap_up"

            next_question = result.next_question
            if next_question is None or not next_question.question.strip():
                raise InterviewStateError(
                    "Interview response was invalid: an unfinished session must provide the next question."
                )
            if next_question.stage is None:
                next_question = next_question.model_copy(update={"stage": next_stage})

            evaluation = result.evaluation
            if evaluation.stage is None:
                evaluation = evaluation.model_copy(update={"stage": current_stage})

            updated_turn = session.execute(
                text(
                    """
                    update public.interview_coaching_turns
                    set
                        answer_text = :answer_text,
                        evaluation_payload = cast(:evaluation_payload as jsonb),
                        readiness_score = :readiness_score,
                        updated_at = now()
                    where id = :turn_id
                      and answer_text is null
                    returning id
                    """
                ),
                {
                    "turn_id": current_turn["id"],
                    "answer_text": answer_text,
                    "evaluation_payload": evaluation.model_dump_json(),
                    "readiness_score": evaluation.readiness_score,
                },
            ).mappings().first()

            if updated_turn is None:
                raise InterviewStateError(
                    "This interview turn was already submitted. Refresh the session and try again."
                )

            session.execute(
                text(
                    """
                    insert into public.interview_coaching_turns (
                        session_id,
                        turn_no,
                        question_payload
                    )
                    values (
                        cast(:session_id as uuid),
                        :turn_no,
                        cast(:question_payload as jsonb)
                    )
                    """
                ),
                {
                    "session_id": session_id,
                    "turn_no": current_turn["turn_no"] + 1,
                    "question_payload": next_question.model_dump_json(),
                },
            )

            session.execute(
                text(
                    """
                    update public.interview_coaching_sessions
                    set
                        current_readiness_score = :readiness_score,
                        session_summary = :session_summary,
                        performance_trend = cast(:performance_trend as jsonb),
                        current_stage = :current_stage,
                        ready_to_finish = :ready_to_finish,
                        updated_at = now(),
                        ai_model = :ai_model
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {
                    "session_id": session_id,
                    "user_id": user_id,
                    "readiness_score": evaluation.readiness_score,
                    "session_summary": result.session_summary,
                    "performance_trend": json.dumps(trend),
                    "current_stage": next_stage,
                    "ready_to_finish": ready_to_finish,
                    "ai_model": settings.openai_model,
                },
            )

        return self.fetch_session_state(user_id=user_id, session_id=session_id)

    def finish_session(self, *, user_id: str, session_id: str) -> InterviewSessionView:
        with SessionLocal.begin() as session:
            session_row = session.execute(
                text(
                    """
                    select id, completed_at
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    for update
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

            if session_row is None:
                raise InterviewNotFoundError("Interview session not found.")
            if session_row["completed_at"] is not None:
                raise InterviewStateError("Interview session is already complete.")

            session.execute(
                text(
                    """
                    update public.interview_coaching_sessions
                    set
                        ready_to_finish = true,
                        completion_reason = 'user_finished',
                        completed_at = now(),
                        updated_at = now(),
                        ai_model = :ai_model
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {
                    "session_id": session_id,
                    "user_id": user_id,
                    "ai_model": settings.openai_model,
                },
            )

        return self.fetch_session_state(user_id=user_id, session_id=session_id)

    def _next_stage(self, current_stage: str) -> str:
        try:
            index = self._STAGE_SEQUENCE.index(current_stage)
        except ValueError:
            return self._STAGE_SEQUENCE[0]

        if index >= len(self._STAGE_SEQUENCE) - 1:
            return self._STAGE_SEQUENCE[-1]
        return self._STAGE_SEQUENCE[index + 1]
