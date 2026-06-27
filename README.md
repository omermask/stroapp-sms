# StroApp SMS — Virtual Phone Number Platform

> A production-grade SMS verification platform that aggregates multiple SMS provider APIs, providing virtual phone numbers for receiving SMS verification codes — with a full-featured admin dashboard and a polished user mobile application.

---

## 📋 Overview

StroApp SMS is a **SMS-PaaS (SMS Platform as a Service)** that solves the problem of needing a real phone number to receive SMS verification codes. Users purchase virtual numbers to receive OTP/activation codes for services like WhatsApp, Telegram, Google, Facebook, TikTok, and hundreds more — without exposing their personal phone number.

The platform aggregates supply from multiple SMS provider APIs, applies a configurable markup engine for profitability, and delivers a unified experience through:

- **📱 User Mobile App** (Flutter) — Browse services, purchase numbers, receive SMS, manage account
- **🛠️ Admin Dashboard** (Flutter) — Manage users, orders, finances, security, and platform configuration
- **⚙️ Backend API** (Python/FastAPI) — RESTful API powering both frontends with enterprise-grade security

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   User App      │     │   Admin App     │     │  3rd-Party      │
│  (Flutter)      │     │  (Flutter)      │     │  Integrations   │
│  port 3000      │     │  port 3001      │     │  (OAuth, IAP,   │
└────────┬────────┘     └────────┬────────┘     │  Payments...)   │
         │                       │              └────────┬────────┘
         └───────────┬───────────┘                       │
                     │ HTTP/JSON                         │
                     ▼                                   │
            ┌────────────────┐                            │
            │   FastAPI App  │◄───────────────────────────┘
            │   Port 9527    │
            │  + Gunicorn    │
            └───────┬────────┘
                    │
         ┌──────────┼──────────┐
         ▼          ▼          ▼
   ┌─────────┐ ┌─────────┐ ┌─────────┐
   │PostgreSQL│ │  Redis  │ │ SMS     │
   │ Database │ │  Cache  │ │Providers│
   │ :5433    │ │ :6379   │ │(4 APIs) │
   └─────────┘ └─────────┘ └─────────┘
