from pydantic import BaseModel, EmailStr, Field, field_validator


class PasswordResetOTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        return str(value).strip().casefold()

    @field_validator("otp")
    @classmethod
    def validate_otp(cls, value: str) -> str:
        if not value.isdigit():
            raise ValueError("OTP must contain exactly 6 digits.")
        return value


class PasswordResetResponse(BaseModel):
    message: str



class PasswordResetRequest(BaseModel):
    email: EmailStr
    otp: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8, max_length=128)

    @field_validator("otp")
    @classmethod
    def validate_reset_otp(cls, value: str) -> str:
        if not value.isdigit():
            raise ValueError("OTP must contain exactly 6 digits.")
        return value

    @field_validator("email")
    @classmethod
    def normalize_reset_email(cls, value: EmailStr) -> str:
        return str(value).strip().casefold()
