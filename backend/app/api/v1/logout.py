from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.logout import LogoutRequest, LogoutResponse
from app.services.logout_manager import LogoutManager

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/logout", response_model=LogoutResponse)
async def logout(
    data: LogoutRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> LogoutResponse:
    await enforce_ip_rate_limit(
        request,
        scope="logout",
        limit=30,
        window_seconds=60,
    )

    manager = LogoutManager(db)

    success = await manager.logout(data.refresh_token)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token.",
        )

    return LogoutResponse()