```

### Data Flow

1. **User** opens the mobile app, browses available services and countries
2. **Backend** queries provider APIs for real-time pricing and stock
3. **Price Engine** applies markup rules, user-specific pricing, and coins conversion
4. **User** purchases a number → coins deducted → provider API called → number allocated
5. **Polling Service** monitors the number for incoming SMS messages
6. **Delivery** — SMS code is delivered to the user via app UI, webhook, email forwarding, or Telegram bot
7. **Optional** — Order auto-cancels after timeout with refund

---

## ✨ Features

### 🔹 Backend API (FastAPI)

**User Features**
- Email/password authentication with JWT (access + refresh tokens)
- Google Sign-In and Apple Sign-In OAuth integration
- Multi-factor authentication (TOTP)
- Virtual number purchase for SMS verification (temporary & rental)
- Real-time SMS message polling with auto-refresh
- Number cancellation with partial refund
- Wallet system with coin-based transactions
- In-app purchase payments (Google Play, Apple App Store, Stripe)
- Webhook management for SMS delivery callbacks
- Email forwarding and Telegram bot integration
- Multi-tier subscription plans (Freemium, PAYG, Pro, Custom)
- Temporary email inbox service
- Voice call verification (call & speak code)
- Referral and affiliate programs
- Reseller and white-label support
- KYC verification and compliance
- GDPR data export and account deletion

**Admin Features**
- Admin authentication and session management
- User management (CRUD, ban, coin adjustment, tier change)
- Order and transaction monitoring
- Provider management (enable/disable, balance check)
- Service management (activate/deactivate)
- Dynamic pricing engine with markup rules
- Pricing templates and user-specific pricing
- Support ticket system
- Dispute resolution
- KYC document verification
- Revenue and P&L reporting
- Financial reconciliation
- Provider settlement tracking
- Affiliate commission management
- Reseller account management
- Broadcast push notifications
- Security scanning and compliance reporting
- Automated database backup and disaster recovery
- Audit logging (enterprise-grade)
- Feature flag management
- Email template customization
- Data export (users, transactions, payments, audit logs)
- Security scans, secrets check, compliance reports
- Multi-language support (7 languages)

**Security & Compliance**
- Rate limiting (Redis token bucket)
- CSRF protection
- XSS prevention
- SQL injection prevention (ORM-based)
- Proxy/VPN detection middleware
- Device fingerprinting
- IP blacklisting
- PII masking in logs
- Structured JSON logging
- Sentry error tracking
- Prometheus metrics
- Security headers (HSTS, CSP, X-Frame-Options, etc.)

### 🔹 User Mobile App (Flutter)

- Browse 100+ services organized by category
- View prices across 200+ countries
- Purchase numbers with one tap (from presets)
- Real-time SMS waiting screen with countdown timer
- Order history with full details
- Wallet with top-up via Google Pay / Apple Pay
- Number rental with duration and auto-extend
- Temporary email inbox
- Voice verification purchase
- Saved presets for quick re-purchase
- Webhook and forwarding configuration
- MFA setup and management
- API key management
- Active sessions management
- Affiliate dashboard with commissions and payouts
- KYC document submission and status tracking
- Support ticket system
- Multi-language (Arabic/English) with RTL support
- Dark/Light theme
- Biometric authentication (fingerprint, face ID)
- Deep linking (referral codes)
- Push notifications via Firebase Cloud Messaging
- Onboarding wizard for new users

### 🔹 Admin Dashboard (Flutter)

- Dashboard with KPI cards and charts (new users, orders, revenue)
- User management with search, filters, and bulk actions
- Order and transaction browsing with detail views
- Support ticket management with reply thread
- System settings (coins per USD, markup, email limits)
- Provider and service management
- Pricing engine with templates, promotions, and markup rules
- Affiliate applications, commissions, and payouts
- Reseller accounts and credit allocation
- Financial reports (revenue, costs, settlements, tax)
- P&L reports
- Analytics dashboard with verification stats and carrier analytics
- Ledger and reconciliation tools
- Security screen: vulnerability scans, secrets check, compliance
- Backup management: create, list, restore
- Disaster recovery: run tests, monitor status
- Webhook queue and retry monitoring
- Broadcast push notifications
- Blacklist management (IP, tokens)
- Whitelabel domain management
- Data sync orchestrator with markup rules
- Data export (CSV) for users, transactions, payments, audit logs
- Telegram bot connection management
- Feature flag toggling
- Session management with force logout
- Email template editing
- Waitlist management
- Multi-language support (7 languages)

---

## 🛠️ Tech Stack

### Backend
| Technology | Purpose |
|------------|---------|
| **Python 3.12+** | Runtime |
| **FastAPI** | Web framework (async) |
| **Uvicorn + Gunicorn** | ASGI server (dev + prod) |
| **SQLAlchemy 2.0** | ORM with async support |
| **PostgreSQL 16** | Primary database |
| **Redis 7** | Caching, rate limiting, queues |
| **Alembic** | Database migrations |
| **Pydantic v2** | Data validation & settings |
| **PyJWT** | JWT authentication |
| **Passlib (bcrypt)** | Password hashing |
| **Sentry** | Error monitoring |
| **Prometheus** | Metrics & observability |
| **Docker** | Containerization |
| **NGINX** | Reverse proxy + WAF |

### SMS Providers (Integrated)
| Provider | Region | Specialty |
|----------|--------|-----------|
| **SMS-Man** (smsman) | Russia/CIS | Wide country coverage |
| **5sim** (fivesim) | International | Large inventory |
| **SMS-Activate** (smsactivate) | Russia/CIS | Competitive pricing |
| **SMSPool** (smspool) | USA/Global | US numbers focus |

### Mobile Apps
| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Riverpod** | State management |
| **GoRouter** | Declarative routing |
| **Dio** | HTTP client with interceptors |
| **Freezed** | Immutable data models |
| **Google Sign-In** | OAuth authentication |
| **Apple Sign-In** | OAuth authentication |
| **Firebase Messaging** | Push notifications |
| **fl_chart** | Charts (admin app) |

---

## 📁 Project Structure

```
stroapp-sms/                          # Monorepo root
├── app/                              # Python backend package
│   ├── api/
│   │   ├── v1/                       # Version 1 API (60+ route files)
│   │   │   ├── auth.py               # Authentication endpoints
│   │   │   ├── purchase.py           # SMS purchase & orders
│   │   │   ├── services.py           # Service listing
│   │   │   ├── user.py               # User profile & balance
│   │   │   ├── payments.py           # Payment processing
│   │   │   ├── webhooks.py           # Webhook management
│   │   │   ├── admin_*.py            # 14 admin sub-modules
│   │   │   └── ...                   # 40+ more endpoint files
│   │   └── v4/                       # Version 4 API (clean admin)
│   │       └── admin.py              # Unified admin API
│   ├── core/                         # Framework & shared utilities
│   │   ├── config.py                 # Pydantic Settings
│   │   ├── database.py               # SQLAlchemy setup
│   │   ├── security.py               # JWT, hashing
│   │   ├── dependencies.py           # FastAPI dependencies
│   │   └── middleware.py             # Custom ASGI middleware
│   ├── domain/
│   │   ├── models.py                 # 60+ SQLAlchemy models
│   │   └── coins.py                  # Coin conversion logic
│   ├── infrastructure/
│   │   ├── providers/                # SMS provider adapters
│   │   │   ├── base.py               # Abstract provider
│   │   │   ├── router.py             # Provider router (fallback)
│   │   │   ├── smsman.py             # SMS-Man integration
│   │   │   ├── fivesim.py            # 5sim integration
│   │   │   ├── smsactivate.py        # SMS-Activate integration
│   │   │   ├── smspool.py            # SMSPool integration
│   │   │   └── circuit_breaker.py    # Fault tolerance
│   │   ├── payments/                 # Payment integrations
│   │   ├── cache/                    # Redis caching
│   │   ├── queue/                    # Webhook queue (Redis streams)
│   │   ├── push/                     # OneSignal push
│   │   ├── bot/                      # Telegram bot
│   │   └── security/                 # Secrets & compliance
│   ├── middleware/                    # HTTP middleware
│   ├── schemas/                      # Pydantic schemas
│   ├── services/                     # Business logic (40+ files)
│   │   ├── purchase_service.py       # SMS purchase flow
│   │   ├── price_calculator.py       # Pricing engine
│   │   ├── pricing_engine_service.py # User-specific pricing
│   │   ├── payment_service.py        # Payment processing
│   │   ├── audit_service.py          # Enterprise audit
│   │   ├── backup_service.py         # DB backup/restore
│   │   ├── security_scanner.py       # Security scanning
│   │   ├── background.py             # Background workers
│   │   └── ...                       # 30+ more services
│   └── websocket/                    # WebSocket manager
├── infrastructure/
│   └── db/
│       └── migrations/               # Alembic migrations
├── scripts/                          # Utility scripts
│   ├── seed_admin.py                 # Create admin user
│   ├── backup.sh                     # Database backup
│   └── run_security_audit.sh         # Security audit
├── main.py                           # Application entry point
├── Dockerfile                        # Docker build
├── docker-compose.yml                # Full stack setup
├── nginx.conf                        # Production proxy config
├── requirements.txt                  # Python dependencies
├── .env.example                      # Example environment
│
├── stroapp-sms-user/                 # User Flutter app
│   └── lib/
│       ├── main.dart                 # App entry point
│       ├── core/                     # API, models, router, theme
│       └── features/                 # Feature modules
│           ├── sms_purchase/         # SMS buying flow
│           ├── auth/                 # Authentication
│           ├── home/                 # Dashboard
│           ├── wallet/               # Wallet & payments
│           ├── settings/             # Settings hub
│           ├── presets/              # Saved presets
│           ├── temp_email/           # Temp email inbox
│           ├── voice/                # Voice verification
│           ├── rentals/              # Number rental
│           └── ...                   # 10+ more features
│
└── stroapp-sms-admin/                # Admin Flutter app
    └── lib/
        ├── main.dart                 # App entry point
        ├── app/                      # Screens & tabs
        │   ├── screens/              # 21 screen files
        │   └── tabs/                 # 5 bottom nav tabs
        └── core/                     # API, models, services, theme
            ├── api_constants.dart    # 184 API endpoint definitions
            ├── services/             # 5 service classes
            ├── models/               # Data models
            └── widgets/              # 12 reusable widgets
