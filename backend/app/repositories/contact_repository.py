from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.models.contact import ContactPageResponse


class ContactSubmissionRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["contact_submissions"]

    async def create_submission(self, document: dict) -> None:
        await self._collection.insert_one(document)


class ContactRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["contact_pages"]

    async def get_page(self, slug: str = "main") -> ContactPageResponse:
        document = await self._collection.find_one({"slug": slug})
        if document is None:
            raise RuntimeError(f"Contact page seed data is missing for slug: {slug}")

        document.pop("_id", None)
        document.pop("slug", None)
        return ContactPageResponse.model_validate(document)


def get_contact_repository() -> ContactRepository:
    return ContactRepository(get_database())


def get_contact_submission_repository() -> ContactSubmissionRepository:
    return ContactSubmissionRepository(get_database())
