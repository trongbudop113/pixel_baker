from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from app.models.admin import AdminDashboardResponse
from app.models.admin import (
    AdminBulkOrderStatusUpdateRequest,
    AdminBulkProductStockUpdateRequest,
    AdminBulkImportResult,
    AdminContentDocumentResponse,
    AdminContentDocumentUpdateRequest,
    AdminCustomerResponse,
    AdminCustomerExcelImportRequest,
    AdminCustomerExcelRow,
    AdminCustomerUpdateRequest,
    AdminIngredientExcelImportRequest,
    AdminIngredientExcelRow,
    AdminIngredientResponse,
    AdminImportAuditLogResponse,
    AdminInventoryTransactionResponse,
    AdminIngredientUpsertRequest,
    AdminIngredientUpdateRequest,
    AdminOrderExcelImportRequest,
    AdminOrderExcelRow,
    AdminOrderAdvanceCheckResponse,
    AdminProductCostReportResponse,
    AdminRevenueSummaryResponse,
    AdminRecipeExcelImportRequest,
    AdminRecipeExcelRow,
    AdminRecipeCopyRequest,
    AdminRecipeCreateRequest,
    AdminRecipeOptionsResponse,
    AdminRecipeReferenceResponse,
    AdminRecipeResponse,
    AdminOrderResponse,
    AdminProductExcelImportRequest,
    AdminProductExcelRow,
    AdminOrderStatusUpdateRequest,
    AdminProductResponse,
    AdminProductUpsertRequest,
    AdminProductUpdateRequest,
    AdminTestimonialResponse,
    AdminTestimonialUpdateRequest,
    AdminVoucherExcelImportRequest,
    AdminVoucherExcelRow,
    AdminVoucherResponse,
    AdminVoucherUpsertRequest,
)
from app.models.common import ApiModel
from app.models.menu import MenuProductDetailResponse
from app.models.auth import UserResponse
from app.repositories.admin_repository import AdminRepository, get_admin_repository
from app.repositories.user_repository import UserRepository, get_user_repository

router = APIRouter()


class AdminActionResponse(ApiModel):
    message: str


async def _require_admin_user(
    authorization: Optional[str] = Header(default=None),
    repository: UserRepository = Depends(get_user_repository),
) -> UserResponse:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Vui lòng đăng nhập để truy cập trang quản trị.",
        )

    token = authorization.removeprefix("Bearer ").strip()
    user = await repository.get_user_by_access_token(token)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Phiên đăng nhập không hợp lệ.",
        )
    permissions = set(user.permissions)
    if "*" not in permissions and "admin:access" not in permissions and user.isAdmin is not True:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập trang quản trị.",
        )
    return user


def _has_any_permission(user: UserResponse, required_permissions: tuple[str, ...]) -> bool:
    permissions = set(user.permissions)
    if "*" in permissions or user.isAdmin is True:
        return True
    return any(permission in permissions for permission in required_permissions)


def require_admin_permission(*required_permissions: str):
    async def dependency(
        user: UserResponse = Depends(_require_admin_user),
    ) -> UserResponse:
        if not _has_any_permission(user, tuple(required_permissions)):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền thực hiện thao tác này.",
            )
        return user

    return dependency


