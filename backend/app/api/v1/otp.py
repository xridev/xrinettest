from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rate_limit import enforce_ip_rate_limit
from app.db.database import get_db
from app.schemas.otp import OTPVerifyRequest, OTPResponse
from app.services.otp_manager import OTPManager


router = APIRouter(prefix="/auth/otp", tags=["Email OTP"])


@router.post(
    "/verify",
    response_model=OTPResponse,
)
async def verify_email_otp(
    data: OTPVerifyRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> OTPResponse:
    await enforce_ip_rate_limit(
        request,
        scope="otp-verify",
        limit=30,
        window_seconds=60,
    )

    manager = OTPManager(db)

    async with db.begin():
        verified = await manager.verify_email_otp(
            email=str(data.email),
            otp=data.otp,
            purpose="signup",
        )

    if not verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP.",
        )

    return OTPResponse(message="Email verified successfully.")
