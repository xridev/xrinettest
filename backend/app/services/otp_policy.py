from datetime import datetime, timedelta, timezone

from app.core.config import settings


def get_otp_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(
        minutes=settings.otp_expire_minutes
    )


def is_otp_expired(expires_at: datetime) -> bool:
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    return datetime.now(timezone.utc) >= expires_at


def has_attempts_remaining(attempts: int) -> bool:
    return attempts < settings.otp_max_attempts


def can_resend_otp(created_at: datetime) -> bool:
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=timezone.utc)

    cooldown = timedelta(
        seconds=settings.otp_resend_cooldown_seconds
    )

    return datetime.now(timezone.utc) >= created_at + cooldown
