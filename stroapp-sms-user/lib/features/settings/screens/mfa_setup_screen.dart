import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/settings_api.dart';

class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  bool _isLoading = true;
  bool? _isEnabled;
  String? _error;
  String? _setupData;
  String? _secret;
  final _verifyController = TextEditingController();
  final _disableController = TextEditingController();
  bool _showVerify = false;
  bool _showDisable = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void dispose() {
    _verifyController.dispose();
    _disableController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final enabled = await ref.read(settingsApiProvider).getMfaStatus();
      if (mounted) setState(() { _isEnabled = enabled; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _setupMfa() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ref.read(settingsApiProvider).setupMfa();
      if (mounted) {
        setState(() {
          _setupData = data['qr_code'] as String? ?? data['uri'] as String?;
          _secret = data['secret'] as String?;
          _showVerify = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _verifyMfa() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(settingsApiProvider).verifyMfa(_verifyController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل التحقق الثنائي بنجاح')),
        );
        setState(() { _isEnabled = true; _showVerify = false; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _disableMfa() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(settingsApiProvider).disableMfa(_disableController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعطيل التحقق الثنائي')),
        );
        setState(() { _isEnabled = false; _showDisable = false; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('التحقق الثنائي (MFA)'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null && _isEnabled == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(QasehIcons.danger_triangle_curved, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _fetchStatus, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.canvasLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineLight),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _isEnabled == true ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _isEnabled == true ? QasehIcons.lock_curved : QasehIcons.unlock_curved,
                                size: 32,
                                color: _isEnabled == true ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isEnabled == true ? 'مفعل' : 'غير مفعل',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: _isEnabled == true ? AppColors.success : AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEnabled == true
                                  ? 'التحقق الثنائي مفعل لحسابك'
                                  : 'التحقق الثنائي غير مفعل. قم بتفعيله لزيادة أمان حسابك.',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isEnabled == false && !_showVerify)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _setupMfa,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تفعيل التحقق الثنائي', style: AppTextStyles.button),
                          ),
                        ),
                      if (_isEnabled == true && !_showDisable)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => setState(() { _showDisable = true; }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تعطيل التحقق الثنائي', style: AppTextStyles.button),
                          ),
                        ),
                      if (_showVerify) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.hairlineLight),
                          ),
                          child: Column(
                            children: [
                              if (_setupData != null)
                                Column(
                                  children: [
                                    Text('امسح رمز QR باستخدام تطبيق Google Authenticator', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                                    const SizedBox(height: 12),
                                    _buildQrImage(_setupData!),
                                    if (_secret != null) ...[
                                      const SizedBox(height: 8),
                                      Text('أو أدخل المفتاح يدوياً:', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: _secret!));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('تم نسخ المفتاح'), duration: Duration(seconds: 2)),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(QasehIcons.document_curved, size: 16, color: AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: SelectableText(
                                              _secret!,
                                              style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink, fontFamily: 'monospace'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Text('رمز التحقق', style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _verifyController,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                                decoration: InputDecoration(
                                  hintText: 'أدخل رمز التحقق',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoftLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.hairlineLight),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _verifyMfa,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('تأكيد', style: AppTextStyles.button),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_showDisable) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.hairlineLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('لتعطيل التحقق الثنائي، يرجى إدخال رمز التحقق:', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _disableController,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                                decoration: InputDecoration(
                                  hintText: 'رمز التحقق',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
                                  filled: true,
                                  fillColor: AppColors.surfaceSoftLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.hairlineLight),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _disableMfa,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: AppColors.onDark,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('تعطيل', style: AppTextStyles.button),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildQrImage(String data) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(data);
    } catch (_) {}
    if (bytes != null && bytes.length > 100) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairlineLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      );
    }
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Center(
        child: SelectableText(
          data,
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
