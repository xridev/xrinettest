from pydantic import BaseModel, EmailStr, field_validator


class ForgotPasswordRequest(BaseModel):
    email: EmailStr

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: EmailStr) -> str:
        return str(value).strip().casefold()


class ForgotPasswordResponse(BaseModel):
    message: str = (
        "If an account exists for this email, "
        "password reset instructions will be sent."
    )
