from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest
from sqlalchemy import select

from app.models import EmailOTP, User, UserSession
from app.schemas.password_reset import PasswordResetRequest
from app.services.otp_service import hash_otp
from app.services.password_reset_manager import PasswordResetManager
from app.services.password_service import hash_password, verify_password


@pytest.mark.asyncio
async def test_password_reset_updates_password_and_revokes_sessions(db_session):
    email = "reset-integration@example.com"
    old_password = "OldPassword123!"
    new_password = "NewPassword456!"
    otp_value = "123456"

    user = User(
        email=email,
        password_hash=hash_password(old_password),
        is_email_verified=True,
        is_active=True,
    )

    async with db_session.begin():
        db_session.add(user)
        await db_session.flush()

        otp = EmailOTP(
            email=email,
            purpose="password_reset",
            otp_hash=hash_otp(
                otp_value,
                email,
                purpose="password_reset",
            ),
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            is_verified=True,
            is_used=False,
            attempts=0,
        )

        session = UserSession(
            user_id=user.id,
            refresh_token_jti=str(uuid4()),
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
        )

        db_session.add_all([otp, session])
        await db_session.flush()

        user_id = user.id
        otp_id = otp.id
        session_id = session.id

    request = PasswordResetRequest(
        email=email,
        otp=otp_value,
        new_password=new_password,
    )

    response = await PasswordResetManager(db_session).reset_password(request)

    assert response.message.startswith("Password reset successfully")

    user_after = await db_session.get(User, user_id)
    otp_after = await db_session.get(EmailOTP, otp_id)
    session_after = await db_session.get(UserSession, session_id)

    assert user_after is not None
    assert verify_password(new_password, user_after.password_hash)
    assert not verify_password(old_password, user_after.password_hash)

    assert otp_after is not None
    assert otp_after.is_used is True

    await db_session.refresh(session_after)
    assert session_after is not None
    assert session_after.revoked_at is not None
