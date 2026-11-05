from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.login_security import (
    check_login_lock,
    record_login_failure,
    reset_login_failures,
)
from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.login import LoginRequest, LoginResponse
from app.services.login_manager import LoginManager


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/login",
    response_model=LoginResponse,
)
async def login(
    data: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    await enforce_ip_rate_limit(
        request,
        scope="login",
        limit=10,
        window_seconds=60,
    )

    client_ip = request.client.host if request.client else "unknown"

    await check_login_lock(data.email, client_ip)

    manager = LoginManager(db)

    try:
        response = await manager.login(data)
    except ValueError as exc:
        await record_login_failure(data.email, client_ip)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc

    await reset_login_failures(data.email, client_ip)
    return response
