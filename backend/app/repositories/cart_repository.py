from typing import Any, Dict, List, Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database


class CartRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["carts"]

    async def get_cart_by_user_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"userId": user_id})

    async def save_cart(self, user_id: str, items: List[Dict[str, Any]]) -> Dict[str, Any]:
        await self._collection.update_one(
            {"userId": user_id},
            {"$set": {"userId": user_id, "items": items}},
            upsert=True,
        )
        saved = await self._collection.find_one({"userId": user_id})
        if saved is None:
            raise RuntimeError("Failed to save cart.")
        return saved

    async def clear_cart(self, user_id: str) -> None:
        await self._collection.update_one(
            {"userId": user_id},
            {"$set": {"userId": user_id, "items": []}},
            upsert=True,
        )


def get_cart_repository() -> CartRepository:
    return CartRepository(get_database())
