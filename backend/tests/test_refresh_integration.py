import pytest
from sqlalchemy import select

from app.models import User, UserSession
from app.schemas.login import LoginRequest
from app.services.login_manager import LoginManager
from app.services.refresh_manager import RefreshManager
from app.services.password_service import hash_password
from app.services.token_service import decode_token


@pytest.mark.asyncio
async def test_refresh_token_rotation(db_session):
    email = "refresh-integration@example.com"
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

    old_payload = decode_token(
        login.refresh_token,
        expected_type="refresh",
    )

    refreshed = await RefreshManager(db_session).refresh(
        login.refresh_token
    )

    new_access = decode_token(
        refreshed.access_token,
        expected_type="access",
    )
    new_refresh = decode_token(
        refreshed.refresh_token,
        expected_type="refresh",
    )

    assert new_access["sub"] == str(user_id)
    assert new_refresh["sub"] == str(user_id)
    assert new_refresh["jti"] != old_payload["jti"]

    old_session = await db_session.scalar(
        select(UserSession).where(
            UserSession.refresh_token_jti == old_payload["jti"]
        )
    )

    assert old_session is not None
    assert old_session.revoked_at is not None

    new_session = await db_session.scalar(
        select(UserSession).where(
            UserSession.refresh_token_jti == new_refresh["jti"]
        )
    )

    assert new_session is not None
    assert new_session.user_id == user_id
    assert new_session.revoked_at is None

    await db_session.rollback()

    with pytest.raises(ValueError, match="Invalid or expired refresh token"):
        await RefreshManager(db_session).refresh(login.refresh_token)
