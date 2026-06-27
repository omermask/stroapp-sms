import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/api/endpoints/kyc_api.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDocuments());
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(kycApiProvider);
      final data = await api.getDocuments();
      setState(() => _documents = data.cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _computeHash(String filePath) {
    final bytes = utf8.encode(filePath);
    return sha256.convert(bytes).toString();
  }

  Future<void> _showUploadDialog() async {
    String documentType = 'passport';
    String filePath = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('رفع مستند'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: documentType,
                decoration: InputDecoration(
                  labelText: 'نوع المستند',
                  filled: true,
                  fillColor: AppColors.canvasLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.hairlineLight),
                  ),
                ),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                items: const [
                  DropdownMenuItem(value: 'passport', child: Text('جواز سفر')),
                  DropdownMenuItem(value: 'national_id', child: Text('بطاقة هوية')),
                  DropdownMenuItem(value: 'driver_license', child: Text('رخصة قيادة')),
                  DropdownMenuItem(value: 'selfie', child: Text('صورة شخصية')),
                ],
                onChanged: (v) {
                  if (v != null) documentType = v;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => filePath = v,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  labelText: 'مسار الملف',
                  hintText: '/path/to/file.jpg',
                  hintTextDirection: TextDirection.rtl,
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
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (filePath.trim().isEmpty) return;
                Navigator.pop(ctx);
                _uploadDocument(documentType, filePath.trim());
              },
              child: const Text('رفع'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(String documentType, String filePath) async {
    setState(() => _isUploading = true);
    try {
      final api = ref.read(kycApiProvider);
      final hash = _computeHash(filePath);
      await api.uploadDocument(documentType, filePath, hash);
      await _fetchDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع المستند بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  IconData _docIcon(String? type) {
    switch (type) {
      case 'passport':
        return QasehIcons.document_curved;
      case 'national_id':
        return QasehIcons.profile_curved;
      case 'driver_license':
        return QasehIcons.document_curved;
      case 'selfie':
        return QasehIcons.camera_curved;
      default:
        return QasehIcons.document_curved;
    }
  }

  String _docLabel(String? type) {
    switch (type) {
      case 'passport':
        return 'جواز سفر';
      case 'national_id':
        return 'بطاقة هوية';
      case 'driver_license':
        return 'رخصة قيادة';
      case 'selfie':
        return 'صورة شخصية';
      default:
        return type ?? 'مستند';
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'مقبول';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('رفع المستندات'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _isUploading ? null : _showUploadDialog,
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              )
            : Icon(QasehIcons.plus_curved, color: AppColors.onPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? CustomErrorWidget(message: _error!, onRetry: _fetchDocuments)
              : _documents.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(icon: QasehIcons.upload_curved, message: 'لا توجد مستندات مرفوعة'),
                      ],
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _fetchDocuments,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _documents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          final docType = doc['document_type'] as String?;
                          final status = doc['status'] as String?;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.canvasLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.hairlineLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _docIcon(docType),
                                    size: 22,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _docLabel(docType),
                                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        doc['file_path'] as String? ?? '',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: AppTextStyles.caption.copyWith(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