@router.get("/dashboard", response_model=AdminDashboardResponse)
async def get_admin_dashboard(
    _: UserResponse = Depends(require_admin_permission("admin:access", "reports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminDashboardResponse:
    return await repository.get_dashboard()


@router.get("/orders", response_model=list[AdminOrderResponse])
async def list_admin_orders(
    _: UserResponse = Depends(require_admin_permission("orders:view", "orders:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminOrderResponse]:
    return await repository.list_orders()


@router.patch("/orders/{order_id}", response_model=AdminOrderResponse)
async def update_admin_order_status(
    order_id: str,
    payload: AdminOrderStatusUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("orders:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminOrderResponse:
    order = await repository.update_order_status(order_id, payload)
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy đơn hàng.",
    )
    return order


@router.get("/orders/{order_id}/advance-check", response_model=AdminOrderAdvanceCheckResponse)
async def get_admin_order_advance_check(
    order_id: str,
    _: UserResponse = Depends(require_admin_permission("orders:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminOrderAdvanceCheckResponse:
    result = await repository.get_order_advance_check(order_id)
    if result is None:
      raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy đơn hàng.",
        )
    return result


@router.post("/orders/bulk-status", response_model=AdminActionResponse)
async def bulk_update_admin_order_status(
    payload: AdminBulkOrderStatusUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("orders:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    modified = await repository.bulk_update_order_status(payload.orderIds, payload.status)
    return AdminActionResponse(message=f"Đã cập nhật {modified} đơn hàng.")


@router.get("/orders/excel-rows", response_model=list[AdminOrderExcelRow])
async def list_admin_order_excel_rows(
    _: UserResponse = Depends(require_admin_permission("orders:view", "orders:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminOrderExcelRow]:
    return await repository.list_order_excel_rows()


@router.post("/orders/excel-import", response_model=AdminBulkImportResult)
async def import_admin_orders_from_excel(
    payload: AdminOrderExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("orders:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    return await repository.import_orders_from_excel(payload.items)


@router.get("/products", response_model=list[AdminProductResponse])
async def list_admin_products(
    _: UserResponse = Depends(require_admin_permission("products:view", "products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminProductResponse]:
    return await repository.list_products()


@router.get("/products/excel-rows", response_model=list[AdminProductExcelRow])
async def list_admin_product_excel_rows(
    _: UserResponse = Depends(require_admin_permission("products:view", "products:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminProductExcelRow]:
    return await repository.list_product_excel_rows()


@router.post("/products/excel-import", response_model=AdminBulkImportResult)
async def import_admin_products_from_excel(
    payload: AdminProductExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    try:
        return await repository.import_products_from_excel(payload.items)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error


@router.patch("/products/{product_id}", response_model=AdminProductResponse)
async def update_admin_product(
    product_id: int,
    payload: AdminProductUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminProductResponse:
    product = await repository.update_product(product_id, payload)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy sản phẩm.",
    )
    return product


@router.post("/products/bulk-stock", response_model=AdminActionResponse)
async def bulk_update_admin_product_stock(
    payload: AdminBulkProductStockUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    modified = await repository.bulk_update_product_stock(payload.productIds, payload.stockStatus)
    return AdminActionResponse(message=f"Đã cập nhật {modified} sản phẩm.")


@router.get("/products/{product_id}", response_model=MenuProductDetailResponse)
async def get_admin_product(
    product_id: int,
    _: UserResponse = Depends(require_admin_permission("products:view", "products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> MenuProductDetailResponse:
    product = await repository.get_product(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy sản phẩm.",
        )
    product["relatedProducts"] = []
    return MenuProductDetailResponse.model_validate(product)


@router.post("/products", response_model=MenuProductDetailResponse)
async def create_admin_product(
    payload: AdminProductUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> MenuProductDetailResponse:
    product = await repository.create_product(payload)
    product["relatedProducts"] = []
    return MenuProductDetailResponse.model_validate(product)


@router.put("/products/{product_id}", response_model=MenuProductDetailResponse)
async def replace_admin_product(
    product_id: int,
    payload: AdminProductUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> MenuProductDetailResponse:
    product = await repository.replace_product(product_id, payload)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy sản phẩm.",
        )
    product["relatedProducts"] = []
    return MenuProductDetailResponse.model_validate(product)


@router.delete("/products/{product_id}", response_model=AdminActionResponse)
async def delete_admin_product(
    product_id: int,
    _: UserResponse = Depends(require_admin_permission("products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    deleted = await repository.delete_product(product_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy sản phẩm.",
        )
    return AdminActionResponse(message="Xóa sản phẩm thành công.")


@router.get("/customers", response_model=list[AdminCustomerResponse])
async def list_admin_customers(
    _: UserResponse = Depends(require_admin_permission("customers:view", "customers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminCustomerResponse]:
    return await repository.list_customers()


@router.get("/customers/excel-rows", response_model=list[AdminCustomerExcelRow])
async def list_admin_customer_excel_rows(
    _: UserResponse = Depends(require_admin_permission("customers:view", "customers:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminCustomerExcelRow]:
    return await repository.list_customer_excel_rows()


@router.post("/customers/excel-import", response_model=AdminBulkImportResult)
async def import_admin_customers_from_excel(
    payload: AdminCustomerExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("customers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    return await repository.import_customers_from_excel(payload.items)


@router.get("/customers/{customer_id}", response_model=AdminCustomerResponse)
async def get_admin_customer(
    customer_id: str,
    _: UserResponse = Depends(require_admin_permission("customers:view", "customers:manage")),
    admin_repository: AdminRepository = Depends(get_admin_repository),
) -> AdminCustomerResponse:
    customers = await admin_repository.list_customers()
    for customer in customers:
        if customer.id == customer_id and not customer.isAdmin:
            return customer
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Không tìm thấy khách hàng.",
    )


@router.put("/customers/{customer_id}", response_model=AdminCustomerResponse)
async def update_admin_customer(
    customer_id: str,
    payload: AdminCustomerUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("customers:manage")),
    user_repository: UserRepository = Depends(get_user_repository),
    admin_repository: AdminRepository = Depends(get_admin_repository),
) -> AdminCustomerResponse:
    existing = await user_repository.get_user_by_email(payload.email)
    if existing is not None and str(existing.get("id") or "") != customer_id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email đã được sử dụng bởi tài khoản khác.",
        )

    user = await user_repository.update_customer_by_admin(
        customer_id,
        full_name=payload.fullName,
        email=payload.email,
        phone=payload.phone,
        address=payload.address,
    )
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy khách hàng.",
        )

    customers = await admin_repository.list_customers()
    for customer in customers:
        if customer.id == customer_id:
            return customer
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Không tìm thấy khách hàng.",
    )


@router.get("/ingredients", response_model=list[AdminIngredientResponse])
async def list_admin_ingredients(
    _: UserResponse = Depends(require_admin_permission("inventory:view", "inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminIngredientResponse]:
    return await repository.list_ingredients()


@router.get("/import-audit-logs", response_model=list[AdminImportAuditLogResponse])
async def list_admin_import_audit_logs(
    _: UserResponse = Depends(require_admin_permission("imports:view", "admin:access")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminImportAuditLogResponse]:
    return await repository.list_import_audit_logs()


@router.get("/inventory-transactions", response_model=list[AdminInventoryTransactionResponse])
async def list_admin_inventory_transactions(
    _: UserResponse = Depends(require_admin_permission("inventory:view", "inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminInventoryTransactionResponse]:
    return await repository.list_inventory_transactions()


@router.get("/product-cost-reports", response_model=list[AdminProductCostReportResponse])
async def list_admin_product_cost_reports(
    _: UserResponse = Depends(require_admin_permission("reports:view", "products:view", "products:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminProductCostReportResponse]:
    return await repository.list_product_cost_reports()


@router.get("/revenue-summary", response_model=AdminRevenueSummaryResponse)
async def get_admin_revenue_summary(
    range: str = "7d",
    _: UserResponse = Depends(require_admin_permission("reports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRevenueSummaryResponse:
    valid_ranges = {"today", "yesterday", "7d", "30d", "this_month", "last_month"}
    if range not in valid_ranges:
        range = "7d"
    return await repository.get_revenue_summary(range)


@router.get("/ingredients/excel-rows", response_model=list[AdminIngredientExcelRow])
async def list_admin_ingredient_excel_rows(
    _: UserResponse = Depends(require_admin_permission("inventory:view", "inventory:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminIngredientExcelRow]:
    return await repository.list_ingredient_excel_rows()


@router.post("/ingredients/excel-import", response_model=AdminBulkImportResult)
async def import_admin_ingredients_from_excel(
    payload: AdminIngredientExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    try:
        return await repository.import_ingredients_from_excel(payload.items)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error


@router.get("/ingredients/{ingredient_id}", response_model=AdminIngredientResponse)
async def get_admin_ingredient(
    ingredient_id: str,
    _: UserResponse = Depends(require_admin_permission("inventory:view", "inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminIngredientResponse:
    ingredient = await repository.get_ingredient(ingredient_id)
    if ingredient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy nguyên liệu.",
        )
    return ingredient


@router.post("/ingredients", response_model=AdminIngredientResponse)
async def create_admin_ingredient(
    payload: AdminIngredientUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminIngredientResponse:
    try:
        return await repository.create_ingredient(payload)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error


@router.put("/ingredients/{ingredient_id}", response_model=AdminIngredientResponse)
async def replace_admin_ingredient(
    ingredient_id: str,
    payload: AdminIngredientUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminIngredientResponse:
    ingredient = await repository.replace_ingredient(ingredient_id, payload)
    if ingredient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy nguyên liệu.",
        )
    return ingredient


@router.patch("/ingredients/{ingredient_id}", response_model=AdminIngredientResponse)
async def update_admin_ingredient(
    ingredient_id: str,
    payload: AdminIngredientUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminIngredientResponse:
    ingredient = await repository.update_ingredient(ingredient_id, payload)
    if ingredient is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy nguyên liệu.",
        )
    return ingredient


@router.delete("/ingredients/{ingredient_id}", response_model=AdminActionResponse)
async def delete_admin_ingredient(
    ingredient_id: str,
    _: UserResponse = Depends(require_admin_permission("inventory:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    deleted = await repository.delete_ingredient(ingredient_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy nguyên liệu.",
        )
    return AdminActionResponse(message="Xóa nguyên liệu thành công.")


@router.get("/vouchers", response_model=list[AdminVoucherResponse])
async def list_admin_vouchers(
    _: UserResponse = Depends(require_admin_permission("vouchers:view", "vouchers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminVoucherResponse]:
    return await repository.list_vouchers()


@router.get("/vouchers/excel-rows", response_model=list[AdminVoucherExcelRow])
async def list_admin_voucher_excel_rows(
    _: UserResponse = Depends(require_admin_permission("vouchers:view", "vouchers:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminVoucherExcelRow]:
    return await repository.list_voucher_excel_rows()


@router.post("/vouchers/excel-import", response_model=AdminBulkImportResult)
async def import_admin_vouchers_from_excel(
    payload: AdminVoucherExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("vouchers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    return await repository.import_vouchers_from_excel(payload.items)


@router.post("/vouchers", response_model=AdminVoucherResponse)
async def create_admin_voucher(
    payload: AdminVoucherUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("vouchers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminVoucherResponse:
    try:
        return await repository.create_voucher(payload.model_dump())
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(error)) from error


@router.put("/vouchers/{code}", response_model=AdminVoucherResponse)
async def update_admin_voucher(
    code: str,
    payload: AdminVoucherUpsertRequest,
    _: UserResponse = Depends(require_admin_permission("vouchers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminVoucherResponse:
    voucher = await repository.update_voucher(code, payload.model_dump())
    if voucher is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy voucher.")
    return voucher


@router.delete("/vouchers/{code}", response_model=AdminActionResponse)
async def delete_admin_voucher(
    code: str,
    _: UserResponse = Depends(require_admin_permission("vouchers:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    deleted = await repository.delete_voucher(code)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy voucher.")
    return AdminActionResponse(message="Xóa voucher thành công.")


@router.get("/testimonials", response_model=list[AdminTestimonialResponse])
async def list_admin_testimonials(
    _: UserResponse = Depends(require_admin_permission("testimonials:view", "testimonials:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminTestimonialResponse]:
    return await repository.list_testimonials()


@router.patch("/testimonials/{testimonial_id}", response_model=AdminTestimonialResponse)
async def update_admin_testimonial(
    testimonial_id: str,
    payload: AdminTestimonialUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("testimonials:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminTestimonialResponse:
    testimonial = await repository.update_testimonial_visibility(
        testimonial_id,
        payload.isVisible,
    )
    if testimonial is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy đánh giá.")
    return testimonial


@router.delete("/testimonials/{testimonial_id}", response_model=AdminActionResponse)
async def delete_admin_testimonial(
    testimonial_id: str,
    _: UserResponse = Depends(require_admin_permission("testimonials:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    deleted = await repository.delete_testimonial(testimonial_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Không tìm thấy đánh giá.")
    return AdminActionResponse(message="Xóa đánh giá thành công.")


@router.get("/contents", response_model=list[AdminContentDocumentResponse])
async def list_admin_contents(
    _: UserResponse = Depends(require_admin_permission("content:view", "content:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminContentDocumentResponse]:
    try:
        return await repository.list_content_documents()
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(error)) from error


@router.get("/contents/{key}", response_model=AdminContentDocumentResponse)
async def get_admin_content(
    key: str,
    _: UserResponse = Depends(require_admin_permission("content:view", "content:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminContentDocumentResponse:
    try:
        return await repository.get_content_document(key)
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(error)) from error


@router.put("/contents/{key}", response_model=AdminContentDocumentResponse)
async def update_admin_content(
    key: str,
    payload: AdminContentDocumentUpdateRequest,
    _: UserResponse = Depends(require_admin_permission("content:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminContentDocumentResponse:
    try:
        return await repository.update_content_document(key, payload.jsonContent)
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(error)) from error


@router.get("/recipes", response_model=list[AdminRecipeResponse])
async def list_admin_recipes(
    _: UserResponse = Depends(require_admin_permission("recipes:view", "recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminRecipeResponse]:
    return await repository.list_recipes()


@router.get("/recipes/excel-rows", response_model=list[AdminRecipeExcelRow])
async def list_admin_recipe_excel_rows(
    _: UserResponse = Depends(require_admin_permission("recipes:view", "recipes:manage", "imports:view")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> list[AdminRecipeExcelRow]:
    return await repository.list_recipe_excel_rows()


@router.post("/recipes/excel-import", response_model=AdminBulkImportResult)
async def import_admin_recipes_from_excel(
    payload: AdminRecipeExcelImportRequest,
    _: UserResponse = Depends(require_admin_permission("recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminBulkImportResult:
    return await repository.import_recipes_from_excel(payload.items)


@router.get("/recipes/options", response_model=AdminRecipeOptionsResponse)
async def get_admin_recipe_options(
    recipe_id: Optional[str] = None,
    _: UserResponse = Depends(require_admin_permission("recipes:view", "recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRecipeOptionsResponse:
    return await repository.get_recipe_options_for_edit(recipe_id)


@router.get("/recipes/{recipe_id}", response_model=AdminRecipeResponse)
async def get_admin_recipe(
    recipe_id: str,
    _: UserResponse = Depends(require_admin_permission("recipes:view", "recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRecipeResponse:
    recipe = await repository.get_recipe(recipe_id)
    if recipe is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy công thức.",
        )
    return recipe


@router.post("/recipes", response_model=AdminRecipeResponse)
async def create_admin_recipe(
    payload: AdminRecipeCreateRequest,
    _: UserResponse = Depends(require_admin_permission("recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRecipeResponse:
    try:
        return await repository.create_recipe(payload)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error


@router.put("/recipes/{recipe_id}", response_model=AdminRecipeResponse)
async def update_admin_recipe(
    recipe_id: str,
    payload: AdminRecipeCreateRequest,
    _: UserResponse = Depends(require_admin_permission("recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRecipeResponse:
    try:
        recipe = await repository.update_recipe(recipe_id, payload)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error
    if recipe is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy công thức.",
        )
    return recipe


@router.post("/recipes/{recipe_id}/copy", response_model=AdminRecipeResponse)
async def copy_admin_recipe(
    recipe_id: str,
    payload: AdminRecipeCopyRequest,
    _: UserResponse = Depends(require_admin_permission("recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminRecipeResponse:
    try:
        return await repository.copy_recipe(recipe_id, payload)
    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(error),
        ) from error


@router.delete("/recipes/{recipe_id}", response_model=AdminActionResponse)
async def delete_admin_recipe(
    recipe_id: str,
    _: UserResponse = Depends(require_admin_permission("recipes:manage")),
    repository: AdminRepository = Depends(get_admin_repository),
) -> AdminActionResponse:
    deleted = await repository.delete_recipe(recipe_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy công thức.",
        )
    return AdminActionResponse(message="Xóa công thức thành công.")
