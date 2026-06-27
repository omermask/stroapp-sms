import uuid


class AppException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.error_id = str(uuid.uuid4())
        super().__init__(message)


ERROR_CODES = {
    "INSUFFICIENT_BALANCE": "رصيدك غير كافٍ لهذه العملية",
    "INSUFFICIENT_COINS": "رصيد الكوين غير كافٍ",
    "SERVICE_UNAVAILABLE": "الخدمة غير متاحة حالياً",
    "PROVIDER_ERROR": "خطأ في المزود",
    "INVALID_COUNTRY": "الدولة غير مدعومة",
    "UNAUTHORIZED": "يجب تسجيل الدخول أولاً",
    "TOKEN_EXPIRED": "انتهت صلاحية الجلسة",
    "TOKEN_INVALID": "رمز الدخول غير صالح",
    "FORBIDDEN": "ليس لديك صلاحية للوصول",
    "RATE_LIMITED": "طلبات كثيرة جداً، الرجاء المحاولة لاحقاً",
    "USER_NOT_FOUND": "المستخدم غير موجود",
    "VALIDATION_ERROR": "بيانات الإدخال غير صالحة",
    "INTERNAL_ERROR": "خطأ داخلي في الخادم",
    "PROVIDER_DISABLED": "المزود غير مفعل",
    "ALL_PROVIDERS_FAILED": "جميع المزودين فشلوا في معالجة هذا الطلب",
    "DUPLICATE_REQUEST": "تم اكتشاف طلب مكرر",
    "NOT_FOUND": "الموارد المطلوبة غير موجودة",
    "WRONG_PASSWORD": "كلمة المرور الحالية غير صحيحة",
    "EMAIL_EXISTS": "البريد الإلكتروني مستخدم بالفعل",
    "MFA_ALREADY_ENABLED": "التحقق بخطوتين مفعل بالفعل",
    "MFA_NOT_SETUP": "يرجى إعداد التحقق بخطوتين أولاً",
    "MFA_NOT_ENABLED": "التحقق بخطوتين غير مفعل",
    "INVALID_TIER": "الرتبة غير صالحة",
    "TIER_NOT_FOUND": "الرتبة غير موجودة",
    "TEMPLATE_NOT_FOUND": "قالب البريد الإلكتروني غير موجود",
}
