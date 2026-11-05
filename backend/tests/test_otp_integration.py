import pytest
from sqlalchemy import select

from app.models import EmailOTP
from app.services.otp_manager import OTPManager


@pytest.mark.asyncio
async def test_otp_issue_and_verification(db_session):
    email = "otp-integration@example.com"
    manager = OTPManager(db_session)

    otp = await manager.issue_otp(email=email)

    assert len(otp) == 6
    assert otp.isdigit()

    record = await db_session.scalar(
        select(EmailOTP).where(
            EmailOTP.email == email,
            EmailOTP.purpose == "signup",
        )
    )

    assert record is not None
    assert record.is_verified is False
    assert record.is_used is False
    assert record.otp_hash != otp

    wrong_result = await manager.verify_email_otp(
        email=email,
        otp="000000" if otp != "000000" else "000001",
    )

    assert wrong_result is False
    await db_session.refresh(record)
    assert record.attempts == 1

    correct_result = await manager.verify_email_otp(
        email=email,
        otp=otp,
    )

    assert correct_result is True
    await db_session.refresh(record)

    assert record.is_verified is True
    assert record.is_used is False
    assert record.attempts == 1


@pytest.mark.asyncio
async def test_otp_rejects_after_max_attempts(db_session):
    email = "otp-attempt-limit@example.com"
    manager = OTPManager(db_session)

    otp = await manager.issue_otp(email=email)

    for _ in range(5):
        result = await manager.verify_email_otp(
            email=email,
            otp="000000" if otp != "000000" else "000001",
        )
        assert result is False

    record = await db_session.scalar(
        select(EmailOTP).where(
            EmailOTP.email == email,
            EmailOTP.purpose == "signup",
        )
    )

    assert record is not None
    assert record.attempts == 5

    result = await manager.verify_email_otp(email=email, otp=otp)
    assert result is False


@pytest.mark.asyncio
async def test_otp_lockout_after_five_failures(db_session):
    from datetime import timezone
    from app.models import OTPSecurityState

    email = "otp-lockout@example.com"
    manager = OTPManager(db_session)
    otp = await manager.issue_otp(email=email)

    for _ in range(5):
        result = await manager.verify_email_otp(
            email=email,
            otp="000000" if otp != "000000" else "000001",
        )
        assert result is False

    state = await db_session.scalar(
        select(OTPSecurityState).where(
            OTPSecurityState.email == email,
            OTPSecurityState.purpose == "signup",
        )
    )

    assert state is not None
    assert state.lockout_count == 1
    assert state.failed_attempts == 0
    assert state.locked_until is not None

    locked_until = state.locked_until
    if locked_until.tzinfo is None:
        locked_until = locked_until.replace(tzinfo=timezone.utc)

    remaining = (locked_until - __import__("datetime").datetime.now(timezone.utc)).total_seconds()
    assert 1790 <= remaining <= 1800

    with pytest.raises(ValueError, match="temporarily locked"):
        await manager.issue_otp(email=email)

    assert await manager.verify_email_otp(email=email, otp=otp) is False


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("previous_count", "expected_minutes"),
    [(1, 60), (2, 180), (5, 180)],
)
async def test_otp_progressive_lockout_duration(
    db_session,
    previous_count,
    expected_minutes,
):
    from datetime import datetime, timezone
    from app.models import OTPSecurityState

    email = f"otp-progress-{previous_count}@example.com"
    manager = OTPManager(db_session)

    otp = await manager.issue_otp(email=email)

    state = await db_session.scalar(
        select(OTPSecurityState).where(
            OTPSecurityState.email == email,
            OTPSecurityState.purpose == "signup",
        )
    )
    assert state is not None
    state.lockout_count = previous_count
    await db_session.flush()

    for _ in range(5):
        result = await manager.verify_email_otp(
            email=email,
            otp="000000" if otp != "000000" else "000001",
        )
        assert result is False

    await db_session.refresh(state)

    assert state.lockout_count == previous_count + 1
    assert state.locked_until is not None

    locked_until = state.locked_until
    if locked_until.tzinfo is None:
        locked_until = locked_until.replace(tzinfo=timezone.utc)

    remaining = (
        locked_until - datetime.now(timezone.utc)
    ).total_seconds()

    assert expected_minutes * 60 - 10 <= remaining <= expected_minutes * 60
