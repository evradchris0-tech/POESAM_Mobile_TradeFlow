import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../data/mock_data.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

class EscrowScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final Transaction? transaction;

  const EscrowScreen({super.key, this.onNavigate, this.transaction});

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen>
    with SingleTickerProviderStateMixin {
  late Transaction _tx;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction ?? mockTransactions.first;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _confirmReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmer la réception'),
        content: Text(
          'Vous confirmez avoir reçu la marchandise pour #${_tx.id} ? '
          'Les fonds seront libérés vers le vendeur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _tx = Transaction(
        id: _tx.id,
        product: _tx.product,
        emoji: _tx.emoji,
        shCode: _tx.shCode,
        sellerName: _tx.sellerName,
        sellerCity: _tx.sellerCity,
        buyerName: _tx.buyerName,
        buyerCity: _tx.buyerCity,
        corridor: _tx.corridor,
        quantity: _tx.quantity,
        unit: _tx.unit,
        unitPrice: _tx.unitPrice,
        totalAmount: _tx.totalAmount,
        commission: _tx.commission,
        transportCost: _tx.transportCost,
        customsDuty: _tx.customsDuty,
        transportDays: _tx.transportDays,
        transportRoute: _tx.transportRoute,
        opportunityScore: _tx.opportunityScore,
        status: TransactionStatus.delivered,
        progressPercent: 1.0,
        sellerTrustScore: _tx.sellerTrustScore,
        isTrustVerified: _tx.isTrustVerified,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text('Réception confirmée. Fonds libérés au vendeur.'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _reportIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _IssueSheet(txId: _tx.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = _tx;
    final showActions = tx.status != TransactionStatus.delivered &&
        tx.status != TransactionStatus.releasing;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction #${tx.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusBadge(status: tx.status)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Stepper(status: tx.status),
            const SizedBox(height: 20),
            _productCard(tx),
            const SizedBox(height: 12),
            _financialCard(tx),
            const SizedBox(height: 24),
            Text('Suivi cargaison', style: AppText.h3()),
            const SizedBox(height: 12),
            _trackingTimeline(tx),
            const SizedBox(height: 16),
            _eta(tx),
            const SizedBox(height: 24),
            Text('Documents', style: AppText.h3()),
            const SizedBox(height: 10),
            _documents(tx),
            const SizedBox(height: 24),
            if (showActions) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Confirmer la réception'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _reportIssue,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: danger,
                    side: const BorderSide(color: danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Signaler un problème'),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Transaction clôturée. Merci pour votre confiance.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: successText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Transaction tx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.product, style: AppText.h3()),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.quantity} ${tx.unit} · Code SH : ${tx.shCode}',
                      style: AppText.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(child: _partyChip(tx.sellerName)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: textTertiary),
              ),
              Flexible(child: _partyChip(tx.buyerName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partyChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: navyBlue,
        ),
      ),
    );
  }

  Widget _financialCard(Transaction tx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          _row('Montant total', formatFCFA(tx.totalAmount),
              bold: true, valueColor: navyBlue),
          const SizedBox(height: 8),
          _row('Commission TF (1,5 %)', formatFCFA(tx.commission)),
          const SizedBox(height: 8),
          _row('Transport AGL', formatFCFA(tx.transportCost)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL acheteur',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                formatFCFA(tx.totalForBuyer),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: navyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fonds sécurisés chez Ecobank PAPSS',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: successText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _trackingTimeline(Transaction tx) {
    final isDelivered = tx.status == TransactionStatus.delivered;
    final events = [
      _TrackEvent('Douala, entrepôt AGL', '14 mai 2026, 08h30', _StepState.done),
      _TrackEvent('Frontière Éséka', '15 mai 2026, 14h20', _StepState.done),
      _TrackEvent(
          'Port d\'Abidjan',
          isDelivered ? '17 mai 2026, 09h15' : '17 mai 2026 (estimé)',
          isDelivered ? _StepState.done : _StepState.current),
      _TrackEvent(
          'Destination finale',
          isDelivered ? '18 mai 2026, 11h40' : '18 mai 2026 (estimé)',
          isDelivered ? _StepState.done : _StepState.future),
    ];

    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          SizedBox(
            height: 70,
            child: TimelineTile(
              alignment: TimelineAlign.start,
              isFirst: i == 0,
              isLast: i == events.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 22,
                height: 22,
                indicator: _trackDot(events[i].state),
              ),
              beforeLineStyle: LineStyle(
                color:
                    events[i].state == _StepState.future ? borderColor : success,
                thickness: 2,
              ),
              afterLineStyle: LineStyle(
                color: i + 1 < events.length &&
                        events[i + 1].state == _StepState.future
                    ? borderColor
                    : (events[i].state == _StepState.done ? success : orange),
                thickness: 2,
              ),
              endChild: Padding(
                padding: const EdgeInsets.only(left: 12, top: 2, bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      events[i].title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: events[i].state == _StepState.future
                            ? textTertiary
                            : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      events[i].subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _trackDot(_StepState state) {
    switch (state) {
      case _StepState.done:
        return Container(
          decoration: const BoxDecoration(color: success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
      case _StepState.current:
        return AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final t = _pulse.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 22 + 10 * t,
                  height: 22 + 10 * t,
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.35 * (1 - t)),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          },
        );
      case _StepState.future:
        return Container(
          decoration: BoxDecoration(
            color: surfacePrimary,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
        );
    }
  }

  Widget _eta(Transaction tx) {
    final delivered = tx.status == TransactionStatus.delivered;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: delivered ? successBg : paleBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(delivered ? Icons.check_circle : Icons.schedule,
              color: delivered ? success : navyBlue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                delivered ? 'Livré' : 'Livraison estimée dans',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: delivered ? successText : textSecondary,
                ),
              ),
              Text(
                delivered ? '18 mai 2026' : '3 jours',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: delivered ? successText : navyBlue,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documents(Transaction tx) {
    final delivered = tx.status == TransactionStatus.delivered;
    Widget chip(String label,
        {required Color bg, required Color fg, IconData? icon}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Certif. Origine ✓', bg: successBg, fg: successText),
        chip('Phytosanitaire ✓', bg: successBg, fg: successText),
        chip('BL ✓', bg: successBg, fg: successText),
        chip(
          delivered ? 'Réception confirmée ✓' : 'Réception à confirmer',
          bg: delivered ? successBg : warningBg,
          fg: delivered ? successText : warningText,
          icon: delivered ? Icons.verified : Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}

enum _StepState { done, current, future }

class _TrackEvent {
  final String title;
  final String subtitle;
  final _StepState state;

  _TrackEvent(this.title, this.subtitle, this.state);
}

class _Stepper extends StatelessWidget {
  final TransactionStatus status;

  const _Stepper({required this.status});

  int get _activeStep {
    switch (status) {
      case TransactionStatus.pending:
        return 0;
      case TransactionStatus.escrowConfirmed:
        return 1;
      case TransactionStatus.shipped:
        return 2;
      case TransactionStatus.inTransit:
        return 3;
      case TransactionStatus.delivered:
      case TransactionStatus.releasing:
        return 4;
      case TransactionStatus.disputed:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Commande', 'Escrow', 'Expédié', 'En transit', 'Livré'];
    final active = _activeStep;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  _circle(i, active),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: i == active
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _textColor(i, active),
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  width: 16,
                  height: 2,
                  color: i < active ? success : borderColor,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _circle(int i, int active) {
    if (i < active) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(color: success, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    if (i == active) {
      final isDone = active == 4;
      final color = isDone ? success : orange;
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isDone
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '${i + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: surfaceSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        '${i + 1}',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textTertiary,
        ),
      ),
    );
  }

  Color _textColor(int i, int active) {
    if (i < active) return successText;
    if (i == active) return active == 4 ? successText : orange;
    return textTertiary;
  }
}

class _IssueSheet extends StatefulWidget {
  final String txId;

  const _IssueSheet({required this.txId});

  @override
  State<_IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends State<_IssueSheet> {
  static const _motifs = [
    'Marchandise endommagée',
    'Quantité non conforme',
    'Qualité insuffisante',
    'Retard de livraison',
    'Documents manquants',
    'Autre',
  ];
  String? _selected;
  final _desc = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.report_problem, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Litige ouvert. Notre médiateur va vous contacter.')),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: danger,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Signaler un problème', style: AppText.h2()),
            const SizedBox(height: 4),
            Text(
              'Transaction #${widget.txId}',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            Text(
              'MOTIF',
              style: AppText.micro(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _motifs.map((m) {
                final sel = m == _selected;
                return ChoiceChip(
                  label: Text(m),
                  selected: sel,
                  onSelected: (_) => setState(() => _selected = m),
                  selectedColor: paleBlue,
                  side: BorderSide(
                    color: sel ? navyBlue : borderColor,
                    width: sel ? 1 : 0.5,
                  ),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? navyBlue : textSecondary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('DESCRIPTION', style: AppText.micro()),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème en détail...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_selected == null || _sending) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Ouvrir le litige'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
