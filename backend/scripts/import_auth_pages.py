import asyncio
import json
from pathlib import Path
import sys

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.core.database import close_mongo_connection, connect_to_mongo, get_database

LOGIN_PAGE_PATH = BACKEND_DIR / "data" / "login_page.json"
REGISTER_PAGE_PATH = BACKEND_DIR / "data" / "register_page.json"


async def import_auth_pages() -> None:
    try:
        await connect_to_mongo()
        database = get_database()
        collection = database["auth_pages"]

        for slug, path in (
            ("login", LOGIN_PAGE_PATH),
            ("register", REGISTER_PAGE_PATH),
        ):
            with path.open("r", encoding="utf-8") as file:
                document = json.load(file)

            await collection.update_one(
                {"slug": slug},
                {"$set": {"slug": slug, **document}},
                upsert=True,
            )

        print("Imported auth page data into MongoDB collection: auth_pages")
    except Exception as error:
        raise RuntimeError(
            "Failed to import auth page data. Check MONGODB_URI and ensure MongoDB is running."
        ) from error
    finally:
        await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(import_auth_pages())
