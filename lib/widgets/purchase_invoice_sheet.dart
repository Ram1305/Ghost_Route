import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subscription.dart';
import '../models/user.dart';
import '../theme/nexus_theme.dart';

/// Invoice detail sheet shown when a purchase history item is tapped.
class PurchaseInvoiceSheet extends StatelessWidget {
  final Subscription purchase;
  final User user;

  const PurchaseInvoiceSheet({
    super.key,
    required this.purchase,
    required this.user,
  });

  static Future<void> show(
    BuildContext context, {
    required Subscription purchase,
    required User user,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PurchaseInvoiceSheet(purchase: purchase, user: user),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NexusTheme.border2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: NexusTheme.text3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        purchase.invoiceNumber,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: NexusTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: NexusTheme.text2),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusBanner(),
                  const SizedBox(height: 20),
                  _buildSection('Billed to', [
                    _InvoiceRow('Name', user.username),
                    _InvoiceRow('Email', user.email),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection('Purchase details', [
                    _InvoiceRow('Plan', purchase.planLabel),
                    _InvoiceRow('Billing period', purchase.plan.period),
                    _InvoiceRow('Devices', '${purchase.plan.devices}'),
                    _InvoiceRow('Amount', '${purchase.displayAmount} ${purchase.displayCurrency}'),
                    _InvoiceRow('Payment method', purchase.paymentMethodLabel),
                    _InvoiceRow('Purchased on', _formatDate(purchase.date)),
                    _InvoiceRow('Valid until', _formatDate(purchase.validUntil)),
                    if (purchase.transactionId != null &&
                        purchase.transactionId!.isNotEmpty)
                      _InvoiceRow('Transaction ID', purchase.transactionId!),
                    if (purchase.productId != null &&
                        purchase.productId!.isNotEmpty)
                      _InvoiceRow('Product ID', purchase.productId!),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: NexusTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NexusTheme.border),
                    ),
                    child: Text(
                      'This receipt confirms your Ghost Route subscription purchase. '
                      'Manage or cancel your subscription in your ${purchase.paymentMethodLabel} account settings.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        height: 1.5,
                        color: NexusTheme.text2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            NexusTheme.teal.withOpacity(0.15),
            NexusTheme.gold.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: NexusTheme.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NexusTheme.teal.withOpacity(0.2),
            ),
            child: const Icon(Icons.check_circle_rounded, color: NexusTheme.teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment successful',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NexusTheme.text,
                  ),
                ),
                Text(
                  purchase.planLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: NexusTheme.text2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            purchase.displayAmount,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: NexusTheme.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_InvoiceRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 2,
            color: NexusTheme.text3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusTheme.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 20, color: NexusTheme.border),
                _buildRow(rows[i].label, rows[i].value),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: NexusTheme.text3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NexusTheme.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceRow {
  final String label;
  final String value;

  _InvoiceRow(this.label, this.value);
}
