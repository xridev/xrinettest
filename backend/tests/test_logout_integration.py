import pytest
from sqlalchemy import select

from app.models import User, UserSession
from app.schemas.login import LoginRequest
from app.services.login_manager import LoginManager
from app.services.logout_manager import LogoutManager
from app.services.password_service import hash_password
from app.services.token_service import decode_token


@pytest.mark.asyncio
async def test_logout_revokes_session(db_session):
    email = "logout-integration@example.com"
    password = "TestPassword123!"

    user = User(
        email=email,
        password_hash=hash_password(password),
        is_email_verified=True,
        is_active=True,
    )

    async with db_session.begin():
        db_session.add(user)
        await db_session.flush()
        user_id = user.id

    login = await LoginManager(db_session).login(
        LoginRequest(email=email, password=password)
    )

    payload = decode_token(
        login.refresh_token,
        expected_type="refresh",
    )

    result = await LogoutManager(db_session).logout(
        login.refresh_token
    )

    assert result is True

    session = await db_session.scalar(
        select(UserSession).where(
            UserSession.refresh_token_jti == payload["jti"]
        )
    )

    assert session is not None
    assert session.user_id == user_id
    assert session.revoked_at is not None

    await db_session.rollback()
    second_result = await LogoutManager(db_session).logout(
        login.refresh_token
    )

    assert second_result is False
