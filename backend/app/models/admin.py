from typing import List, Optional

from app.models.common import ApiModel


class AdminStatCardResponse(ApiModel):
    label: str
    value: str
    tone: str


class AdminRecentOrderResponse(ApiModel):
    orderId: str
    total: int
    status: str


class AdminOrderResponse(ApiModel):
    orderId: str
    customerName: str
    customerEmail: str
    total: int
    status: str
    itemCount: int
    paymentMethod: str
    createdAt: str


class AdminOrderStatusUpdateRequest(ApiModel):
    status: str


class AdminOrderIngredientShortageResponse(ApiModel):
    ingredientId: str
    ingredientName: str
    requiredQuantity: int
    availableQuantity: int
    unit: str


class AdminOrderAdvanceCheckResponse(ApiModel):
    orderId: str
    currentStatus: str
    nextStatus: str
    requiresInventoryConfirmation: bool = False
    canAdvance: bool = True
    message: str
    shortages: List[AdminOrderIngredientShortageResponse] = []


class AdminBulkOrderStatusUpdateRequest(ApiModel):
    orderIds: List[str]
    status: str


class AdminProductResponse(ApiModel):
    id: int
    title: str
    category: str
    priceValue: int
    stockStatus: str
    imageUrl: Optional[str] = None


class AdminProductUpdateRequest(ApiModel):
    stockStatus: str


class AdminBulkProductStockUpdateRequest(ApiModel):
    productIds: List[int]
    stockStatus: str


class AdminProductUpsertRequest(ApiModel):
    title: str
    category: str
    priceValue: int
    description: str
    images: List[str]
    sku: str
    stockStatus: str
    weight: str
    storageNote: str
    deliveryNote: str
    detailBullets: List[str]


class AdminProductExcelRow(ApiModel):
    id: Optional[int] = None
    title: str
    category: str
    priceValue: int
    description: str
    images: str
    sku: str
    stockStatus: str
    weight: str
    storageNote: str
    deliveryNote: str
    detailBullets: str


class AdminVoucherExcelRow(ApiModel):
    code: str
    title: str
    note: str
    accent: str
    discountType: str
    discountValue: int
    minOrderValue: int = 0


class AdminIngredientResponse(ApiModel):
    id: str
    name: str
    category: str
    unit: str
    standardUnit: str
    conversionFactor: int
    unitPrice: int
    availableQuantity: int
    availableNormalizedQuantity: int
    lowStockThreshold: int
    lowStockThresholdNormalized: int
    status: str
    lastUpdatedAt: str


class AdminIngredientUpdateRequest(ApiModel):
    quantityDelta: int = 0
    lowStockThreshold: Optional[int] = None
    status: Optional[str] = None


class AdminIngredientUpsertRequest(ApiModel):
    name: str
    category: str
    unit: str
    unitPrice: int
    availableQuantity: int
    lowStockThreshold: int


class AdminIngredientExcelRow(ApiModel):
    id: Optional[str] = None
    name: str
    category: str
    unit: str
    unitPrice: int
    availableQuantity: int
    lowStockThreshold: int


class AdminCustomerExcelRow(ApiModel):
    id: Optional[str] = None
    fullName: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    isAdmin: bool = False


class AdminOrderExcelRow(ApiModel):
    orderId: str
    userId: Optional[str] = None
    customerName: str
    customerEmail: str
    customerPhone: Optional[str] = None
    customerAddress: Optional[str] = None
    paymentMethod: str
    status: str
    itemCount: int
    subtotal: int
    discountAmount: int = 0
    deliveryFee: int = 0
    total: int
    voucherCode: Optional[str] = None
    itemsJson: str = "[]"
    createdAt: Optional[str] = None


class AdminRecipeIngredientInput(ApiModel):
    ingredientId: str
    sourceType: str = "ingredient"
    quantity: int
    wastePercent: int = 0


class AdminRecipeIngredientResponse(ApiModel):
    ingredientId: str
    ingredientName: str
    sourceType: str = "ingredient"
    unit: str
    quantity: int
    normalizedQuantity: int = 0
    wastePercent: int = 0
    unitPrice: int
    lineCost: int


class AdminRecipeResponse(ApiModel):
    id: str
    productId: int
    productTitle: str
    recipeType: str = "finished"
    yieldQuantity: int
    yieldUnit: str
    ingredients: List[AdminRecipeIngredientResponse]
    totalCost: int
    costPerUnit: int
    grossProfitEstimate: int = 0
    grossMarginPercent: float = 0
    createdAt: str


