from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def customize_openapi(app: FastAPI) -> str:
    def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema

        openapi_schema = get_openapi(
            title="StroApp SMS API",
            version="1.0.0",
            description="""
# StroApp SMS — API للتحقق عبر الرسائل النصية

## المصادقة
- **JWTBearer**: استخدم `Authorization: Bearer <token>` للـ API
- **API Keys**: استخدم `Authorization: Bearer nsk_<key>` لمطوري التطبيقات
- **Admin Cookie**: للأدمن، JWT في cookie

## التنسيق القياسي
جميع الاستجابات تستخدم التنسيق الموحد:
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": { "request_id": "...", "timestamp": "..." }
}
```

## رسائل الخطأ والنجاح بالعربية
All user-facing messages are in Arabic.
""",
            routes=app.routes,
        )

        openapi_schema["info"]["x-logo"] = {
            "url": "https://stroapp.com/logo.png",
            "altText": "StroApp SMS",
        }

        openapi_schema["tags"] = [
            {"name": "Auth", "description": "تسجيل الدخول والتسجيل"},
            {"name": "SMS Verification", "description": "شراء أرقام للتحقق"},
            {"name": "Voice Verification", "description": "التحقق الصوتي"},
            {"name": "Number Rental", "description": "استئجار أرقام"},
            {"name": "Temporary Email", "description": "الإيميل المؤقت"},
            {"name": "Payments", "description": "الدفع والإيداع"},
            {"name": "User", "description": "إدارة الحساب"},
            {"name": "Admin", "description": "لوحة التحكم"},
            {"name": "Webhooks", "description": "نظام الـ Webhook"},
            {"name": "KYC", "description": "التحقق من الهوية"},
            {"name": "Support", "description": "الدعم الفني"},
            {"name": "Affiliate", "description": "نظام الإحالة"},
            {"name": "Security", "description": "الأمان والامتثال"},
        ]

        schema_definitions = {}
        for path_data in openapi_schema.get("paths", {}).values():
            for method_data in path_data.values():
                if "responses" in method_data:
                    for response in method_data["responses"].values():
                        if "content" in response:
                            for content_type, content_data in response["content"].items():
                                if "schema" in content_data:
                                    ref = content_data["schema"].get("$ref", "")
                                    if ref and ref.startswith("#/components/schemas/"):
                                        schema_name = ref.split("/")[-1]
                                        if "properties" in content_data["schema"]:
                                            schema_definitions[schema_name] = content_data["schema"]

        openapi_schema["components"]["schemas"] = {
            **openapi_schema.get("components", {}).get("schemas", {}),
            **schema_definitions,
        }

        openapi_schema["servers"] = [
            {"url": "https://api.stroapp.com", "description": "Production"},
            {"url": "http://localhost:9527", "description": "Local development"},
        ]

        app.openapi_schema = openapi_schema
        return app.openapi_schema

    app.openapi = custom_openapi
    return app
