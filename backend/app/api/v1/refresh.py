from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.login import LoginResponse
from app.schemas.refresh import RefreshRequest
from app.services.refresh_manager import RefreshManager


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/refresh", response_model=LoginResponse)
async def refresh_tokens(
    data: RefreshRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    await enforce_ip_rate_limit(
        request,
        scope="refresh",
        limit=30,
        window_seconds=60,
    )

    manager = RefreshManager(db)

    try:
        return await manager.refresh(data.refresh_token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        ) from exc