class AdminRecipeCreateRequest(ApiModel):
    productId: int
    recipeType: str = "finished"
    yieldQuantity: int
    yieldUnit: str
    ingredients: List[AdminRecipeIngredientInput]


class AdminRecipeExcelRow(ApiModel):
    id: Optional[str] = None
    productId: int
    recipeType: str = "finished"
    yieldQuantity: int
    yieldUnit: str
    ingredientsJson: str


class AdminRecipeReferenceResponse(ApiModel):
    id: str
    productId: int
    productTitle: str
    recipeType: str
    yieldQuantity: int
    yieldUnit: str
    costPerUnit: int


class AdminRecipeOptionsResponse(ApiModel):
    products: List[AdminProductResponse]
    ingredients: List[AdminIngredientResponse]
    recipeReferences: List[AdminRecipeReferenceResponse]


class AdminRecipeCopyRequest(ApiModel):
    productId: int


class AdminInventoryTransactionResponse(ApiModel):
    id: str
    ingredientId: str
    ingredientName: str
    transactionType: str
    quantityDelta: int
    unit: str
    normalizedQuantityDelta: int
    normalizedUnit: str
    balanceQuantity: int
    balanceNormalizedQuantity: int
    referenceType: Optional[str] = None
    referenceId: Optional[str] = None
    note: Optional[str] = None
    createdAt: str


class AdminProductCostReportResponse(ApiModel):
    productId: int
    productTitle: str
    recipeType: str
    sellingPrice: int
    estimatedCost: int
    grossProfit: int
    grossMarginPercent: float


class AdminProductExcelImportRequest(ApiModel):
    items: List[AdminProductExcelRow]


class AdminIngredientExcelImportRequest(ApiModel):
    items: List[AdminIngredientExcelRow]


class AdminVoucherExcelImportRequest(ApiModel):
    items: List[AdminVoucherExcelRow]


class AdminRecipeExcelImportRequest(ApiModel):
    items: List[AdminRecipeExcelRow]


class AdminCustomerExcelImportRequest(ApiModel):
    items: List[AdminCustomerExcelRow]


class AdminOrderExcelImportRequest(ApiModel):
    items: List[AdminOrderExcelRow]


class AdminImportValidationError(ApiModel):
    rowNumber: int
    field: str
    message: str
    value: Optional[str] = None


class AdminImportAuditLogResponse(ApiModel):
    id: str
    entityType: str
    status: str
    createdCount: int
    updatedCount: int
    errorCount: int
    createdAt: str


class AdminBulkImportResult(ApiModel):
    message: str
    createdCount: int
    updatedCount: int
    errorCount: int = 0
    errors: List[AdminImportValidationError] = []
    auditLogId: Optional[str] = None


class AdminCustomerResponse(ApiModel):
    id: str
    fullName: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    orderCount: int
    isAdmin: bool = False


class AdminCustomerUpdateRequest(ApiModel):
    fullName: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None


class AdminVoucherResponse(ApiModel):
    code: str
    title: str
    note: str
    accent: str
    discountType: str
    discountValue: int
    minOrderValue: int = 0


class AdminVoucherUpsertRequest(ApiModel):
    code: str
    title: str
    note: str
    accent: str
    discountType: str
    discountValue: int
    minOrderValue: int = 0


class AdminTestimonialResponse(ApiModel):
    id: str
    content: str
    author: str
    accent: str
    createdAt: Optional[str] = None
    isVisible: bool = True


class AdminTestimonialUpdateRequest(ApiModel):
    isVisible: bool


class AdminContentDocumentResponse(ApiModel):
    key: str
    title: str
    jsonContent: str


class AdminContentDocumentUpdateRequest(ApiModel):
    jsonContent: str


class AdminAlertResponse(ApiModel):
    title: str
    description: str
    tone: str


class AdminTabSummaryResponse(ApiModel):
    title: str
    rows: List[str]
    buttonLabel: Optional[str] = None
    compact: bool = False


class AdminDashboardResponse(ApiModel):
    title: str
    notificationLabel: str
    statCards: List[AdminStatCardResponse]
    recentOrders: List[AdminRecentOrderResponse]
    alerts: List[AdminAlertResponse]
    salesByHour: List[int]
    topTrendLabel: str
    topTrendValue: str
    tabSummaries: List[AdminTabSummaryResponse]
