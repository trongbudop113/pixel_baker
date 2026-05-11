from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.story import StoryPageResponse


class StoryRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["story_pages"]

    async def get_page(self, slug: str = "main") -> StoryPageResponse:
        document = await self._collection.find_one({"slug": slug})
        if document is None:
            raise RuntimeError(f"Story page seed data is missing for slug: {slug}")

        document.pop("_id", None)
        document.pop("slug", None)
        return StoryPageResponse.model_validate(document)


def get_story_repository() -> StoryRepository:
    return StoryRepository(get_database())
