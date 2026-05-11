import asyncio
import json
from pathlib import Path
import sys

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.core.database import close_mongo_connection, connect_to_mongo, get_database

CONTACT_PAGE_PATH = BACKEND_DIR / "data" / "contact_page.json"


async def import_contact_page() -> None:
    try:
        await connect_to_mongo()
        database = get_database()
        collection = database["contact_pages"]

        with CONTACT_PAGE_PATH.open("r", encoding="utf-8") as file:
            document = json.load(file)

        await collection.update_one(
            {"slug": "main"},
            {"$set": {"slug": "main", **document}},
            upsert=True,
        )
        print("Imported contact page data into MongoDB collection: contact_pages")
    except Exception as error:
        raise RuntimeError(
            "Failed to import contact page data. Check MONGODB_URI and ensure MongoDB is running."
        ) from error
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(import_contact_page())
