import base64
import io
import json
import os
import uuid
from dataclasses import dataclass

from app.core.config import settings


@dataclass(frozen=True)
class StoredImage:
    url: str


class LocalImageStorage:
    def __init__(self, upload_dir: str):
        self._upload_dir = upload_dir

    async def save(
        self,
        *,
        contents: bytes,
        original_filename: str,
        content_type: str,
    ) -> StoredImage:
        del content_type
        filename = _safe_image_filename(original_filename)
        os.makedirs(self._upload_dir, exist_ok=True)
        filepath = os.path.join(self._upload_dir, filename)
        with open(filepath, "wb") as file:
            file.write(contents)
        return StoredImage(url=f"/uploads/{filename}")


class GoogleDriveImageStorage:
    def __init__(self, folder_id: str):
        self._folder_id = folder_id.strip()

    async def save(
        self,
        *,
        contents: bytes,
        original_filename: str,
        content_type: str,
    ) -> StoredImage:
        if not self._folder_id:
            raise RuntimeError("GOOGLE_DRIVE_FOLDER_ID is missing.")

        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaIoBaseUpload

        credentials = service_account.Credentials.from_service_account_info(
            _google_service_account_info(),
            scopes=["https://www.googleapis.com/auth/drive.file"],
        )
        service = build("drive", "v3", credentials=credentials, cache_discovery=False)
        filename = _safe_image_filename(original_filename)
        media = MediaIoBaseUpload(
            io.BytesIO(contents),
            mimetype=content_type,
            resumable=False,
        )
        created = (
            service.files()
            .create(
                body={"name": filename, "parents": [self._folder_id]},
                media_body=media,
                fields="id",
            )
            .execute()
        )
        file_id = created["id"]
        service.permissions().create(
            fileId=file_id,
            body={"role": "reader", "type": "anyone"},
            fields="id",
        ).execute()
        return StoredImage(url=f"https://lh3.googleusercontent.com/d/{file_id}")


def image_storage(upload_dir: str):
    provider = settings.image_storage_provider.strip().lower()
    if provider in {"google_drive", "drive"}:
        return GoogleDriveImageStorage(settings.google_drive_folder_id)
    return LocalImageStorage(upload_dir)


def _safe_image_filename(original_filename: str) -> str:
    ext = (original_filename or "image.jpg").rsplit(".", 1)[-1].lower()
    if ext not in {"jpg", "jpeg", "png", "webp", "gif"}:
        ext = "jpg"
    return f"{uuid.uuid4().hex}.{ext}"


def _google_service_account_info() -> dict:
    if settings.google_drive_service_account_base64.strip():
        decoded = base64.b64decode(settings.google_drive_service_account_base64)
        return json.loads(decoded.decode("utf-8"))
    if settings.google_drive_service_account_json.strip():
        return json.loads(settings.google_drive_service_account_json)
    raise RuntimeError("Google Drive service account credentials are missing.")
