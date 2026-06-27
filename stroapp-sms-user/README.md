# StroApp SMS — User Mobile App

A Flutter mobile application for the StroApp SMS platform. Browse services, purchase virtual phone numbers, receive SMS verification codes, and manage your account.

> **Part of the StroApp SMS monorepo.** See the [main README](../README.md) for full platform documentation.

## Features

- Browse 100+ services (Telegram, WhatsApp, Google, Facebook, TikTok, etc.)
- View real-time pricing across 200+ countries
- Purchase temporary numbers for SMS verification
- Receive SMS messages with real-time polling
- Rent numbers for extended durations
- Cancel orders with partial refund
- Wallet with coin-based transactions
- Top-up via Google Pay / Apple Pay / Stripe
- Saved presets for one-click re-purchase
- Temporary email inbox service
- Voice call verification
- Webhook and email forwarding configuration
- MFA (TOTP) security
- API key management
- Referral and affiliate programs
- KYC verification
- Support ticket system
- Multi-language (Arabic/English) with RTL support
- Dark/Light theme
- Push notifications via FCM

## Setup

```bash
cp .env.example .env
# Edit .env with your API_BASE_URL

flutter pub get
flutter run
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API base URL | `http://localhost:9527/stroapp/v1` |
| `CONNECT_TIMEOUT` | HTTP connect timeout (ms) | `10000` |
| `RECEIVE_TIMEOUT` | HTTP receive timeout (ms) | `15000` |
