import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/kyc_api.dart';
import '../../../core/models/kyc_profile.dart';
import '../providers/kyc_provider.dart';

class KycFormScreen extends ConsumerStatefulWidget {
  const KycFormScreen({super.key});

  @override
  ConsumerState<KycFormScreen> createState() => _KycFormScreenState();
}

class _KycFormScreenState extends ConsumerState<KycFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _phoneNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(kycApiProvider);
      final response = await api.getKycProfile();
      final profile = KycProfile.fromJson(response);
      _fullNameController.text = profile.fullName ?? '';
      _dateOfBirthController.text = profile.dateOfBirth ?? '';
      _nationalityController.text = profile.nationality ?? '';
      _phoneNumberController.text = profile.phoneNumber ?? '';
      _addressLine1Controller.text = profile.addressLine1 ?? '';
      _addressLine2Controller.text = profile.addressLine2 ?? '';
      _cityController.text = profile.city ?? '';
      _stateController.text = profile.state ?? '';
      _postalCodeController.text = profile.postalCode ?? '';
      _countryController.text = profile.country ?? '';
      setState(() => _isEditing = true);
    } catch (_) {
      setState(() => _isEditing = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = {
      'full_name': _fullNameController.text.trim(),
      'date_of_birth': _dateOfBirthController.text.trim(),
      'nationality': _nationalityController.text.trim(),
      'phone_number': _phoneNumberController.text.trim(),
      'address_line1': _addressLine1Controller.text.trim(),
      'address_line2': _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'country': _countryController.text.trim(),
    };

    try {
      final api = ref.read(kycApiProvider);
      if (_isEditing) {
        await api.updateKycProfile(data);
      } else {
        await api.createKycProfile(data);
      }
      await ref.read(kycProvider.notifier).fetchProfile();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('نموذج التحقق'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('المعلومات الشخصية'),
                    const SizedBox(height: 12),
                    _buildTextField(_fullNameController, 'الاسم الكامل'),
                    const SizedBox(height: 12),
                    _buildTextField(_dateOfBirthController, 'تاريخ الميلاد', hint: 'YYYY-MM-DD'),
                    const SizedBox(height: 12),
                    _buildTextField(_nationalityController, 'الجنسية'),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneNumberController, 'رقم الهاتف', keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    _buildSectionTitle('العنوان'),
                    const SizedBox(height: 12),
                    _buildTextField(_addressLine1Controller, 'العنوان (سطر 1)'),
                    const SizedBox(height: 12),
                    _buildTextField(_addressLine2Controller, 'العنوان (سطر 2)', required: false),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_cityController, 'المدينة')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_stateController, 'الولاية/المقاطعة')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_postalCodeController, 'الرمز البريدي')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_countryController, 'الدولة')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text(
                                _isEditing ? 'تحديث البيانات' : 'إرسال الطلب',
                                style: AppTextStyles.button,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink));
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong),
        filled: true,
        fillColor: AppColors.canvasLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.hairlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.bluePrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال $label' : null
          : null,
    );
  }
}
