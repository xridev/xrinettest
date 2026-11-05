from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.database import close_database
from app.db.redis import close_redis
from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.otp import router as otp_router
from app.api.v1.login import router as login_router
from app.api.v1.refresh import router as refresh_router
from app.api.v1.logout import router as logout_router
from app.api.v1.password_reset import router as password_reset_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_database()
    await close_redis()


app = FastAPI(
    title=settings.app_name,
    debug=settings.debug,
    lifespan=lifespan,
)

if settings.cors_origins_list:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(
    health_router,
    prefix=settings.api_v1_prefix,
)

app.include_router(auth_router, prefix=settings.api_v1_prefix)
app.include_router(otp_router, prefix=settings.api_v1_prefix)
app.include_router(login_router, prefix=settings.api_v1_prefix)
app.include_router(refresh_router, prefix=settings.api_v1_prefix)
app.include_router(logout_router, prefix=settings.api_v1_prefix)
app.include_router(password_reset_router, prefix=settings.api_v1_prefix)
