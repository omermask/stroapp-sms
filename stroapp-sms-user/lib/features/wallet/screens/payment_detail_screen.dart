import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/transaction.dart';
import '../../../core/api/endpoints/user_api.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;
  const PaymentDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final userApi = ref.read(userApiProvider);
      final invoice = await userApi.createInvoiceFromTransaction(widget.transaction.id);
      final invoiceId = invoice['id'] as String;
      final invoiceNumber = invoice['invoice_number'] as String;

      final pdfBytes = await userApi.downloadInvoicePdf(invoiceId);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$invoiceNumber.pdf');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Invoice $invoiceNumber',
          text: 'Stroapp Invoice - $invoiceNumber',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الفاتورة في: ${file.path}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الفاتورة: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isCredit = tx.amount > 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoftLight,
      appBar: AppBar(
        title: const Text('تفاصيل الفاتورة'),
        backgroundColor: AppColors.canvasLight,
        surfaceTintColor: AppColors.canvasLight,
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            GestureDetector(
              onTap: _downloadPdf,
              child: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(QasehIcons.download_curved, size: 22, color: AppColors.ink),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInvoiceHeader(tx),
            const SizedBox(height: 20),
            _buildPaymentDetails(context, tx),
            const SizedBox(height: 20),
            _buildSummary(tx, isCredit),
            const SizedBox(height: 20),
            _buildFooter(tx),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(Transaction tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(QasehIcons.wallet_filled, size: 32, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tx.type == 'deposit' ? 'إيداع عبر Google Pay' : tx.description ?? tx.type,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'تمت العملية بنجاح',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext ctx, Transaction tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الدفع', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildIdRow(ctx, tx.id),
          const Divider(height: 20),
          _buildRow('التاريخ', _formatDateTime(tx.createdAt)),
          const Divider(height: 20),
          _buildRow('المنتج', tx.description ?? tx.type),
          if (tx.reference != null) ...[
            const Divider(height: 20),
            _buildRow('المرجع', tx.reference!),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(Transaction tx, bool isCredit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملخص المبلغ', style: AppTextStyles.titleSmall.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildRow('المبلغ', '\$5.00'),
          const Divider(height: 20),
          _buildRow('العملات المستلمة', '+${tx.amount} عملة'),
          const Divider(height: 20),
          if (tx.coinsBefore != null) _buildRow('الرصيد قبل', '${tx.coinsBefore} عملة'),
          if (tx.coinsBefore != null && tx.coinsAfter != null) ...[
            const Divider(height: 20),
            _buildRow('الرصيد بعد', '${tx.coinsAfter} عملة'),
          ],
          const Divider(height: 20),
          _buildRow('الحالة', 'مكتملة', valueColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildFooter(Transaction tx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(QasehIcons.shield_done_curved, size: 24, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'هذه فاتورة إلكترونية معتمدة من Stroapp',
              style: AppTextStyles.caption.copyWith(color: AppColors.bodyLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: valueColor ?? AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildIdRow(BuildContext ctx, String id) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('رقم العملية', style: AppTextStyles.caption.copyWith(color: AppColors.mutedStrong)),
        const Spacer(),
        Flexible(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: id));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('تم نسخ رقم العملية'), duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        id,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(QasehIcons.document_curved, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
