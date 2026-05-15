import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
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
  final String text;
  final bool typing;
  final File? image;

  const _ChatMessage._({
    required this.sender,
    required this.text,
    this.typing = false,
    this.image,
  });

  factory _ChatMessage.user(String text, {File? image}) =>
      _ChatMessage._(sender: _Sender.user, text: text, image: image);
  factory _ChatMessage.bot(String text) =>
      _ChatMessage._(sender: _Sender.bot, text: text);
  factory _ChatMessage.typing() =>
      const _ChatMessage._(sender: _Sender.bot, text: '', typing: true);
}

class _CustomsScreenState extends State<CustomsScreen> {
  final _input = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _apiConfigured = true;

  static const _systemInstruction = '''
Tu es l'Assistant Douanier IA expert de TradeFlow Africa.
Tu aides les PME camerounaises à exporter (notamment le Cacao) vers la ZLECAf.
Voici des faits officiels réels à utiliser dans tes réponses (2024/2025) :
1. Documents requis (via le GUCE) : 
   - Statut d'exportateur (Ministère du commerce).
   - Déclaration d'exportation (SGS / Douane).
   - Certificat phytosanitaire (MINADER).
   - Certificat d'origine ZLECAf (impératif pour les tarifs préférentiels).
   - Bulletin de vérification ONCC.
2. Fiscalité :
   - Droit de sortie : ~10% de la valeur FOB (selon Loi de Finances).
   - Abattement de 20% sur la valeur FOB pour le cacao certifié "zéro déforestation" (Nouveauté 2025).
3. OCR : Si l'utilisateur envoie une image, analyse-la en tant que document douanier ou facture et dis s'il semble conforme ou donne un résumé.

RÈGLE STRICTE DE SOURCING (très importante) :
- Termine TOUJOURS ta réponse par une section "**Sources**" en bas.
- Pour chaque affirmation factuelle, fournis le lien officiel correspondant
  au format Markdown : `- [Nom de la source](https://url-complete.exemple)`.
- Privilégie les sources officielles : site GUCE Cameroun, douane.cm,
  minader.cm, oncc-cameroun.org, secrétariat ZLECAf (au-afcfta.org),
  Loi de Finances du Cameroun, Journal Officiel.
- Si tu ne disposes pas d'URL fiable et vérifiable pour une affirmation,
  écris explicitement "Source non vérifiée — à confirmer" plutôt qu'inventer
  un lien. Ne fabrique JAMAIS d'URL.
- Si l'utilisateur envoie une image (OCR), inclus aussi des sources légales
  pour les documents identifiés.

Sois bref, précis. Utilise le Markdown pour formater joliment tes réponses.
Ne sois pas trop bavard.
''';

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  void _initAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'VOTRE_CLE_ICI') {
      _apiConfigured = false;
      _messages.add(_ChatMessage.bot(
        '⚠️ **Mode Démo** : Clé API Gemini manquante. Veuillez ajouter `GEMINI_API_KEY` dans votre fichier `.env` pour activer la recherche en temps réel et l\'OCR.'
      ));
    } else {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemInstruction),
      );
      _chat = _model.startChat();
      _messages.add(_ChatMessage.bot(
        'Bonjour ! 👋 Je suis l\'**Assistant IA TradeFlow** propulsé par Gemini.\n\n'
        'Je peux **analyser vos documents** par OCR (cliquez sur 📎) et faire des recherches sur l\'export ZLECAf. '
        'Chaque réponse inclut une section **Sources** avec des liens officiels cliquables.'
      ));
    }
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

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: navyBlue),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(_, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: navyBlue),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(_, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 4 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier trop volumineux — max 4 Mo'),
            backgroundColor: danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    _send('Vérifie ce document pour mon exportation', image: file);
  }

  String _mimeType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      case 'heic': return 'image/heic';
      default: return 'image/jpeg';
    }
  }

  Future<void> _send(String raw, {File? image}) async {
    final text = raw.trim();
    if (text.isEmpty && image == null) return;

    setState(() {
      _messages.add(_ChatMessage.user(text, image: image));
      _messages.add(_ChatMessage.typing());
    });
    _input.clear();
    _scrollToBottom();

    if (!_apiConfigured) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _messages.removeWhere((m) => m.typing);
        _messages.add(_ChatMessage.bot('Veuillez configurer `GEMINI_API_KEY` dans `.env` pour que je puisse traiter cette requête.'));
      });
      _scrollToBottom();
      return;
    }

    try {
      final prompt = text.isEmpty ? "Analyse ce document." : text;
      late final GenerateContentResponse response;

      if (image != null) {
        final bytes = await image.readAsBytes();
        response = await _chat.sendMessage(Content.multi([
          TextPart(prompt),
          DataPart(_mimeType(image.path), bytes),
        ]));
      } else {
        response = await _chat.sendMessage(Content.text(prompt));
      }

      setState(() {
        _messages.removeWhere((m) => m.typing);
        _messages.add(_ChatMessage.bot(response.text ?? 'Erreur de génération.'));
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.typing);
        _messages.add(_ChatMessage.bot('Désolé, erreur réseau : $e'));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfacePrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Assistant IA Douanier',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: orange, size: 12),
                const SizedBox(width: 4),
                Text('Propulsé par Gemini 2.5 & OCR',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: orange),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _renderMessage(_messages[index]),
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navyBlue, mediumBlue],
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: navyBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (m.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(m.image!, height: 150, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (m.text.isNotEmpty)
                    Text(m.text, style: GoogleFonts.inter(fontSize: 14, color: Colors.white, height: 1.4)),
                ],
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
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surfacePrimary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: MarkdownBody(
                      data: m.text,
                      onTapLink: (text, href, title) async {
                        if (href == null) return;
                        final uri = Uri.tryParse(href);
                        if (uri == null) return;
                        if (!mounted) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: const Text('Lien généré par l\'IA'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ce lien a été généré automatiquement. Vérifiez l\'URL avant de l\'ouvrir.',
                                  style: AppText.body(color: textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: surfaceSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(href, style: AppText.caption(color: navyBlue)),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Ouvrir'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Could not launch $href: $e');
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(fontSize: 14, color: textPrimary, height: 1.4),
                        strong: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        listBullet: GoogleFonts.inter(color: navyBlue),
                        a: GoogleFonts.inter(
                          fontSize: 14,
                          color: navyBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(delay: 0), SizedBox(width: 4),
          _Dot(delay: 200), SizedBox(width: 4),
          _Dot(delay: 400),
        ],
      ),
    );
  }


  Widget _inputBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: surfacePrimary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.auto_awesome, color: orange),
              tooltip: 'Suggestions IA',
              offset: const Offset(0, -60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) => _send(val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: "Quels sont les documents requis pour la ZLECAf ?", child: Text("Documents requis")),
                const PopupMenuItem(value: "Quelles sont les taxes d'exportation au Cameroun ?", child: Text("Taxes et Fiscalité")),
                const PopupMenuItem(value: "Comment bénéficier de l'abattement zéro déforestation ?", child: Text("Zéro déforestation (2025)")),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IconButton(
              icon: const Icon(Icons.attach_file, color: textSecondary),
              tooltip: 'Analyser un document (OCR)',
              onPressed: _pickImage,
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              margin: const EdgeInsets.only(bottom: 2),
              child: Scrollbar(
                child: TextField(
                  controller: _input,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.inter(fontSize: 15, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    hintStyle: GoogleFonts.inter(color: textTertiary, fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 4),
            child: Material(
              color: orange,
              borderRadius: BorderRadius.circular(24),
              elevation: 2,
              shadowColor: orange.withValues(alpha: 0.4),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _send(_input.text),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: navyBlue.withValues(alpha: 0.3 + 0.6 * _ctrl.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
