from typing import Any, Dict, List, Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database


class OrderRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["orders"]

    async def create_order(self, document: Dict[str, Any]) -> Dict[str, Any]:
        await self._collection.insert_one(document)
        created = await self._collection.find_one({"orderId": document["orderId"]})
        if created is None:
            raise RuntimeError("Failed to create order.")
        return created

    async def list_orders_by_user_id(self, user_id: str) -> List[Dict[str, Any]]:
        cursor = self._collection.find({"userId": user_id}).sort("createdAt", -1)
        return await cursor.to_list(length=100)

    async def get_order_by_user_and_order_id(
        self,
        user_id: str,
        order_id: str,
    ) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one(
            {"userId": user_id, "orderId": order_id},
        )

    async def get_order_by_order_id(self, order_id: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"orderId": order_id})

    async def update_order(
        self,
        order_id: str,
        updates: Dict[str, Any],
    ) -> Optional[Dict[str, Any]]:
        await self._collection.update_one(
            {"orderId": order_id},
            {"$set": updates},
        )
        return await self._collection.find_one({"orderId": order_id})

    async def append_timeline_entry(
        self,
        order_id: str,
        entry: Dict[str, Any],
    ) -> Optional[Dict[str, Any]]:
        await self._collection.update_one(
            {"orderId": order_id},
            {"$push": {"timeline": entry}},
        )
        return await self._collection.find_one({"orderId": order_id})


def get_order_repository() -> OrderRepository:
    return OrderRepository(get_database())
