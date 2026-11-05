from abc import ABC, abstractmethod


class EmailService(ABC):
    @abstractmethod
    async def send_otp(
        self,
        email: str,
        otp: str,
        purpose: str = "signup",
    ) -> bool:
        """Send an OTP email through the configured provider."""
        raise NotImplementedError
