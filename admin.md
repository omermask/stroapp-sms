# Admin API Documentation — stroapp-sms

## Base Info

- **Base URL**: `/admin/api` (v4, main) + `/admin/*` (v1, legacy)
- **Auth**: JWT Bearer token — obtained via `POST /admin/api/login`
- **Response Format** (wrapped by `success_response`):
  ```json
  {
    "success": true,
    "data": { ... },
    "error": null,
    "meta": { "request_id": "...", "timestamp": "..." }
  }
  ```
- **Error Format** (`AppException`):
  ```json
  {
    "success": false,
    "data": null,
    "error": { "code": "NOT_FOUND", "message": "المستخدم غير موجود", "error_id": "...", "request_id": "..." },
    "meta": { "request_id": "...", "timestamp": "..." }
  }
  ```
- **Pagination** (when used): returns `items`, `total`, `page`, `per_page` (or `total_pages`)

---

## 1. Authentication (v4)

### `POST /admin/api/login`

Login as admin. Returns JWT token.

**Request**:
```json
{
  "email": "admin@example.com",
  "password": "secret"
}
```

**Response**:
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "email": "admin@example.com",
    "display_name": "Admin Name"
  }
}
```

**Logic**: Validates email exists, `user.is_admin == true`, password hash match. Logs audit `admin.login`.

---

## 2. Dashboard (v4)

### `GET /admin/api/dashboard`

Aggregated dashboard metrics.

**Response**:
```json
{
  "total_users": 1234,
  "active_orders": 56,
  "total_revenue": 9999.99,
  "active_providers": 3,
  "total_orders": 5000,
  "total_transactions": 8000,
  "analytics": { ... }
}
```

**Logic**: Counts users, pending orders, sum of deposit transactions. Providers checked via `ProviderRouter.enabled_providers`. Analytics from `AnalyticsService.get_dashboard()`.

---

## 3. Stats (v4)

### `GET /admin/api/stats`

Same as dashboard but without `analytics` key. Lighter query.

---

## 4. Users

### `GET /admin/api/users` (v4) | `GET /admin/api/users` (v1)

List users with optional filters.

**Query Params**: `page` (1), `per_page` (20, max 100), `search` (email/name/ID), `tier`, `is_banned`

**Response**:
```json
{
  "users": [
    {
      "id": "uuid", "email": "u@example.com", "display_name": "User",
      "coins": 100, "tier": "freemium", "is_admin": false,
      "is_banned": false, "is_active": true,
      "email_verified": true, "mfa_enabled": false,
      "created_at": "2024-01-01T00:00:00",
      "last_login_at": "2024-06-01T00:00:00"
    }
  ],
  "total": 100, "page": 1, "per_page": 20
}
```

**Logic**: Filters via `User.email.ilike`, `User.display_name.ilike`, `User.id.ilike` for search. Filters by `tier` and `is_banned`. Ordered by `created_at DESC`.

---

### `GET /admin/api/users/{user_id}` (v4) | `GET /admin/api/users/{user_id}` (v1)

Detailed user info with stats.

**Response** (v4):
```json
{
  "id": "uuid", "email": "...", "display_name": "...",
  "photo_url": "...", "coins": 100, "lifetime_coins": 500,
  "tier": "freemium", "is_admin": false, "is_banned": false,
  "is_active": true, "email_verified": true,
  "mfa_enabled": false, "onboarding_completed": true,
  "created_at": "...", "last_login_at": "...",
  "stats": { "order_count": 10, "transaction_count": 20 }
}
```

**v1 adds**: `marketing_consent`, `analytics_consent`, `stats.total_payments_usd`, `stats.active_sessions`

---

### `POST /admin/api/users/{user_id}/ban` (v4) | `POST /admin/api/users/{user_id}/ban` (v1)

Toggle ban status.

**v1 Request**:
```json
{ "reason": "Spam" }
```

**Response**:
```json
{ "id": "uuid", "is_banned": true, "message": "تم حظر المستخدم" }
```

**Logic**: Flips `user.is_banned`. v4 logs `user.ban`/`user.unban`. v1 logs with reason.

---

### `POST /admin/api/users/{user_id}/adjust` (v4) | `POST /admin/api/users/{user_id}/adjust-coins` (v1)

Add or deduct coins.

**Request**:
```json
{ "coins": 50, "reason": "Bonus" }
```

**v1 uses**: `{ "amount": 50, "reason": "Bonus" }`

**Response** (v4):
```json
{ "id": "uuid", "coins": 150, "adjustment": 50, "reason": "Bonus" }
```

**Logic**: `user.coins += body.coins`. If positive, adds to `lifetime_coins`. Creates a `Transaction` record with type `adjustment`. Blocks if user is banned. Logs audit.

---

### `POST /admin/api/users/{user_id}/tier` (v4) | `POST /admin/api/users/{user_id}/change-tier` (v1)

Change user tier.

**Request**:
```json
{ "tier": "pro" }
```

**Valid tiers**: `freemium`, `payg`, `pro`, `custom` (v4) | `freemium`, `basic`, `premium`, `enterprise` (v1 schemas)

**Response**: `{ "message": "تم تغيير رتبة المستخدم إلى pro" }`

**Logic**: Validates tier against allowed list, sets `user.tier`, logs audit.

---

### `DELETE /admin/api/users/{user_id}` (v4) | `DELETE /admin/api/users/{user_id}` (v1)

Soft-delete user.

**Logic**: Prevents self-deletion. Sets `is_active=false`, `is_banned=true`, anonymizes email to `deleted_{id}@deleted.com`. Logs audit.

---

### `POST /admin/api/users/{user_id}/sessions/invalidate` (v4) | `POST /admin/api/users/{user_id}/sessions/invalidate` (v1)

Invalidate all user sessions.

**Response**: `{ "message": "تم إلغاء جميع الجلسات" }`

**Logic**: Calls `SessionManager.invalidate_all_sessions()`.

---

## 5. Bulk Operations (v4)

### `POST /admin/api/users/bulk/adjust-coins`

Adjust coins for multiple users.

**Request**:
```json
{
  "user_ids": ["uuid1", "uuid2"],
  "amount": -10,
  "reason": "Penalty"
}
```

Response standard success.

---

## 6. Providers (v4)

### `GET /admin/api/providers`

List all SMS providers with live balance.

**Response**:
```json
[
  { "name": "twilio", "display_name": "Twilio", "enabled": true, "balance": 50.25 }
]
```

**Logic**: Iterates `provider_router.all_providers`, calls `await p.get_balance()` per provider.

---

### `POST /admin/api/providers/{name}/toggle`

Enable/disable a provider.

**Response**:
```json
{ "name": "twilio", "enabled": false }
```

**Logic**: Calls `provider_router.toggle_provider(name)` which flips state. Logs audit.

---

## 7. Services (v4)

### `GET /admin/api/services`

List all SMS services.

**Response**:
```json
[
  { "id": "uuid", "name": "whatsapp", "display_name": "WhatsApp", "category": "otp", "is_active": true, "created_at": "..." }
]
```

**Logic**: `db.query(Service).order_by(Service.name).all()`

---

### `POST /admin/api/services`

Create or update service (upsert by name).

**Request**:
```json
{ "name": "whatsapp", "display_name": "WhatsApp", "category": "otp" }
```

**Logic**: If name exists, updates `display_name` and `category`. Otherwise creates new. Logs audit.

---

## 8. Settings (v4)

### `GET /admin/api/settings`

**Response**:
```json
{
  "coins_per_usd": 100,
  "default_markup": 0.3,
  "temp_emails_per_month": 10,
  "environment": "production",
  "jwt_expiration_hours": 24,
  "jwt_refresh_expiration_days": 30,
  "third_party_configured": true
}
```

**Logic**: Reads from `get_settings()` (app config), not DB.

---

### `POST /admin/api/settings`

Update settings.

**Request**:
```json
{ "coins_per_usd": 100, "default_markup": 0.3, "temp_emails_per_month": 10 }
```

**Logic**: Upserts into `AppSetting` DB table by key. Calls `get_settings.cache_clear()`. Logs audit.

---

## 9. Transactions (v4)

### `GET /admin/api/transactions`

List transactions.

**Query Params**: `page` (1), `limit` (20, max 100), `type` (deposit/withdrawal/adjustment/refund), `user_id`

**Response**:
```json
{
  "items": [
    { "id": "uuid", "user_id": "uuid", "amount": 50, "type": "deposit",
      "description": "...", "reference": "...",
      "coins_before": 100, "coins_after": 150,
      "created_at": "..." }
  ],
  "total": 500, "page": 1, "total_pages": 25
}
```

---

## 10. Orders (v4)

### `GET /admin/api/orders`

List SMS orders.

**Query Params**: `page` (1), `limit` (20, max 100), `status`

**Response**:
```json
{
  "items": [
    { "id": "uuid", "user_id": "uuid", "service": "whatsapp",
      "country": "sa", "provider": "twilio",
      "phone_number": "+9665...", "status": "completed",
      "cost_coins": 5, "activation_id": "...",
      "verification_code": "123456", "refunded": false,
      "created_at": "..." }
  ],
  "total": 200, "page": 1, "total_pages": 10
}
```

---

## 11. Audit Logs (v4)

### `GET /admin/api/logs`

**Query Params**: `page` (1), `limit` (30, max 100), `action`, `user_id`

**Response**:
```json
{
  "items": [
    { "id": "uuid", "user_id": "uuid", "action": "user.ban",
      "resource_type": "user", "resource_id": "...",
      "details": "...", "ip_address": "1.2.3.4",
      "created_at": "..." }
  ],
  "total": 1000, "page": 1, "total_pages": 34
}
```

---

## 12. Tiers (v4)

### `GET /admin/api/tiers`

List all tier configurations.

**Response**: Array of tier objects from `TierService.all_tiers()`.

---

## 13. Feature Flags (v4)

### `GET /admin/api/feature-flags`

**Response**: Array of feature flag objects from `FeatureFlags.all_flags()`.

---

### `POST /admin/api/feature-flags/{name}`

Update a feature flag.

**Request**:
```json
{ "enabled": true, "strategy": "all_users" }
```

Logs audit.

---

## 14. Sessions (v4)

### `GET /admin/api/sessions`

List active sessions. Optional `?user_id=uuid` filter.

**Response**:
```json
[
  { "id": "uuid", "user_id": "uuid", "ip_address": "...",
    "user_agent": "...", "is_active": true,
    "created_at": "...", "expires_at": "..." }
]
```

---

### `POST /admin/api/sessions/{session_id}/revoke`

Revoke a specific session.

**Response**: `{ "message": "تم إلغاء الجلسة" }`

**Logic**: `SessionManager.invalidate_session()`. Logs audit.

---

## 15. Email Templates (v4)

### `GET /admin/api/email-templates`

List all email templates.

**Response**:
```json
[
  { "id": "uuid", "name": "welcome", "subject": "Welcome!",
    "is_active": true, "updated_at": "..." }
]
```

---

### `GET /admin/api/email-templates/{name}`

Get template by name with full HTML content.

---

### `PUT /admin/api/email-templates/{name}`

Update template.

**Request**:
```json
{ "subject": "Welcome!", "html_content": "<html>...</html>" }
```

**Logic**: `EmailTemplateService.save_template()`. Logs audit.

---

## 16. Waitlist (v4)

### `GET /admin/api/waitlist`

**Response**:
```json
[
  { "id": "uuid", "email": "u@example.com", "name": "User",
    "source": "landing", "is_notified": false, "created_at": "..." }
]
```

---

### `POST /admin/api/waitlist/{entry_id}/notify`

Mark waitlist entry as notified.

---

## 17. Notifications (v4)

### `GET /admin/api/notifications`

**Query Params**: `page`, `per_page`

**Response**:
```json
{ "items": [...], "total": 50, "page": 1, "per_page": 20 }
```

---

### `POST /admin/api/notifications`

Create admin notification.

**Request**:
```json
{
  "title": "Maintenance",
  "message": "Server down 2AM",
  "notification_type": "info",
  "audience_filter": null,
  "scheduled_at": null
}
```

**Logic**: `NotificationPrefsService.create_admin_notification()`. Logs audit.

---

### `GET /admin/api/notification-defaults`

Get default notification channel preferences.

---

### `PUT /admin/api/notification-defaults/{category}`

Update defaults for a category.

**Request**:
```json
{ "push_enabled": true, "email_enabled": false }
```

---

## 18. Support Tickets (v1)

### `GET /admin/support/tickets`

**Query Params**: `status`, `category`, `limit` (50, max 200), `offset` (0)

**Response**:
```json
[
  { "id": "uuid", "user_id": "uuid", "subject": "Problem",
    "category": "billing", "priority": "high",
    "status": "open", "assigned_to": null,
    "created_at": "...", "updated_at": "..." }
]
```

---

### `GET /admin/support/tickets/{ticket_id}`

Full ticket detail with replies.

**Response**:
```json
{
  "id": "uuid", "user_id": "uuid", "subject": "...",
  "message": "...", "category": "...", "priority": "...",
  "status": "open", "assigned_to": null,
  "created_at": "...", "updated_at": "...",
  "replies": [
    { "id": "uuid", "user_id": "uuid", "message": "...",
      "is_admin": true, "created_at": "..." }
  ]
}
```

---

### `POST /admin/support/tickets/{ticket_id}/reply`

**Request**: `{ "message": "We'll fix it" }`

---

### `POST /admin/support/tickets/{ticket_id}/close`

Closes ticket. Logs audit.

---

### `POST /admin/support/tickets/{ticket_id}/assign`

**Request**: `{ "admin_id": "uuid" }`

Assigns ticket to admin.

---

## 19. Broadcast (v1)

### `POST /admin/broadcast/notification`

Broadcast to all active users.

**Request**:
```json
{
  "title": "System Update",
  "body": "New features!",
  "notification_type": "broadcast",
  "send_push": false
}
```

**Logic**: Sends to all `User.is_active == True`. Creates `Notification` records for each user + WebSocket push via `WebSocketManager.broadcast()`. Logs audit with user count.

---

### `POST /admin/broadcast/notification/tier`

Broadcast to specific tier.

**Request**:
```json
{
  "tier": "pro",
  "title": "Pro Feature",
  "body": "Exclusive!",
  "notification_type": "broadcast"
}
```

**Logic**: Same as above but filtered by `User.tier == body.tier`.

---

## 20. Analytics (v1)

### `GET /admin/analytics/dashboard`

Dashboard analytics from `AnalyticsService.get_dashboard()`.

---

### `POST /admin/analytics/snapshot/compute`

Compute and store daily analytics snapshot.

---

### `GET /admin/analytics/verifications?days=30`

Verification statistics for last N days.

---

### `GET /admin/analytics/carriers?days=30`

Carrier-level analytics.

---

### `GET /admin/analytics/purchase-outcomes?days=7&page=1&per_page=20`

Paginated purchase outcome data.

---

### `GET /admin/analytics/monthly-targets`

Get all monthly targets.

---

### `POST /admin/analytics/monthly-targets`

Set a monthly target.

**Request**:
```json
{
  "month": "2024-06",
  "target_new_users": 1000,
  "target_revenue": 50000.0,
  "target_verifications": 5000,
  "target_success_rate": 95.0,
  "notes": "Summer push"
}
```

---

### `GET /admin/analytics/users/{user_id}`

Full analytics snapshot for a single user.

---

## Summary of All Endpoints

| # | Method | Path | Source | Description |
|---|--------|------|--------|-------------|
| 1 | POST | `/admin/api/login` | v4 | Admin login |
| 2 | GET | `/admin/api/dashboard` | v4 | Dashboard metrics |
| 3 | GET | `/admin/api/stats` | v4 | Lightweight stats |
| 4 | GET | `/admin/api/users` | v4 | List users |
| 5 | GET | `/admin/api/users/{id}` | v4 | User detail |
| 6 | POST | `/admin/api/users/{id}/ban` | v4 | Toggle ban |
| 7 | POST | `/admin/api/users/{id}/adjust` | v4 | Adjust coins |
| 8 | POST | `/admin/api/users/{id}/tier` | v4 | Change tier |
| 9 | DELETE | `/admin/api/users/{id}` | v4 | Soft-delete user |
| 10 | POST | `/admin/api/users/{id}/sessions/invalidate` | v4 | Invalidate sessions |
| 11 | POST | `/admin/api/users/bulk/adjust-coins` | v4 | Bulk coin adjustment |
| 12 | GET | `/admin/api/providers` | v4 | List providers |
| 13 | POST | `/admin/api/providers/{name}/toggle` | v4 | Toggle provider |
| 14 | GET | `/admin/api/services` | v4 | List services |
| 15 | POST | `/admin/api/services` | v4 | Create/update service |
| 16 | GET | `/admin/api/settings` | v4 | Get settings |
| 17 | POST | `/admin/api/settings` | v4 | Update settings |
| 18 | GET | `/admin/api/transactions` | v4 | List transactions |
| 19 | GET | `/admin/api/orders` | v4 | List SMS orders |
| 20 | GET | `/admin/api/logs` | v4 | Audit logs |
| 21 | GET | `/admin/api/tiers` | v4 | List tiers |
| 22 | GET | `/admin/api/feature-flags` | v4 | List feature flags |
| 23 | POST | `/admin/api/feature-flags/{name}` | v4 | Update feature flag |
| 24 | GET | `/admin/api/sessions` | v4 | List sessions |
| 25 | POST | `/admin/api/sessions/{id}/revoke` | v4 | Revoke session |
| 26 | GET | `/admin/api/email-templates` | v4 | List email templates |
| 27 | GET | `/admin/api/email-templates/{name}` | v4 | Get template |
| 28 | PUT | `/admin/api/email-templates/{name}` | v4 | Update template |
| 29 | GET | `/admin/api/waitlist` | v4 | List waitlist |
| 30 | POST | `/admin/api/waitlist/{id}/notify` | v4 | Mark notified |
| 31 | GET | `/admin/api/notifications` | v4 | List admin notifications |
| 32 | POST | `/admin/api/notifications` | v4 | Create admin notification |
| 33 | GET | `/admin/api/notification-defaults` | v4 | Get notification defaults |
| 34 | PUT | `/admin/api/notification-defaults/{category}` | v4 | Update defaults |
| 35 | GET | `/admin/support/tickets` | v1 | List support tickets |
| 36 | GET | `/admin/support/tickets/{id}` | v1 | Ticket detail |
| 37 | POST | `/admin/support/tickets/{id}/reply` | v1 | Reply to ticket |
| 38 | POST | `/admin/support/tickets/{id}/close` | v1 | Close ticket |
| 39 | POST | `/admin/support/tickets/{id}/assign` | v1 | Assign ticket |
| 40 | POST | `/admin/broadcast/notification` | v1 | Broadcast to all |
| 41 | POST | `/admin/broadcast/notification/tier` | v1 | Broadcast to tier |
| 42 | GET | `/admin/analytics/dashboard` | v1 | Analytics dashboard |
| 43 | POST | `/admin/analytics/snapshot/compute` | v1 | Compute snapshot |
| 44 | GET | `/admin/analytics/verifications` | v1 | Verification stats |
| 45 | GET | `/admin/analytics/carriers` | v1 | Carrier analytics |
| 46 | GET | `/admin/analytics/purchase-outcomes` | v1 | Purchase outcomes |
| 47 | GET | `/admin/analytics/monthly-targets` | v1 | Get monthly targets |
| 48 | POST | `/admin/analytics/monthly-targets` | v1 | Set monthly target |
| 49 | GET | `/admin/analytics/users/{id}` | v1 | User analytics snapshot |
