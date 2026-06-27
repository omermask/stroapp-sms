import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/sms_purchase/screens/services_list_screen.dart';
import '../../features/sms_purchase/screens/countries_screen.dart';
import '../../features/sms_purchase/screens/purchase_screen.dart';
import '../../features/sms_purchase/screens/waiting_for_sms_screen.dart';
import '../../features/orders/screens/orders_list_screen.dart';
import '../../shared/widgets/widgets.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/wallet/screens/transactions_screen.dart';
import '../../features/wallet/screens/top_up_screen.dart';
import '../../features/wallet/screens/payment_detail_screen.dart';
import '../../core/models/transaction.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/change_password_screen.dart';
import '../../features/settings/screens/api_keys_screen.dart';
import '../../features/settings/screens/mfa_setup_screen.dart';
import '../../features/settings/screens/sessions_screen.dart';
import '../../features/settings/screens/webhooks_screen.dart';
import '../../features/settings/screens/tiers_screen.dart';
import '../../features/settings/screens/forwarding_config_screen.dart';
import '../../features/settings/screens/gdpr_consent_screen.dart';
import '../../features/settings/screens/delete_account_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/screens/notification_prefs_screen.dart';
import '../../features/support/screens/support_list_screen.dart';
import '../../features/support/screens/create_ticket_screen.dart';
import '../../features/support/screens/ticket_detail_screen.dart';
import '../../features/kyc/screens/kyc_form_screen.dart';
import '../../features/kyc/screens/kyc_status_screen.dart';
import '../../features/kyc/screens/document_upload_screen.dart';
import '../../features/referral/screens/referral_screen.dart';
import '../../features/referral/screens/claim_code_screen.dart';
import '../../features/presets/screens/presets_screen.dart';
import '../../features/temp_email/screens/temp_email_screen.dart';
import '../../features/voice/screens/voice_purchase_screen.dart';
import '../../features/payments/screens/google_pay_screen.dart';
import '../../features/payments/screens/apple_pay_screen.dart';
import '../../features/rentals/screens/rentals_list_screen.dart';
import '../../features/rentals/screens/rental_detail_screen.dart';
import '../../features/rentals/screens/new_rental_screen.dart';
import '../../features/rentals/screens/rental_messages_screen.dart';
import '../../core/services/session_service.dart';
import '../../features/affiliate/screens/affiliate_dashboard_screen.dart';
import '../../features/affiliate/screens/apply_affiliate_screen.dart';
import '../../features/affiliate/screens/commissions_screen.dart';
import '../../features/affiliate/screens/payout_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation.startsWith('/reset-password') ||
          state.matchedLocation.startsWith('/onboarding');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', name: 'forgotPassword', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password/:token',
        name: 'resetPassword',
        builder: (_, state) => ResetPasswordScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, _) => const OnboardingScreen()),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', name: 'home', builder: (_, _) => const HomeScreen()),

          // SMS Purchase
          GoRoute(path: '/sms', name: 'sms', builder: (_, _) => const ServicesListScreen()),
          GoRoute(
            path: '/sms/:serviceName/countries',
            name: 'countries',
            builder: (_, state) => CountriesScreen(
              serviceName: state.pathParameters['serviceName']!,
              displayName: state.uri.queryParameters['display_name'],
            ),
          ),
          GoRoute(
            path: '/sms/:serviceName/countries/:countryCode/purchase',
            name: 'purchase',
            builder: (_, state) => PurchaseScreen(
              serviceName: state.pathParameters['serviceName']!,
              countryCode: state.pathParameters['countryCode']!,
              countryName: state.uri.queryParameters['country_name'] ?? state.pathParameters['countryCode']!,
              provider: state.uri.queryParameters['provider'],
              displayName: state.uri.queryParameters['display_name'],
            ),
          ),
          GoRoute(
            path: '/sms/waiting/:orderId',
            name: 'waitingForSms',
            builder: (_, state) => WaitingForSmsScreen(
              orderId: state.pathParameters['orderId']!,
            ),
          ),

          // Orders
          GoRoute(path: '/orders', name: 'orders', builder: (_, _) => const OrdersListScreen()),
          GoRoute(
            path: '/orders/:orderId',
            name: 'orderDetail',
            builder: (_, state) => OrderDetailScreen(
              orderId: state.pathParameters['orderId']!,
            ),
          ),

          // Wallet
          GoRoute(path: '/wallet', name: 'wallet', builder: (_, _) => const WalletScreen()),
          GoRoute(path: '/wallet/top-up', name: 'topUp', builder: (_, _) => const TopUpScreen()),
          GoRoute(path: '/wallet/transactions', name: 'transactions', builder: (_, _) => const TransactionsScreen()),
          GoRoute(
            path: '/wallet/transactions/:transactionId',
            name: 'paymentDetail',
            builder: (_, state) {
              final tx = state.extra as Transaction;
              return PaymentDetailScreen(transaction: tx);
            },
          ),

          // Notifications
          GoRoute(path: '/notifications', name: 'notifications', builder: (_, _) => const NotificationsScreen()),
          GoRoute(path: '/notifications/prefs', name: 'notificationPrefs', builder: (_, _) => const NotificationPrefsScreen()),

          // Support
          GoRoute(path: '/support', name: 'support', builder: (_, _) => const SupportListScreen()),
          GoRoute(path: '/support/create', name: 'createTicket', builder: (_, _) => const CreateTicketScreen()),
          GoRoute(
            path: '/support/:ticketId',
            name: 'ticketDetail',
            builder: (_, state) => TicketDetailScreen(ticketId: state.pathParameters['ticketId']!),
          ),

          // KYC
          GoRoute(path: '/kyc/form', name: 'kycForm', builder: (_, _) => const KycFormScreen()),
          GoRoute(path: '/kyc/status', name: 'kycStatus', builder: (_, _) => const KycStatusScreen()),
          GoRoute(path: '/kyc/documents', name: 'kycDocuments', builder: (_, _) => const DocumentUploadScreen()),

          // Referral
          GoRoute(path: '/referral', name: 'referral', builder: (_, _) => const ReferralScreen()),
          GoRoute(path: '/referral/claim', name: 'claimCode', builder: (_, _) => const ClaimCodeScreen()),

          // Presets
          GoRoute(path: '/presets', name: 'presets', builder: (_, _) => const PresetsScreen()),

          // Temp Email
          GoRoute(path: '/temp-email', name: 'tempEmail', builder: (_, _) => const TempEmailScreen()),

          // Voice
          GoRoute(path: '/voice', name: 'voice', builder: (_, _) => const VoicePurchaseScreen()),

          // Payments
          GoRoute(path: '/payments/google-pay', name: 'googlePay', builder: (_, _) => const GooglePayScreen()),
          GoRoute(path: '/payments/apple-pay', name: 'applePay', builder: (_, _) => const ApplePayScreen()),

          // Rentals
          GoRoute(path: '/rentals', name: 'rentals', builder: (_, _) => const RentalsListScreen()),
          GoRoute(path: '/rentals/new', name: 'newRental', builder: (_, _) => const NewRentalScreen()),
          GoRoute(
            path: '/rentals/:rentalId',
            name: 'rentalDetail',
            builder: (_, state) => RentalDetailScreen(rentalId: state.pathParameters['rentalId']!),
          ),
          GoRoute(
            path: '/rentals/:rentalId/messages',
            name: 'rentalMessages',
            builder: (_, state) => RentalMessagesScreen(rentalId: state.pathParameters['rentalId']!),
          ),

          // Affiliate
          GoRoute(path: '/affiliate', name: 'affiliate', builder: (_, _) => const AffiliateDashboardScreen()),
          GoRoute(path: '/affiliate/apply', name: 'applyAffiliate', builder: (_, _) => const ApplyAffiliateScreen()),
          GoRoute(path: '/affiliate/commissions', name: 'commissions', builder: (_, _) => const CommissionsScreen()),
          GoRoute(path: '/affiliate/payout', name: 'payout', builder: (_, _) => const PayoutScreen()),

          // Settings
          GoRoute(path: '/settings', name: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: '/settings/profile', name: 'profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/settings/change-password', name: 'changePassword', builder: (_, _) => const ChangePasswordScreen()),
          GoRoute(path: '/settings/api-keys', name: 'apiKeys', builder: (_, _) => const ApiKeysScreen()),
          GoRoute(path: '/settings/mfa', name: 'mfa', builder: (_, _) => const MfaSetupScreen()),
          GoRoute(path: '/settings/sessions', name: 'sessions', builder: (_, _) => const SessionsScreen()),
          GoRoute(path: '/settings/webhooks', name: 'webhooks', builder: (_, _) => const WebhooksScreen()),
          GoRoute(path: '/settings/tiers', name: 'tiers', builder: (_, _) => const TiersScreen()),
          GoRoute(path: '/settings/forwarding', name: 'forwarding', builder: (_, _) => const ForwardingConfigScreen()),
          GoRoute(path: '/settings/gdpr', name: 'gdpr', builder: (_, _) => const GdprConsentScreen()),
          GoRoute(path: '/settings/delete-account', name: 'deleteAccount', builder: (_, _) => const DeleteAccountScreen()),
        ],
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (_, _) {
    goRouter.refresh();
  });

  ref.listen<bool>(sessionExpiredProvider, (_, expired) {
    if (expired) {
      ref.read(authProvider.notifier).logout();
    }
  });

  return goRouter;
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(QasehIcons.home_light), activeIcon: Icon(QasehIcons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(QasehIcons.message_light), activeIcon: Icon(QasehIcons.message_filled), label: 'SMS'),
          BottomNavigationBarItem(icon: Icon(QasehIcons.document_light), activeIcon: Icon(QasehIcons.document_filled), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(QasehIcons.wallet_light), activeIcon: Icon(QasehIcons.wallet_filled), label: 'المحفظة'),
          BottomNavigationBarItem(icon: Icon(QasehIcons.setting_light), activeIcon: Icon(QasehIcons.setting_filled), label: 'الإعدادات'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/sms')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/sms');
      case 2: context.go('/orders');
      case 3: context.go('/wallet');
      case 4: context.go('/settings');
    }
  }
}
