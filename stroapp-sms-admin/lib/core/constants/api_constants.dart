class ApiConstants {
  ApiConstants._();

  static String baseUrl = 'http://10.92.177.145:9527/stroapp/v4/admin/api';

  // v4 endpoints under /admin/api
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String stats = '/stats';
  static const String users = '/users';
  static const String providers = '/providers';
  static const String services = '/services';
  static const String settings = '/settings';
  static const String transactions = '/transactions';
  static const String orders = '/orders';
  static const String logs = '/logs';
  static const String tiers = '/tiers';
  static const String featureFlags = '/feature-flags';
  static const String sessions = '/sessions';
  static const String emailTemplates = '/email-templates';
  static const String waitlist = '/waitlist';
  static const String notifications = '/notifications';
  static const String notificationDefaults = '/notification-defaults';

  // v4 base without /api for v1 routes mounted under /stroapp/v4
  static String get v4Base {
    const suffix = '/admin/api';
    final b = baseUrl;
    if (b.endsWith('$suffix/')) return b.substring(0, b.length - suffix.length - 1);
    if (b.endsWith(suffix)) return b.substring(0, b.length - suffix.length);
    return b;
  }

  // v1 endpoints mounted under /stroapp/v4/admin/*
  static const String supportTickets = '/admin/support/tickets';
  static const String kyc = '/admin/kyc';
  static const String disputes = '/admin/disputes';
  static const String broadcast = '/admin/broadcast';
  static const String pricing = '/admin/pricing';
  static const String affiliate = '/admin/affiliate';
  static const String reseller = '/admin/reseller';
  static const String financial = '/admin/financial';
  static const String reconciliation = '/admin/reconciliation';
  static const String reconciliationRun = '/admin/reconciliation/run';
  static const String reconciliationLogs = '/admin/reconciliation/logs';
  static const String reconciliationAlerts = '/admin/reconciliation/alerts';
  static String reconciliationAlertResolve(String id) => '/admin/reconciliation/alerts/$id/resolve';
  static const String security = '/admin/security';
  static const String telegram = '/admin/telegram';
  static const String blacklist = '/admin/blacklist';
  static const String whitelabel = '/admin/whitelabel';
  static const String export_ = '/admin/export';
  static const String sync = '/admin/sync';
  static const String analytics = '/admin/analytics';
  static const String pnl = '/admin/pnl';
  static const String ledger = '/user/ledger';

  // Dynamic endpoint helpers
  static String userDetail(String id) => '/users/$id';
  static String banUser(String id) => '/users/$id/ban';
  static String adjustCoins(String id) => '/users/$id/adjust';
  static String setTier(String id) => '/users/$id/tier';
  static String deleteUser(String id) => '/users/$id';
  static String invalidateSessions(String id) =>
      '/users/$id/sessions/invalidate';
  static String providerToggle(String name) => '/providers/$name/toggle';
  static String serviceToggle(String name) => '/services/$name/toggle';
  static String featureFlag(String name) => '/feature-flags/$name';
  static String revokeSession(String id) => '/sessions/$id/revoke';
  static String emailTemplate(String name) => '/email-templates/$name';
  static String waitlistNotify(String id) => '/waitlist/$id/notify';
  static String ticketDetail(String id) => '/admin/support/tickets/$id';
  static String ticketReply(String id) => '/admin/support/tickets/$id/reply';
  static String ticketClose(String id) => '/admin/support/tickets/$id/close';
  static String ticketAssign(String id) => '/admin/support/tickets/$id/assign';
  static String kycDetail(String id) => '/admin/kyc/$id';
  static String kycVerify(String id) => '/admin/kyc/$id/verify';
  static String kycReject(String id) => '/admin/kyc/$id/reject';
  static String disputeDetail(String id) => '/admin/disputes/$id';
  static String disputeResolve(String id) => '/admin/disputes/$id/resolve';
  static const String loginV1 = '/admin/api/login';

  // Sync
  static const String syncTrigger = '/admin/sync/trigger';
  static const String syncStatus = '/admin/sync/status';
  static const String syncOrchestrator = '/admin/sync/orchestrator';
  static const String syncOrchestratorStart = '/admin/sync/orchestrator/start';
  static const String syncOrchestratorStop = '/admin/sync/orchestrator/stop';
  static const String syncMarkupRules = '/admin/sync/markup-rules';
  static const String syncServiceCountries = '/admin/sync/service-countries';

  // Blacklist
  static const String blacklistIps = '/admin/blacklist/ips';
  static const String blacklistTokens = '/admin/blacklist/tokens';
  static String blockIp() => '/admin/blacklist/ip';
  static String unblockIp() => '/admin/blacklist/ip';

  // Broadcast
  static const String broadcastNotification = '/admin/broadcast/notification';
  static const String broadcastTier = '/admin/broadcast/notification/tier';

  // Pricing
  static const String pricingTemplates = '/admin/pricing/templates';
  static String pricingTemplateDetail(String id) => '/admin/pricing/templates/$id';
  static String pricingTemplateActivate(String id) => '/admin/pricing/templates/$id/activate';
  static String pricingTemplateHistory(String id) => '/admin/pricing/templates/$id/history';
  static const String pricingAssignments = '/admin/pricing/assignments';
  static String pricingAssignmentDelete(String id) => '/admin/pricing/assignments/$id';
  static const String pricingPromotions = '/admin/pricing/promotions';
  static String pricingPromotionToggle(String id) => '/admin/pricing/promotions/$id/toggle';
  static String pricingPromoCodeUsage(String code) => '/admin/pricing/promo-codes/$code/usage';

  // Affiliate
  static const String affiliateApplications = '/admin/affiliate/applications';
  static String affiliateApplicationReview(String id) => '/admin/affiliate/applications/$id/review';
  static const String affiliateCommissions = '/admin/affiliate/commissions';
  static String affiliateCommissionApprove(String id) => '/admin/affiliate/commissions/$id/approve';
  static const String affiliateTiers = '/admin/affiliate/tiers';
  static const String affiliatePayouts = '/admin/affiliate/payouts';
  static String affiliatePayoutProcess(String id) => '/admin/affiliate/payouts/$id/process';

  // Reseller
  static const String resellerAccounts = '/admin/reseller/accounts';
  static String resellerAccountDetail(String id) => '/admin/reseller/accounts/$id';
  static String resellerAccountToggle(String id) => '/admin/reseller/accounts/$id/toggle';
  static const String resellerSubAccounts = '/admin/reseller/sub-accounts';
  static String resellerSubAccountDetail(String id) => '/admin/reseller/sub-accounts/$id';
  static String resellerSubAccountToggle(String id) => '/admin/reseller/sub-accounts/$id/toggle';
  static const String resellerCreditAllocate = '/admin/reseller/credit/allocate';
  static const String resellerCreditHistory = '/admin/reseller/credit/history';
  static const String resellerTransactions = '/admin/reseller/transactions';
  static String resellerAnalytics(String id) => '/admin/reseller/analytics/$id';

  // Financial
  static const String financialRevenue = '/admin/financial/revenue';
  static const String financialRevenueDetails = '/admin/financial/revenue/details';
  static const String financialRevenueAdjust = '/admin/financial/revenue/adjust';
  static const String financialRevenueAdjustments = '/admin/financial/revenue/adjustments';
  static const String financialTaxConfigs = '/admin/financial/tax/configs';
  static const String financialTaxReports = '/admin/financial/tax/reports';
  static const String financialTaxExemptions = '/admin/financial/tax/exemptions';
  static const String financialProviderAgreements = '/admin/financial/providers/agreements';
  static const String financialProviderCosts = '/admin/financial/providers/costs';
  static const String financialProviderSettlements = '/admin/financial/providers/settlements';
  static const String financialProviderReconciliations = '/admin/financial/providers/reconciliations';
  static const String financialStatements = '/admin/financial/statements';
  static const String financialMetrics = '/admin/financial/metrics';

  // Security
  static const String securityScan = '/admin/security/scan';
  static const String securityScans = '/admin/security/scans';
  static const String securityCompliance = '/admin/security/compliance';
  static const String securitySecretsCheck = '/admin/security/secrets/check';
  static const String securityBackup = '/admin/security/backup';
  static const String securityBackups = '/admin/security/backups';
  static String securityBackupRestore(String id) => '/admin/security/backup/$id/restore';
  static const String securityDRTest = '/admin/security/dr/test';
  static const String securityDRTests = '/admin/security/dr/tests';
  static const String securityDRStatus = '/admin/security/dr/status';

  // Export
  static const String exportUsers = '/admin/export/users';
  static const String exportTransactions = '/admin/export/transactions';
  static const String exportPayments = '/admin/export/payments';
  static const String exportAuditLogs = '/admin/export/audit-logs';

  // P&L
  static const String pnlGenerate = '/admin/pnl/generate';
  static const String pnlReports = '/admin/pnl/reports';

  // Analytics
  static const String analyticsDashboard = '/admin/analytics/dashboard';
  static const String analyticsVerifications = '/admin/analytics/verifications';
  static const String analyticsCarriers = '/admin/analytics/carriers';
  static const String analyticsPurchaseOutcomes = '/admin/analytics/purchase-outcomes';
  static const String analyticsMonthlyTargets = '/admin/analytics/monthly-targets';
  static String analyticsUser(String id) => '/admin/analytics/users/$id';

  // Telegram
  static const String telegramConnections = '/admin/telegram/connections';

  // Whitelabel
  static const String whitelabelDomains = '/admin/whitelabel/domains';
}
