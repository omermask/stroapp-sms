# Security Policy / سياسة الأمان

## Reporting a Vulnerability / الإبلاغ عن ثغرة أمنية

We take security seriously. If you discover a security vulnerability, please **do not** open a public issue.

نحن نأخذ الأمان على محمل الجد. إذا اكتشفت ثغرة أمنية، من فضلك **لا تنشئ Issue عام**.

### How to Report / كيفية الإبلاغ

1. **Privately**: Go to [Security Advisories](https://github.com/omermask/stroapp-sms/security/advisories/new)
2. **Email**: (coming soon)
3. **Telegram**: (coming soon)

### What to Include / ماذا تتضمن

- Type of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Time / وقت الاستجابة

We will acknowledge receipt within 48 hours and provide a timeline for the fix within 5 business days.

سنؤكد الاستلام خلال 48 ساعة ونقدم جدول زمني للإصلاح خلال 5 أيام عمل.

## Scope / النطاق

The following are in scope:
- Backend API (`/stroapp/` endpoints)
- Authentication and authorization
- Data privacy and access control
- Payment processing
- User data exposure

## Out of Scope / خارج النطاق

- Theoretical vulnerabilities without proof of concept
- Rate limiting bypass (we track this separately)
- SSL/TLS configuration (handled by infrastructure)
- Dependency CVEs without exploit context