```

---

## 🚀 Getting Started

### Prerequisites

- Python 3.12+
- PostgreSQL 16
- Redis 7
- Flutter 3.x (for mobile apps)
- Docker (optional, for containerized deployment)

### 1. Clone & Setup Backend

```bash
git clone <repo-url> stroapp-sms
cd stroapp-sms

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or .venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings (database URL, API keys, secrets)
```

### 2. Database Setup

```bash
# Using Docker (recommended for development)
docker run -d \
  --name stroapp-db \
  -e POSTGRES_USER=stroapp \
  -e POSTGRES_PASSWORD=stroapp_pass \
  -e POSTGRES_DB=stroapp \
  -p 5433:5432 \
  postgres:16

# Run migrations
alembic upgrade head

# Seed admin user
python scripts/seed_admin.py admin@example.com your-password
```

### 3. Run Backend

```bash
# Development
python main.py

# Production (with Gunicorn)
gunicorn main:app -c gunicorn.conf.py
```

The API will be available at `http://localhost:9527/stroapp/docs` (Swagger UI).

### 4. Run User App

```bash
cd stroapp-sms-user
cp .env.example .env  # edit API_BASE_URL
flutter pub get
flutter run -d chrome  # or -d android, -d ios
```

### 5. Run Admin App

