import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionChatScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionChatScreen({super.key, required this.transaction});

  @override
  State<TransactionChatScreen> createState() => _TransactionChatScreenState();
}

enum _Sender { me, other }

class _Message {
  final _Sender sender;
  final String text;
  final DateTime time;
  final bool read;

  _Message({
    required this.sender,
    required this.text,
    required this.time,
    this.read = true,
  });
}

class _TransactionChatScreenState extends State<TransactionChatScreen>
    with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  final List<_Message> _messages = [];
  bool _otherIsTyping = false;

  @override
  void initState() {
    super.initState();
    _seedMockHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _seedMockHistory() {
    final now = DateTime.now();
    _messages.addAll([
      _Message(
        sender: _Sender.other,
        text: 'Bonjour ! Confirmé pour la commande de '
            '${widget.transaction.quantity} ${widget.transaction.unit} de '
            '${widget.transaction.product}.',
        time: now.subtract(const Duration(hours: 28)),
      ),
      _Message(
        sender: _Sender.me,
        text:
            'Parfait, merci. La cargaison a quitté l\'entrepôt AGL ce matin.',
        time: now.subtract(const Duration(hours: 27)),
      ),
      _Message(
        sender: _Sender.other,
        text: 'Super, vous avez le numéro de tracking ?',
        time: now.subtract(const Duration(hours: 27)),
      ),
      _Message(
        sender: _Sender.me,
        text: widget.transaction.transportRoute.isNotEmpty
            ? widget.transaction.transportRoute
            : 'AGL-TF-2024-0847',
        time: now.subtract(const Duration(hours: 26, minutes: 50)),
      ),
      _Message(
        sender: _Sender.other,
        text: 'Reçu. Je préviens nos équipes au port. À très vite.',
        time: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_Message(
        sender: _Sender.me,
        text: text,
        time: DateTime.now(),
        read: false,
      ));
      _inputCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Simulate the other party reading + typing back (demo only)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _otherIsTyping = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() {
      _otherIsTyping = false;
      _messages.add(_Message(
        sender: _Sender.other,
        text: _autoReply(text),
        time: DateTime.now(),
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  String _autoReply(String _) =>
      'Bien reçu. Je reviens vers vous dès que possible.';

  @override
  Widget build(BuildContext context) {
    final otherName = widget.transaction.buyerName.isNotEmpty
        ? widget.transaction.buyerName
        : 'Acheteur';
    final groups = _groupByDate(_messages);

    return Scaffold(
      backgroundColor: surfaceSecondary,
      appBar: AppBar(
        backgroundColor: surfacePrimary,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: paleBlue,
              child: Text(
                _initials(otherName),
                style: AppText.body(color: navyBlue, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(otherName,
                      style: AppText.body(
                          color: textPrimary, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('En ligne', style: AppText.micro(color: success)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: navyBlue),
            tooltip: 'Détails de la transaction',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _txContextBanner(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: groups.length + (_otherIsTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (_otherIsTyping && i == groups.length) {
                  return _typingBubble();
                }
                return _dateGroup(groups[i]);
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _txContextBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: paleBlue,
      child: Row(
        children: [
          Text(widget.transaction.emoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.transaction.product} · ${widget.transaction.corridor}',
              style: AppText.caption(color: navyBlue, weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '#${widget.transaction.id}',
            style: GoogleFonts.firaCode(fontSize: 11, color: navyBlue),
          ),
        ],
      ),
    );
  }

  Widget _dateGroup(_DateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: surfacePrimary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Text(group.label,
                  style: AppText.micro(color: textTertiary)),
            ),
          ),
        ),
        for (final m in group.messages) _bubble(m),
      ],
    );
  }

  Widget _bubble(_Message m) {
    final isMe = m.sender == _Sender.me;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isMe ? navyBlue : surfacePrimary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                border: isMe
                    ? null
                    : Border.all(color: borderColor, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatHour(m.time),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : textTertiary,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          m.read ? Icons.done_all : Icons.done,
                          size: 13,
                          color: m.read
                              ? skyBlue
                              : Colors.white.withValues(alpha: 0.75),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surfacePrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: surfacePrimary,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: navyBlue),
            tooltip: 'Joindre',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Joindre un fichier — bientôt'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: surfaceSecondary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message…',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: orange,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _send,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DateGroup> _groupByDate(List<_Message> msgs) {
    final groups = <_DateGroup>[];
    for (final m in msgs) {
      final label = _formatDateLabel(m.time);
      if (groups.isNotEmpty && groups.last.label == label) {
        groups.last.messages.add(m);
      } else {
        groups.add(_DateGroup(label, [m]));
      }
    }
    return groups;
  }

  String _formatDateLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(mDay).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    const mois = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${t.day} ${mois[t.month - 1]} ${t.year}';
  }

  String _formatHour(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _DateGroup {
  final String label;
  final List<_Message> messages;
  _DateGroup(this.label, this.messages);
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: navyBlue.withValues(alpha: 0.3 + 0.6 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
