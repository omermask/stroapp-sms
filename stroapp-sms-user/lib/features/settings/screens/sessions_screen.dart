import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ref.read(settingsApiProvider).getSessions();
      if (mounted) {
        setState(() {
          _sessions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('إنهاء الجلسة', style: AppTextStyles.titleMedium),
        content: const Text('هل أنت متأكد من إنهاء هذه الجلسة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنهاء', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(settingsApiProvider).revokeSession(sessionId);
        await _fetchSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء الجلسة')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _revokeAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvasLight,
        title: const Text('إنهاء كل الجلسات', style: AppTextStyles.titleMedium),
        content: const Text('هل أنت متأكد من إنهاء جميع الجلسات النشطة؟ سيتم تسجيل خروجك من جميع الأجهزة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: AppColors.mutedStrong))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنهاء الكل', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(settingsApiProvider).revokeAllSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنهاء جميع الجلسات. سيتم تسجيل خروجك.')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  String _deviceIcon(String? device) {
    final d = (device ?? '').toLowerCase();
    if (d.contains('android')) return 'android';
    if (d.contains('iphone') || d.contains('ios') || d.contains('ipad')) return 'ios';
    if (d.contains('mac') || d.contains('windows') || d.contains('linux')) return 'desktop';
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('الجلسات النشطة'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
        actions: [
          if (_sessions.any((s) => s['is_active'] == true))
            TextButton(
              onPressed: _revokeAll,
              child: const Text('إنهاء الكل', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          if (_sessions.isNotEmpty && !_sessions.any((s) => s['is_active'] == true))
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('العودة للرئيسية', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchSessions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _fetchSessions, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  )
                : _sessions.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Column(
                              children: [
                                Icon(QasehIcons.ticket_curved, size: 48, color: AppColors.mutedStrong),
                                const SizedBox(height: 12),
                                Text('لا توجد جلسات نشطة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : !_sessions.any((s) => s['is_active'] == true)
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(QasehIcons.ticket_curved, size: 48, color: AppColors.mutedStrong),
                                    const SizedBox(height: 12),
                                    Text('جميع الجلسات منتهية', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: () => context.go('/home'),
                                      icon: const Icon(QasehIcons.arrow_left_curved, size: 18),
                                      label: const Text('العودة إلى الرئيسية'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final device = session['device'] as String? ?? 'متصفح';
                          final ip = session['ip'] as String? ?? '---';
                          final lastUsed = session['last_used_at'] != null
                              ? DateTime.parse(session['last_used_at'] as String)
                              : null;
                          final isCurrent = session['is_current'] == true;
                          final isActive = session['is_active'] == true;
                          final sessionId = session['id'] as String? ?? '';
                          final browser = session['browser'] as String?;
                          final os = session['os'] as String?;
                          final city = session['city'] as String?;
                          final country = session['country'] as String?;
                          final location = [city, country].where((e) => e != null && e.isNotEmpty).join('، ');
                          final detailParts = <String>[
                            if (browser != null && browser.isNotEmpty) browser,
                            if (os != null && os.isNotEmpty) os,
                          ];
                          final detail = detailParts.join(' • ');

                          IconData iconData;
                          switch (_deviceIcon(device)) {
                            case 'android':
                              iconData = QasehIcons.call_curved;
                              break;
                            case 'ios':
                              iconData = QasehIcons.call_curved;
                              break;
                            case 'desktop':
                              iconData = QasehIcons.work_curved;
                              break;
                            default:
                              iconData = QasehIcons.discovery_curved;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.canvasLight : AppColors.canvasLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent ? AppColors.primary : AppColors.hairlineLight,
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: (isActive ? AppColors.primary : AppColors.mutedStrong).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(iconData, size: 20, color: isActive ? AppColors.primary : AppColors.mutedStrong),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(device, style: AppTextStyles.labelMedium.copyWith(
                                                color: isActive ? AppColors.ink : AppColors.mutedStrong,
                                              )),
                                            ),
                                            if (isCurrent)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('حالياً', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontSize: 11)),
                                              ),
                                            if (!isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('غير نشط', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 11)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('IP: $ip', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                                        if (detail.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(detail, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                                          ),
                                        if (location.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text('الموقع: $location', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                                          ),
                                        if (lastUsed != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'آخر استخدام: ${_formatDateTime(lastUsed)}',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isActive && !isCurrent && sessionId.isNotEmpty)
                                    IconButton(
                                      icon: Icon(QasehIcons.close_square_curved, size: 20, color: AppColors.error),
                                      onPressed: () => _revokeSession(sessionId),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقائق';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعات';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