```bash
cd stroapp-sms-admin
flutter pub get
flutter run -d chrome  # or -d android, -d ios
```

### Docker Compose (Full Stack)

```bash
docker compose up -d
```

This starts PostgreSQL, Redis, and the FastAPI application together.

---

## 🔧 Configuration

### Backend Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://stroapp:stroapp_pass@localhost:5433/stroapp` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `SECRET_KEY` | App encryption key (min 32 chars) | — |
| `JWT_SECRET_KEY` | JWT signing key (min 32 chars) | — |
| `COINS_PER_USD` | Coin-to-USD conversion rate | `100` |
| `DEFAULT_MARKUP` | Default price markup multiplier | `1.15` |
| `SMSMAN_API_KEY` | SMS-Man provider API key | — |
| `FIVESIM_API_KEY` | 5sim provider API key | — |
| `SMSACTIVATE_API_KEY` | SMS-Activate provider API key | — |
| `SMSPOOL_API_KEY` | SMSPool provider API key | — |
| `SENTRY_DSN` | Sentry error tracking DSN | — |
| `TURNSTILE_SECRET_KEY` | Cloudflare Turnstile secret | — |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | — |

Full list available in `.env.example`.

### Flutter App Configuration

Each Flutter app uses a `.env` file for configuration:

**User App (.env):**
```
API_BASE_URL=http://localhost:9527/stroapp/v1
CONNECT_TIMEOUT=10000
RECEIVE_TIMEOUT=15000
```

**Admin App:** Base URL is configured in `lib/core/constants/api_constants.dart` and can be changed at runtime via the login screen UI.

---

## 📖 API Documentation

