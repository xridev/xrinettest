from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.signup import SignupRequest, SignupResponse
from app.services.signup_manager import SignupManager


router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/signup",
    response_model=SignupResponse,
    status_code=status.HTTP_201_CREATED,
)
async def signup(
    data: SignupRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> SignupResponse:
    await enforce_ip_rate_limit(
        request,
        scope="signup",
        limit=5,
        window_seconds=60,
    )

    manager = SignupManager(db)

    try:
        return await manager.register(data)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
