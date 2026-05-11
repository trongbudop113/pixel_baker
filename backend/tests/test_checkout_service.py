import unittest

from app.models.auth import UserResponse
from app.models.checkout import CheckoutItemRequest, CheckoutRequest
from app.services.checkout_service import CheckoutService, PAYMENT_COD


class _FakeOrderRepository:
    def __init__(self):
        self.created_orders = []

    async def create_order(self, payload):
        self.created_orders.append(dict(payload))


class _FakeUserRepository:
    def __init__(self):
        self.document = {
            "id": "user-1",
            "fullName": "Pixel User",
            "email": "user@example.com",
            "phone": "0900000000",
            "address": "123 Pixel Street",
            "collectedVoucherCodes": ["PIXEL15"],
            "usedVoucherCodes": [],
            "isAdmin": False,
        }
        self.used_codes = []

    async def get_user_by_id(self, user_id):
        if user_id == self.document["id"]:
            return dict(self.document)
        return None

    async def get_non_admin_user_by_id(self, user_id):
        return await self.get_user_by_id(user_id)

    async def mark_voucher_used(self, user_id, code):
        self.used_codes.append((user_id, code))
        return True


class _FakeVoucherRepository:
    async def get_voucher_by_code(self, code):
        if code != "PIXEL15":
            return None
        return {
            "code": "PIXEL15",
            "discountType": "percent",
            "discountValue": 15,
            "minOrderValue": 50000,
        }


class _FakeAdminRepository:
    def __init__(self):
        self.shortages = []
        self.deduct_calls = []

    async def validate_ingredients_for_order_items(self, items):
        return list(self.shortages)

    async def deduct_ingredients_for_order_items(self, items, *, reference_type, reference_id):
        self.deduct_calls.append(
            {
                "items": list(items),
                "referenceType": reference_type,
                "referenceId": reference_id,
            }
        )


class _FakeCartRepository:
    def __init__(self):
        self.cleared_user_ids = []

    async def clear_cart(self, user_id):
        self.cleared_user_ids.append(user_id)


class CheckoutServiceTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.order_repository = _FakeOrderRepository()
        self.user_repository = _FakeUserRepository()
        self.voucher_repository = _FakeVoucherRepository()
        self.admin_repository = _FakeAdminRepository()
        self.cart_repository = _FakeCartRepository()
        self.service = CheckoutService(
            self.order_repository,
            self.user_repository,
            self.voucher_repository,
            self.admin_repository,
            self.cart_repository,
        )
        self.user = UserResponse(
            id="user-1",
            fullName="Pixel User",
            email="user@example.com",
            phone="0900000000",
            address="123 Pixel Street",
            isAdmin=False,
        )

    async def test_validate_checkout_blocks_when_ingredients_are_short(self):
        self.admin_repository.shortages = [
            {
                "ingredientId": "flour",
                "ingredientName": "Bột mì",
                "requiredQuantity": 500,
                "availableQuantity": 100,
                "unit": "g",
            }
        ]

        validation = await self.service.validate_checkout(
            self.user,
            CheckoutRequest(
                paymentMethod=PAYMENT_COD,
                deliveryFee=15000,
                items=[
                    CheckoutItemRequest(
                        productId=1,
                        title="Bánh dâu",
                        priceValue=60000,
                        quantity=1,
                    )
                ],
            ),
        )

        self.assertFalse(validation.canCheckout)
        self.assertEqual(len(validation.shortages), 1)

    async def test_place_order_marks_voucher_and_deducts_inventory(self):
        response = await self.service.place_order(
            self.user,
            CheckoutRequest(
                paymentMethod=PAYMENT_COD,
                deliveryFee=15000,
                voucherCode="PIXEL15",
                items=[
                    CheckoutItemRequest(
                        productId=1,
                        title="Bánh dâu",
                        priceValue=100000,
                        quantity=1,
                    )
                ],
            ),
        )

        self.assertTrue(response.orderId.startswith("OD-"))
        self.assertEqual(self.user_repository.used_codes, [("user-1", "PIXEL15")])
        self.assertEqual(len(self.admin_repository.deduct_calls), 1)
        self.assertEqual(self.cart_repository.cleared_user_ids, ["user-1"])

