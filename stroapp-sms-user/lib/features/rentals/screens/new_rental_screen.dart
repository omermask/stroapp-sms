import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/rentals_api.dart';
import '../../../core/api/api_exceptions.dart';

class NewRentalScreen extends ConsumerStatefulWidget {
  const NewRentalScreen({super.key});

  @override
  ConsumerState<NewRentalScreen> createState() => _NewRentalScreenState();
}

class _NewRentalScreenState extends ConsumerState<NewRentalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController(text: '1');
  bool _autoExtend = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _services = [];
  String? _selectedCountry;
  String? _selectedService;
  bool _loadingCountries = true;
  bool _loadingServices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCountries());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final data = await ref.read(rentalsApiProvider).getAvailableCountries();
      if (mounted) {
        setState(() {
          _countries = data.cast<Map<String, dynamic>>();
          _loadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCountries = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e, fallback: 'فشل تحميل الدول')), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _loadServices(String country) async {
    setState(() {
      _loadingServices = true;
      _selectedService = null;
      _services = [];
    });
    try {
      final data = await ref.read(rentalsApiProvider).getAvailableServices(country);
      if (mounted) {
        setState(() {
          _services = data.cast<Map<String, dynamic>>();
          _loadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingServices = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractErrorMessage(e, fallback: 'فشل تحميل الخدمات')), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null || _selectedService == null) return;

    final hours = int.tryParse(_hoursController.text) ?? 1;
    if (hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون الساعات أكبر من 0'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(rentalsApiProvider).createRental(
        _selectedService!,
        _selectedCountry!,
        hours,
        _autoExtend,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الإيجار بنجاح'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('إيجار جديد'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(QasehIcons.bag_curved, size: 28, color: AppColors.onPrimary),
                    const SizedBox(height: 12),
                    Text(
                      'إنشاء إيجار جديد',
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.onPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'استأجر رقمًا لاستقبال الرسائل',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('الدولة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              _loadingCountries
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
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
                          borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
                        ),
                      ),
                      hint: Text('اختر الدولة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                      isExpanded: true,
                      items: _countries.map((c) {
                        return DropdownMenuItem(
                          value: c['code'] as String,
                          child: Text(c['name'] as String? ?? c['code'] as String, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCountry = val);
                        if (val != null) _loadServices(val);
                      },
                      validator: (v) => v == null ? 'يرجى اختيار الدولة' : null,
                    ),
              const SizedBox(height: 20),
              Text('الخدمة', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              if (_selectedCountry == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.canvasLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineLight),
                  ),
                  child: Text('اختر الدولة أولاً', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                )
              else if (_loadingServices)
                const Center(child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              else
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: InputDecoration(
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
                      borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
                    ),
                  ),
                  hint: Text('اختر الخدمة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedStrong)),
                  isExpanded: true,
                  items: _services.map((s) {
                    final name = s['name'] as String? ?? s['id'] as String;
                    final stock = s['stock'] as int? ?? 0;
                    return DropdownMenuItem(
                      value: s['id'] as String,
                      child: Row(
                        children: [
                          Expanded(child: Text(name, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink))),
                          if (stock > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('$stock', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedService = val);
                  },
                  validator: (v) => v == null ? 'يرجى اختيار الخدمة' : null,
                ),
              const SizedBox(height: 20),
              Text('المدة (ساعات)', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
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
                    borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'يرجى إدخال المدة';
                  final hours = int.tryParse(v);
                  if (hours == null || hours <= 0) return 'يرجى إدخال رقم صحيح أكبر من 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.canvasLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineLight),
                ),
                child: SwitchListTile(
                  title: Text('التمديد التلقائي', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink)),
                  subtitle: Text(
                    'تجديد الإيجار تلقائياً عند انتهاء المدة',
                    style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                  ),
                  value: _autoExtend,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _autoExtend = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                          ),
                        )
                      : Text('إنشاء الإيجار', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
