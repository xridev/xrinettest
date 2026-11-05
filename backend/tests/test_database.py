import pytest
from sqlalchemy import text

from app.models import User, UserProfile, EmailOTP, UserSession


@pytest.mark.asyncio
async def test_postgresql_connection_and_auth_tables(db_session):
    result = await db_session.execute(
        text("SELECT current_database(), current_user")
    )
    database_name, database_user = result.one()

    assert database_name == "xrinet"
    assert database_user == "xrinet"

    expected_tables = {
        "users",
        "user_profiles",
        "email_otps",
        "user_sessions",
    }

    result = await db_session.execute(
        text("""
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'public'
        """)
    )
    actual_tables = {row[0] for row in result}

    assert expected_tables.issubset(actual_tables)
    assert all([
        User,
        UserProfile,
        EmailOTP,
        UserSession,
    ])
