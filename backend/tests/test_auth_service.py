import unittest

from fastapi import HTTPException

from app.models.auth import LoginRequest, RefreshTokenRequest, RegisterRequest, UserRole
from app.services.auth_service import AuthService


class _FakeUserRepository:
    def __init__(self):
        self.by_email = {}
        self.by_id = {}

    async def get_user_by_email(self, email):
        return self.by_email.get(email.lower().strip())

    async def create_user(self, payload):
        self.by_email[payload["email"]] = dict(payload)
        self.by_id[payload["id"]] = dict(payload)
        return dict(payload)

    async def save_session(
        self,
        user_id,
        *,
        access_token,
        refresh_token,
        access_token_expires_at,
        refresh_token_expires_at,
    ):
        document = self.by_id[user_id]
        document["accessToken"] = access_token
        document["refreshToken"] = refresh_token
        document["accessTokenExpiresAt"] = access_token_expires_at.isoformat()
        document["refreshTokenExpiresAt"] = refresh_token_expires_at.isoformat()
        self.by_email[document["email"]] = dict(document)

    async def get_user_document_by_refresh_token(self, token):
        for document in self.by_id.values():
            if document.get("refreshToken") == token:
                return dict(document)
        return None

    async def clear_session(self, user_id):
        document = self.by_id[user_id]
        document["accessToken"] = None
        document["refreshToken"] = None


class AuthServiceTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.repository = _FakeUserRepository()
        self.service = AuthService(self.repository)

    async def test_register_and_refresh_issue_token_pair_and_role(self):
        result = await self.service.register(
            RegisterRequest(
                fullName="Pixel User",
                email="user@example.com",
                password="123456",
            )
        )

        self.assertTrue(result.accessToken)
        self.assertTrue(result.refreshToken)
        self.assertEqual(result.user.role, UserRole.customer)
        self.assertFalse(result.user.isAdmin)
        self.assertEqual(result.user.permissions, [])

        refreshed = await self.service.refresh(
            RefreshTokenRequest(refreshToken=result.refreshToken)
        )

        self.assertNotEqual(refreshed.accessToken, result.accessToken)
        self.assertNotEqual(refreshed.refreshToken, result.refreshToken)
        self.assertEqual(refreshed.user.email, "user@example.com")

    async def test_login_rejects_invalid_credentials(self):
        await self.service.register(
            RegisterRequest(
                fullName="Pixel User",
                email="user@example.com",
                password="123456",
            )
        )

        with self.assertRaises(HTTPException) as context:
            await self.service.login(
                LoginRequest(email="user@example.com", password="wrong-password")
            )

        self.assertEqual(context.exception.status_code, 401)

