import pytest_asyncio
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import settings
from app.db.database import engine


@pytest_asyncio.fixture
async def db_session():
    async with engine.connect() as connection:
        outer_transaction = await connection.begin()

        test_session_factory = async_sessionmaker(
            bind=connection,
            class_=AsyncSession,
            expire_on_commit=False,
            autoflush=False,
            join_transaction_mode="create_savepoint",
        )

        try:
            async with test_session_factory() as session:
                yield session
        finally:
            await outer_transaction.rollback()
    await engine.dispose()


@pytest_asyncio.fixture
async def test_redis_client():
    client = Redis.from_url(
        settings.redis_url,
        decode_responses=True,
    )
    try:
        yield client
    finally:
        await client.aclose()


@pytest_asyncio.fixture
async def api_client(db_session, test_redis_client, monkeypatch):
    from httpx import ASGITransport, AsyncClient

    from app.core import rate_limit
    from app.db.database import get_db
    from app.main import app

    async def override_get_db():
        yield db_session

    monkeypatch.setattr(
        rate_limit,
        "redis_client",
        test_redis_client,
    )

    app.dependency_overrides[get_db] = override_get_db

    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(
            transport=transport,
            base_url="http://testserver",
        ) as client:
            yield client
    finally:
        app.dependency_overrides.clear()
