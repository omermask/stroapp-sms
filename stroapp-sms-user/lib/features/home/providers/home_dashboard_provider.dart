import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/endpoints/user_api.dart';
import '../../../core/api/endpoints/notifications_api.dart';
import '../../../core/api/endpoints/tier_api.dart';
import '../../../core/api/endpoints/services_api.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/models/user.dart';
import '../../../core/models/balance.dart';
import '../../../core/models/tier.dart';
import '../../../core/models/sms_order.dart';
import '../../../core/models/service.dart';

class HomeDashboardState {
  final bool isLoading;
  final User? user;
  final Balance? balance;
  final Tier? currentTier;
  final int unreadNotifications;
  final List<SMSOrder> recentVerifications;
  final List<Service> topServices;
  final int usedToday;
  final String? error;

  const HomeDashboardState({
    this.isLoading = false,
    this.user,
    this.balance,
    this.currentTier,
    this.unreadNotifications = 0,
    this.recentVerifications = const [],
    this.topServices = const [],
    this.usedToday = 0,
    this.error,
  });

  HomeDashboardState copyWith({
    bool? isLoading,
    User? user,
    Balance? balance,
    Tier? currentTier,
    int? unreadNotifications,
    List<SMSOrder>? recentVerifications,
    List<Service>? topServices,
    int? usedToday,
    String? error,
    bool clearUser = false,
    bool clearBalance = false,
    bool clearTier = false,
  }) {
    return HomeDashboardState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      balance: clearBalance ? null : (balance ?? this.balance),
      currentTier: clearTier ? null : (currentTier ?? this.currentTier),
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      recentVerifications: recentVerifications ?? this.recentVerifications,
      topServices: topServices ?? this.topServices,
      usedToday: usedToday ?? this.usedToday,
      error: error,
    );
  }
}

class HomeDashboardNotifier extends StateNotifier<HomeDashboardState> {
  final UserApi _userApi;
  final NotificationsApi _notificationsApi;
  final TierApi _tierApi;
  final ServicesApi _servicesApi;

  HomeDashboardNotifier(
    this._userApi,
    this._notificationsApi,
    this._tierApi,
    this._servicesApi,
  ) : super(const HomeDashboardState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _userApi.getUserProfile(),
        _userApi.getBalance(),
        _tierApi.getCurrentTier(),
        _notificationsApi.getUnreadCount().catchError((_) => 0),
        _userApi.getVerifications(5),
        _servicesApi.getServices(null, 30, 0),
      ]);

      final user = User.fromJson(results[0] as Map<String, dynamic>);

      final balanceData = results[1] as Map<String, dynamic>;
      final balance = Balance.fromJson(balanceData);

      final tierData = results[2] as Map<String, dynamic>;
      final tierConfig = tierData['config'] as Map<String, dynamic>;
      final currentTier = Tier.fromJson(tierConfig);

      final unreadNotifications = results[3] as int;

      final verificationsList = results[4] as List<dynamic>;
      final recentVerifications = verificationsList
          .map((e) => SMSOrder.fromJson(e as Map<String, dynamic>))
          .toList();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final usedToday = recentVerifications
          .where((v) => v.createdAt.isAfter(todayStart))
          .length;

      final servicesList = results[5] as List<dynamic>;
      final topServices = servicesList
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        user: user,
        balance: balance,
        currentTier: currentTier,
        unreadNotifications: unreadNotifications,
        recentVerifications: recentVerifications,
        topServices: topServices,
        usedToday: usedToday,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e, fallback: 'حدث خطأ في تحميل البيانات'),
      );
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final homeDashboardProvider =
    StateNotifierProvider<HomeDashboardNotifier, HomeDashboardState>((ref) {
  final userApi = ref.read(userApiProvider);
  final notificationsApi = ref.read(notificationsApiProvider);
  final tierApi = ref.read(tierApiProvider);
  final servicesApi = ref.read(servicesApiProvider);
  return HomeDashboardNotifier(
    userApi,
    notificationsApi,
    tierApi,
    servicesApi,
  );
});
