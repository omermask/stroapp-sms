# StroApp SMS — Admin Dashboard

A Flutter admin dashboard application for the StroApp SMS platform. Manage users, orders, finances, security, and all platform configuration from a single interface.

> **Part of the StroApp SMS monorepo.** See the [main README](../README.md) for full platform documentation.

## Features

### Dashboard
- KPI cards (total users, orders, revenue, active providers)
- User growth chart (7 days)
- Revenue distribution chart

### User Management
- List/search/filter users (by name, email, tier, status)
- Ban/unban users
- Adjust coin balances
- Change subscription tiers
- Delete users with confirmation
- Invalidate all user sessions

### Order & Transaction Monitoring
- Browse SMS orders with status and cost
- View order details (service, country, phone, provider, code)
- List financial transactions (deposits/withdrawals)

### Support & Verification
- Support ticket management with reply threads
- KYC document review (approve/reject)
- Dispute resolution

### System Configuration
- Global settings (coins_per_usd, default_markup, temp email limits)
- Provider management (enable/disable)
- Service management (activate/deactivate)
- Feature flag toggling
- Email template editing
- Session management with force logout
- Waitlist management

### Pricing Engine
- Pricing templates and user assignments
- Promotions and promo codes
- Markup rules management

### Business Operations
- Affiliate applications, commissions, and payouts
- Reseller accounts and credit allocation
- Revenue, provider costs, and settlements
- P&L reporting
- Analytics dashboard (verifications, carriers, purchase outcomes)
- Financial reconciliation with discrepancy alerts

### Security & Compliance
- Vulnerability scanning with history
- Secrets configuration check
- Compliance report generation
- Automated database backup (create, list, restore)
- Disaster recovery testing and status monitoring
- IP and token blacklist management
- Audit log browsing
- Data export (CSV) for users, transactions, payments, logs

### Communication
- Broadcast push notifications (all users or by tier)
- Telegram bot connection management
- Email template customization

## Setup

```bash
flutter pub get
flutter run -d chrome
```

The app connects to the backend API. The base URL can be configured in the login screen.
