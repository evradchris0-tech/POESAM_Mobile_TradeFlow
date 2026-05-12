import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand_logo.dart';

class CustomsScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const CustomsScreen({super.key, this.onNavigate});

  @override
  State<CustomsScreen> createState() => _CustomsScreenState();
}

enum _Sender { user, bot }

class _ChatMessage {
  final _Sender sender;
  final String? text;
  final CacaoQA? qa;
  final bool typing;

  const _ChatMessage._({
    required this.sender,
    this.text,
    this.qa,
    this.typing = false,
  });

  factory _ChatMessage.user(String text) =>
      _ChatMessage._(sender: _Sender.user, text: text);
  factory _ChatMessage.bot(CacaoQA qa) =>
      _ChatMessage._(sender: _Sender.bot, qa: qa);
  factory _ChatMessage.botText(String text) =>
      _ChatMessage._(sender: _Sender.bot, text: text);
  factory _ChatMessage.typing() =>
      const _ChatMessage._(sender: _Sender.bot, typing: true);
}

class _DocItem {
  final String name;
  final int cost;
  final bool checked;

  const _DocItem({
    required this.name,
    required this.cost,
    required this.checked,
  });

  _DocItem copyWith({bool? checked}) =>
      _DocItem(name: name, cost: cost, checked: checked ?? this.checked);
}

class _CustomsScreenState extends State<CustomsScreen> {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];

  List<_DocItem> _docs = const [
    _DocItem(name: 'Déclaration d\'exportation GUCE', cost: 15000, checked: false),
    _DocItem(name: 'Certificat d\'origine ZLECAf', cost: 5000, checked: true),
    _DocItem(name: 'Certificat phytosanitaire MINADER', cost: 3250, checked: true),
    _DocItem(name: 'Certificat de qualité ONCC', cost: 8500, checked: false),
  ];

  static const int _transportCost = 85000;
  static const int _customsDutyZLECAf = 0;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage.botText(
      'Bonjour Jean-Paul 👋 Je suis l\'assistant douanier TradeFlow, spécialisé sur le cacao Cameroun → ZLECAf. '
      'Posez votre question ou choisissez une suggestion ci-dessous.',
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  CacaoQA? _matchQA(String input) {
    final t = input.toLowerCase();
    if (t.contains('document') || t.contains('papier') || t.contains('quels')) {
      return cacaoQuestions[0];
    }
    if (t.contains('fiscal') || t.contains('taxe') || t.contains('droits') ||
        t.contains('tva') || t.contains('oncc')) {
      return cacaoQuestions[1];
    }
    if (t.contains('qualité') || t.contains('fermentation') ||
        t.contains('humidité') || t.contains('norme') || t.contains('icco')) {
      return cacaoQuestions[2];
    }
    if (t.contains('délai') || t.contains('transport') ||
        t.contains('corridor') || t.contains('agl') ||
        t.contains('abidjan') || t.contains('douala')) {
      return cacaoQuestions[3];
    }
    if (t.contains('prix') || t.contains('période') ||
        t.contains('saison') || t.contains('récolte') || t.contains('marché')) {
      return cacaoQuestions[4];
    }
    return null;
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage.user(text));
      _messages.add(_ChatMessage.typing());
    });
    _input.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final match = _matchQA(text);
    setState(() {
      _messages.removeWhere((m) => m.typing);
      if (match != null) {
        _messages.add(_ChatMessage.bot(match));
      } else {
        _messages.add(_ChatMessage.botText(
          'Je n\'ai pas de réponse précise. Essayez les suggestions cacao ci-dessous '
          '(documents, fiscalité, qualité, transport, saisonnalité).',
        ));
      }
    });
    _scrollToBottom();
  }

  Future<void> _askSuggestion(CacaoQA qa) async {
    await _send(qa.question);
  }

  int get _checklistCost =>
      _docs.where((d) => d.checked).fold(0, (s, d) => s + d.cost);

  int get _totalCost =>
      _checklistCost + _transportCost + _customsDutyZLECAf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Guide douanier',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Text(
              'Cacao · Powered by RAG officiel',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: orange,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                for (final m in _messages) _renderMessage(m),
                const SizedBox(height: 16),
                _checklistCard(),
                const SizedBox(height: 12),
                _costCalculator(),
              ],
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _renderMessage(_ChatMessage m) {
    if (m.sender == _Sender.user) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: navyBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                m.text ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogoIcon(size: 32, radius: 16, background: surfacePrimary),
          const SizedBox(width: 8),
          Expanded(
            child: m.typing
                ? _typingBubble()
                : (m.qa != null
                    ? _qaBubble(m.qa!)
                    : _plainBotBubble(m.text ?? '')),
          ),
        ],
      ),
    );
  }

  Widget _plainBotBubble(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _suggestionsRow(),
        ],
      ),
    );
  }

  Widget _qaBubble(CacaoQA qa) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            qa.answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: paleBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: navyBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Source : ${qa.source}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: navyBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: successBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_outlined, size: 14, color: success),
                const SizedBox(width: 4),
                Text(
                  'Vérifié par sources officielles',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: successText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Dot(delay: 0),
          SizedBox(width: 4),
          _Dot(delay: 200),
          SizedBox(width: 4),
          _Dot(delay: 400),
        ],
      ),
    );
  }

  Widget _suggestionsRow() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cacaoQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final shortLabels = [
            'Documents',
            'Fiscalité',
            'Qualité ICCO',
            'Corridor AGL',
            'Saisonnalité',
          ];
          return OutlinedButton(
            onPressed: () => _askSuggestion(cacaoQuestions[i]),
            style: OutlinedButton.styleFrom(
              foregroundColor: navyBlue,
              side: BorderSide(color: navyBlue.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            child: Text(
              shortLabels[i],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: navyBlue,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _checklistCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text('Checklist documents cacao', style: AppText.h3()),
          ),
          for (int i = 0; i < _docs.length; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: navyBlue,
              value: _docs[i].checked,
              onChanged: (v) => setState(() {
                _docs = List.of(_docs)
                  ..[i] = _docs[i].copyWith(checked: v ?? false);
              }),
              title: Text(
                _docs[i].name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                formatFCFA(_docs[i].cost),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _costCalculator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COÛT TOTAL ESTIMÉ — CACAO 1T DOUALA → ABIDJAN',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          _costRow(
              'Droits de douane ZLECAf', formatFCFA(_customsDutyZLECAf)),
          const SizedBox(height: 6),
          for (final d in _docs.where((d) => d.checked))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _costRow(d.name, formatFCFA(d.cost)),
            ),
          _costRow('Transport AGL Douala → Abidjan', formatFCFA(_transportCost)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: navyBlue,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  formatFCFA(_totalCost),
                  key: ValueKey(_totalCost),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: textSecondary),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: surfacePrimary,
        border: Border(top: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cacaoQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final shortLabels = [
                  'Documents',
                  'Fiscalité',
                  'Qualité ICCO',
                  'Corridor AGL',
                  'Saisonnalité',
                ];
                return OutlinedButton(
                  onPressed: () => _askSuggestion(cacaoQuestions[i]),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navyBlue,
                    side: BorderSide(color: navyBlue.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  child: Text(
                    shortLabels[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: navyBlue,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(
                    hintText: 'Posez votre question cacao...',
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: orange,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _send(_input.text),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: navyBlue.withOpacity(0.3 + 0.6 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
