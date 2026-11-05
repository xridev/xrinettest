from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt

from app.core.config import settings


def create_access_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)

    payload = {
        "sub": user_id,
        "type": "access",
        "jti": str(uuid4()),
        "iat": now,
        "exp": now + timedelta(
            minutes=settings.access_token_expire_minutes
        ),
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )



def get_refresh_token_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(
        days=settings.refresh_token_expire_days
    )

def create_refresh_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)

    payload = {
        "sub": user_id,
        "type": "refresh",
        "jti": str(uuid4()),
        "iat": now,
        "exp": get_refresh_token_expiry(),
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_token(token: str, expected_type: str | None = None) -> dict:
    payload = jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
    )

    if not isinstance(payload.get("sub"), str) or not payload["sub"]:
        raise jwt.InvalidTokenError("Invalid token subject.")

    if not isinstance(payload.get("jti"), str) or not payload["jti"]:
        raise jwt.InvalidTokenError("Invalid token identifier.")

    token_type = payload.get("type")

    if token_type not in {"access", "refresh"}:
        raise jwt.InvalidTokenError("Invalid token type.")

    if expected_type is not None and token_type != expected_type:
        raise jwt.InvalidTokenError("Unexpected token type.")

    return payload
