from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.auth import AuthPageResponse


class AuthPageRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["auth_pages"]

    async def get_page(self, slug: str) -> AuthPageResponse:
        document = await self._collection.find_one({"slug": slug})
        if document is None:
            raise RuntimeError(f"Auth page seed data is missing for slug: {slug}")

        document.pop("_id", None)
        document.pop("slug", None)
        return AuthPageResponse.model_validate(document)


def get_auth_page_repository() -> AuthPageRepository:
    return AuthPageRepository(get_database())
