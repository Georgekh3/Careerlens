import json

from sqlalchemy import text

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


class InterviewCoachingRepository:
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
                        ai_model
                    )
                    values (
                        :user_id,
                        :raw_job_text,
                        :location,
                        :current_readiness_score,
                        :session_summary,
                        cast(:focus_areas as jsonb),
                        cast(:performance_trend as jsonb),
                        :ai_model
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
                    "ai_model": "openai",
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
                        completed_at
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

            if session_row is None:
                raise ValueError("Interview session not found.")

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

            if not answer_text and current_question is None:
                current_question = question

        is_complete = session_row["completed_at"] is not None or current_question is None

        return InterviewSessionView(
            session_id=str(session_row["id"]),
            readiness_score=session_row["current_readiness_score"] or 1,
            performance_trend=list(session_row["performance_trend"] or []),
            session_summary=session_row["session_summary"] or "",
            focus_areas=list(session_row["focus_areas"] or []),
            current_question=current_question,
            turns=turns,
            is_session_complete=is_complete,
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
            raise ValueError("Interview session not found.")
        if session_state.current_question is None:
            raise ValueError("Interview session is already complete.")

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
        }

    def save_turn_result(
        self,
        *,
        user_id: str,
        session_id: str,
        answer_text: str,
        result: TurnCoachingResult,
    ) -> InterviewSessionView:
        with SessionLocal.begin() as session:
            current_turn = session.execute(
                text(
                    """
                    select id, turn_no
                    from public.interview_coaching_turns
                    where session_id = cast(:session_id as uuid)
                      and answer_text is null
                    order by turn_no asc
                    limit 1
                    """
                ),
                {"session_id": session_id},
            ).mappings().first()

            if current_turn is None:
                raise ValueError("No active interview question was found.")

            session_row = session.execute(
                text(
                    """
                    select performance_trend
                    from public.interview_coaching_sessions
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {"session_id": session_id, "user_id": user_id},
            ).mappings().first()

            if session_row is None:
                raise ValueError("Interview session not found.")

            trend = list(session_row["performance_trend"] or [])
            trend.append(result.evaluation.readiness_score)

            session.execute(
                text(
                    """
                    update public.interview_coaching_turns
                    set
                        answer_text = :answer_text,
                        evaluation_payload = cast(:evaluation_payload as jsonb),
                        readiness_score = :readiness_score,
                        updated_at = now()
                    where id = :turn_id
                    """
                ),
                {
                    "turn_id": current_turn["id"],
                    "answer_text": answer_text,
                    "evaluation_payload": result.evaluation.model_dump_json(),
                    "readiness_score": result.evaluation.readiness_score,
                },
            )

            if not result.is_session_complete and result.next_question is not None:
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
                        "question_payload": result.next_question.model_dump_json(),
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
                        updated_at = now(),
                        completed_at = case
                            when :is_complete then now()
                            else completed_at
                        end
                    where id = cast(:session_id as uuid)
                      and user_id = cast(:user_id as uuid)
                    """
                ),
                {
                    "session_id": session_id,
                    "user_id": user_id,
                    "readiness_score": result.evaluation.readiness_score,
                    "session_summary": result.session_summary,
                    "performance_trend": json.dumps(trend),
                    "is_complete": result.is_session_complete,
                },
            )

        return self.fetch_session_state(user_id=user_id, session_id=session_id)
