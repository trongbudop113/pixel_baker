from typing import Optional

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.core.config import settings

mongo_client: Optional[AsyncIOMotorClient] = None
database: Optional[AsyncIOMotorDatabase] = None


async def connect_to_mongo() -> None:
    global mongo_client, database
    mongo_client = AsyncIOMotorClient(
        settings.mongodb_uri,
        serverSelectionTimeoutMS=settings.mongodb_timeout_ms,
    )
    database = mongo_client[settings.mongodb_db]
    await mongo_client.admin.command("ping")


async def close_mongo_connection() -> None:
    global mongo_client, database
    if mongo_client is not None:
        mongo_client.close()
    mongo_client = None
    database = None


def get_database() -> AsyncIOMotorDatabase:
    if database is None:
        raise RuntimeError("MongoDB connection has not been initialized.")
    return database
