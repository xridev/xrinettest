from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.otp_repository import OTPRepository
from app.services.otp_policy import (
    can_resend_otp,
    get_otp_expiry,
    has_attempts_remaining,
    is_otp_expired,
)
from app.services.otp_service import generate_otp, hash_otp, verify_otp


class OTPManager:
    LOCKOUT_DURATIONS = (
        timedelta(minutes=30),
        timedelta(hours=1),
        timedelta(hours=3),
    )

    def __init__(self, db: AsyncSession):
        self.repository = OTPRepository(db)

    async def _get_security_state(self, email: str, purpose: str):
        await self.repository.acquire_security_lock(email, purpose)

        state = await self.repository.get_security_state(
            email,
            purpose,
            for_update=True,
        )

        if state is None:
            state = await self.repository.create_security_state(
                email,
                purpose,
            )

        return state

    def _is_locked(self, state) -> bool:
        if state.locked_until is None:
            return False

        locked_until = state.locked_until
        if locked_until.tzinfo is None:
            locked_until = locked_until.replace(tzinfo=timezone.utc)

        now = datetime.now(timezone.utc)

        if now < locked_until:
            return True

        state.locked_until = None
        state.failed_attempts = 0
        return False

    async def issue_otp(
        self,
        email: str,
        purpose: str = "signup",
    ) -> str:
        normalized_email = email.strip().casefold()
        state = await self._get_security_state(
            normalized_email,
            purpose,
        )

        if self._is_locked(state):
            raise ValueError("OTP requests are temporarily locked. Please try again later.")

        existing = await self.repository.get_latest(
            normalized_email,
            purpose,
            for_update=True,
        )

        if existing and not can_resend_otp(existing.created_at):
            raise ValueError("Please wait before requesting another OTP.")

        await self.repository.invalidate_active(
            normalized_email,
            purpose,
        )

        otp = generate_otp()
        otp_hash = hash_otp(otp, normalized_email, purpose)

        await self.repository.create(
            email=normalized_email,
            purpose=purpose,
            otp_hash=otp_hash,
            expires_at=get_otp_expiry(),
        )

        return otp

    async def verify_email_otp(
        self,
        email: str,
        otp: str,
        purpose: str = "signup",
    ) -> bool:
        normalized_email = email.strip().casefold()
        state = await self._get_security_state(
            normalized_email,
            purpose,
        )

        if self._is_locked(state):
            return False

        existing = await self.repository.get_latest(
            normalized_email,
            purpose,
            for_update=True,
        )

        if existing is None:
            return False

        if is_otp_expired(existing.expires_at):
            return False

        if not has_attempts_remaining(existing.attempts):
            return False

        if not verify_otp(
            otp,
            existing.otp_hash,
            normalized_email,
            purpose,
        ):
            await self.repository.increment_attempts(existing)

            state.failed_attempts += 1

            if state.failed_attempts >= 5:
                index = min(
                    state.lockout_count,
                    len(self.LOCKOUT_DURATIONS) - 1,
                )
                state.lockout_count += 1
                state.failed_attempts = 0
                state.locked_until = (
                    datetime.now(timezone.utc)
                    + self.LOCKOUT_DURATIONS[index]
                )

            await self.repository.db.flush()
            return False

        await self.repository.mark_verified(existing)

        state.failed_attempts = 0
        state.lockout_count = 0
        state.locked_until = None

        await self.repository.db.flush()
        return True
