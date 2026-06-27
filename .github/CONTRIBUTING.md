# Contributing to StroApp SMS / المساهمة في StroApp SMS

We welcome contributions from everyone! Here's how you can help.

نرحب بمساهمات الجميع! إليك كيف يمكنك المساعدة.

## 🌍 Languages / اللغات

- **English**: Preferred for code, issues, and PR descriptions
- **Arabic**: Also accepted for issues and comments
- Both languages in the same post is encouraged for wider reach

## 🐛 Reporting Bugs / الإبلاغ عن أخطاء

1. Check if the bug already exists in [Issues](https://github.com/omermask/stroapp-sms/issues)
2. Use the **Bug Report** template when creating a new issue
3. Include as much detail as possible (environment, steps, screenshots)

## 💡 Suggesting Features / اقتراح ميزات

1. Check if the feature already exists or was suggested in [Issues](https://github.com/omermask/stroapp-sms/issues)
2. Use the **Feature Request** template
3. Explain why this feature would be useful

## 🛠️ Pull Requests / طلبات الدمج

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature` or `fix/your-fix`
3. Make your changes
4. Run tests:
   - Backend: `pytest tests/ -v`
   - Flutter: `flutter test`
5. Commit with clear messages
6. Push and open a PR against `main`

## 📝 Code Style / أسلوب الكود

### Backend (Python)
- Follow PEP 8
- Use type hints
- Use existing patterns (FastAPI, SQLAlchemy)

### Flutter (Dart)
- Follow Dart conventions
- Use Riverpod for state management
- Use freezed for immutable models

## 🔒 Security / الأمان

If you find a security vulnerability, please **do not** open a public issue.
Report it privately via [Security Advisories](https://github.com/omermask/stroapp-sms/security/advisories/new).

## 📄 License / الترخيص

By contributing, you agree that your contributions will be licensed under the project's license.

## 🎯 Tags Guide / دليل الوسوم

| Label / الوسم | Meaning / المعنى |
|---------------|------------------|
| `bug` | Something isn't working / شيء لا يعمل |
| `enhancement` | New feature or request / ميزة جديدة |
| `documentation` | Documentation improvements / تحسين التوثيق |
| `good first issue` | Good for newcomers / مناسبة للمبتدئين |
| `help wanted` | Extra attention needed / تحتاج مساعدة |
| `question` | Further information is needed / تحتاج استفسار |
| `backend` | Related to the Python API / متعلق بالخادم |
| `user-app` | Related to the Flutter user app / متعلق بتطبيق المستخدم |
| `admin-app` | Related to the Flutter admin app / متعلق بلوحة الإدارة |
| `security` | Security-related / متعلق بالأمان |
| `performance` | Performance issues / مشاكل أداء |
| `i18n` | Translation / localization / ترجمة |
