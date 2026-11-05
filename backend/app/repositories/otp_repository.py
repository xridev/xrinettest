import hashlib
from datetime import datetime, timezone

from sqlalchemy import select, update, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.email_otp import EmailOTP
from app.models.otp_security_state import OTPSecurityState


class OTPRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_latest(
        self,
        email: str,
        purpose: str,
        for_update: bool = False,
    ) -> EmailOTP | None:
        statement = (
            select(EmailOTP)
            .where(
                EmailOTP.email == email.strip().casefold(),
                EmailOTP.purpose == purpose,
                EmailOTP.is_used.is_(False),
                EmailOTP.is_verified.is_(False),
            )
            .order_by(EmailOTP.created_at.desc())
            .limit(1)
        )

        if for_update:
            statement = statement.with_for_update()

        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def get_verified_for_signup(
        self,
        email: str,
        purpose: str = "signup",
        for_update: bool = True,
    ) -> EmailOTP | None:
        statement = (
            select(EmailOTP)
            .where(
                EmailOTP.email == email.strip().casefold(),
                EmailOTP.purpose == purpose,
                EmailOTP.is_verified.is_(True),
                EmailOTP.is_used.is_(False),
                EmailOTP.expires_at > datetime.now(timezone.utc),
            )
            .order_by(EmailOTP.created_at.desc())
            .limit(1)
        )

        if for_update:
            statement = statement.with_for_update()

        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def create(
        self,
        email: str,
        purpose: str,
        otp_hash: str,
        expires_at: datetime,
    ) -> EmailOTP:
        otp = EmailOTP(
            email=email.strip().casefold(),
            purpose=purpose,
            otp_hash=otp_hash,
            expires_at=expires_at,
        )
        self.db.add(otp)
        await self.db.flush()
        return otp

    async def invalidate_active(
        self,
        email: str,
        purpose: str,
    ) -> None:
        statement = (
            update(EmailOTP)
            .where(
                EmailOTP.email == email.strip().casefold(),
                EmailOTP.purpose == purpose,
                EmailOTP.is_used.is_(False),
            )
            .values(is_used=True)
        )
        await self.db.execute(statement)
        await self.db.flush()

    async def increment_attempts(self, otp: EmailOTP) -> None:
        otp.attempts += 1
        await self.db.flush()

    async def mark_verified(self, otp: EmailOTP) -> None:
        otp.is_verified = True
        await self.db.flush()

    async def consume_verified(self, otp: EmailOTP) -> None:
        otp.is_used = True
        await self.db.flush()

    async def get_verified_for_purpose(
        self,
        email: str,
        purpose: str,
        for_update: bool = True,
    ) -> EmailOTP | None:
        statement = (
            select(EmailOTP)
            .where(
                EmailOTP.email == email.strip().casefold(),
                EmailOTP.purpose == purpose,
                EmailOTP.is_verified.is_(True),
                EmailOTP.is_used.is_(False),
                EmailOTP.expires_at > datetime.now(timezone.utc),
            )
            .order_by(EmailOTP.created_at.desc())
            .limit(1)
        )

        if for_update:
            statement = statement.with_for_update()

        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def acquire_security_lock(self, email: str, purpose: str) -> None:
        normalized_email = email.strip().casefold()
        lock_key = int.from_bytes(
            hashlib.sha256(
                f"{purpose}:{normalized_email}".encode("utf-8")
            ).digest()[:8],
            byteorder="big",
            signed=True,
        )
        await self.db.execute(
            text("SELECT pg_advisory_xact_lock(:lock_key)"),
            {"lock_key": lock_key},
        )

    async def get_security_state(
        self,
        email: str,
        purpose: str,
        for_update: bool = True,
    ) -> OTPSecurityState | None:
        statement = select(OTPSecurityState).where(
            OTPSecurityState.email == email.strip().casefold(),
            OTPSecurityState.purpose == purpose,
        )
        if for_update:
            statement = statement.with_for_update()
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()

    async def create_security_state(
        self,
        email: str,
        purpose: str,
    ) -> OTPSecurityState:
        state = OTPSecurityState(
            email=email.strip().casefold(),
            purpose=purpose,
        )
        self.db.add(state)
        await self.db.flush()
        return state
