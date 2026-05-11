from typing import Any, Dict, List, Optional

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database


class VoucherRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self._collection = database["vouchers"]

    async def list_vouchers(self) -> List[Dict[str, Any]]:
        cursor = self._collection.find({})
        return await cursor.to_list(length=100)

    async def get_voucher_by_code(self, code: str) -> Optional[Dict[str, Any]]:
        return await self._collection.find_one({"code": code.upper().strip()})

    async def create_voucher(self, document: Dict[str, Any]) -> Dict[str, Any]:
        await self._collection.insert_one(document)
        created = await self._collection.find_one({"code": document["code"]})
        if created is None:
            raise RuntimeError("Failed to create voucher.")
        return created

    async def update_voucher(self, code: str, document: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        await self._collection.update_one(
            {"code": code.upper().strip()},
            {"$set": document},
        )
        return await self._collection.find_one({"code": code.upper().strip()})

    async def delete_voucher(self, code: str) -> bool:
        result = await self._collection.delete_one({"code": code.upper().strip()})
        return result.deleted_count > 0


def get_voucher_repository() -> VoucherRepository:
    return VoucherRepository(get_database())