### Base URLs
- **User API**: `/stroapp/v1/...`
- **Admin API**: `/stroapp/v4/admin/api/...`
- **Swagger UI**: `/stroapp/docs`
- **ReDoc**: `/stroapp/redoc`
- **Health**: `/health`
- **Metrics**: `/stroapp/metrics`

### Authentication
- **User**: JWT Bearer tokens (access + refresh tokens)
- **Admin**: JWT Bearer tokens (separate admin login endpoint)
- **MFA**: Optional TOTP with `x-mfa-token` header
- **API Keys**: `nsk_` prefixed keys for programmatic access

### Response Format
All API responses follow a consistent structure:
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "request_id": "uuid"
}
```

Paginated responses:
```json
{
  "success": true,
  "data": { "items": [...], "total": 100, "page": 1, "per_page": 20 },
  "error": null
}
```

---

## 🔒 Security

The platform implements multiple layers of security:

- **Rate Limiting**: Redis token bucket algorithm (configurable limits)
- **CSRF Protection**: Token-based per-session
- **XSS Prevention**: Input sanitization and output encoding
- **SQL Injection**: ORM-based queries + statement-level protection
- **Proxy/VPN Detection**: Middleware to flag anonymous traffic
- **Device Fingerprinting**: Risk scoring per device
- **IP Blacklisting**: Manual and automated blacklist management
- **Session Management**: Active session tracking with revocation
- **MFA**: Optional TOTP two-factor authentication
- **Audit Logging**: Every admin action is logged with user, IP, timestamp
- **Security Scanning**: Automated vulnerability scanning
- **Secrets Management**: Encrypted storage of sensitive configuration
- **GDPR Compliance**: Data export, deletion, and consent management
- **KYC/AML**: Identity verification for high-value accounts
- **WAF**: NGINX-based web application firewall in production
- **HTTPS**: SSL/TLS enforcement via NGINX

---

## 🧪 Testing

```bash
# Backend tests
pytest tests/ -v

# Run specific test
pytest tests/test_comprehensive.py -v

# Flutter tests (user app)
cd stroapp-sms-user
flutter test

# Flutter tests (admin app)
cd stroapp-sms-admin
flutter test
```

---

## 📦 Deployment

### Production Architecture

```
Internet → NGINX (Reverse Proxy + WAF) → Gunicorn (4 workers) → FastAPI
                                                                    │
                                    PostgreSQL ←────────────────────┤
                                    Redis ←────────────────────────┤
                                    SMS Providers ←────────────────┘
```

### Docker Deployment

```bash
# Build and run
docker compose up -d --build

# Check logs
docker compose logs -f api

# Run migrations
docker compose exec api alembic upgrade head

# Create admin user
docker compose exec api python scripts/seed_admin.py admin@example.com password
```

### Manual Production Setup

1. Set up PostgreSQL and Redis
2. Configure `.env` with production values
3. Run with Gunicorn:
   ```bash
   gunicorn main:app -c gunicorn.conf.py
   ```
4. Set up NGINX reverse proxy using `nginx.conf`
5. Configure SSL certificates (Let's Encrypt)
6. Set up monitoring (Sentry, Prometheus)
7. Configure automated backups via the admin panel

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow existing code style and conventions
- Write tests for new features
- Update API documentation for endpoint changes
- Run `pytest` before submitting PRs
- Use conventional commit messages

---

## 📄 License

All rights reserved. This project is proprietary software.

---

## 📞 Support

- **Author**: Omer Jasim — [oj33593@gmail.com](mailto:oj33593@gmail.com)
- **API Docs**: `/stroapp/docs` (Swagger), `/stroapp/redoc` (ReDoc)
- **Admin Panel**: Accessible via the admin Flutter app
- **Issues**: Report via [GitHub Issues](https://github.com/omermask/stroapp-sms/issues)
- **Security**: Report via [Security Advisories](https://github.com/omermask/stroapp-sms/security/advisories/new)
