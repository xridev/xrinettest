from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.otp import OTPResponse
from app.schemas.password_reset import (
    PasswordResetOTPVerifyRequest,
    PasswordResetRequest,
    PasswordResetResponse,
)
from app.services.password_reset_manager import PasswordResetManager


router = APIRouter(prefix="/auth/password", tags=["Password Reset"])


@router.post("/verify-otp", response_model=OTPResponse)
async def verify_password_reset_otp(
    data: PasswordResetOTPVerifyRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> OTPResponse:
    await enforce_ip_rate_limit(
        request,
        scope="password-reset-verify",
        limit=10,
        window_seconds=60,
    )

    manager = PasswordResetManager(db)

    verified = await manager.verify_reset_otp(data)

    if not verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset OTP.",
        )

    return OTPResponse(message="Password reset OTP verified successfully.")


@router.post("/reset", response_model=PasswordResetResponse)
async def reset_password(
    data: PasswordResetRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> PasswordResetResponse:
    await enforce_ip_rate_limit(
        request,
        scope="password-reset",
        limit=5,
        window_seconds=60,
    )

    manager = PasswordResetManager(db)

    try:
        return await manager.reset_password(data)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset proof.",
        ) from exc
