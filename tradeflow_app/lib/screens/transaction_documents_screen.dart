import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionDocumentsScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDocumentsScreen({super.key, required this.transaction});

  @override
  State<TransactionDocumentsScreen> createState() =>
      _TransactionDocumentsScreenState();
}

class _DocEntry {
  final String name;
  final String type;
  final IconData icon;
  final Color tint;
  final DateTime addedAt;
  final String size;
  final bool verified;
  final File? localFile;

  _DocEntry({
    required this.name,
    required this.type,
    required this.icon,
    required this.tint,
    required this.addedAt,
    required this.size,
    required this.verified,
    this.localFile,
  });
}

class _TransactionDocumentsScreenState
    extends State<TransactionDocumentsScreen> {
  final List<_DocEntry> _documents = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _seedMock();
  }

  void _seedMock() {
    final base = DateTime.now().subtract(const Duration(days: 2));
    _documents.addAll([
      _DocEntry(
        name: 'Facture commerciale',
        type: 'commercial_invoice',
        icon: Icons.receipt_long,
        tint: navyBlue,
        addedAt: base,
        size: '142 Ko',
        verified: true,
      ),
      _DocEntry(
        name: 'Certificat d\'origine ZLECAf',
        type: 'certificate_origin',
        icon: Icons.public,
        tint: success,
        addedAt: base.add(const Duration(hours: 4)),
        size: '286 Ko',
        verified: true,
      ),
      _DocEntry(
        name: 'Connaissement (BOL)',
        type: 'bill_of_lading',
        icon: Icons.local_shipping_outlined,
        tint: orange,
        addedAt: base.add(const Duration(hours: 7)),
        size: '512 Ko',
        verified: false,
      ),
    ]);
  }

  Future<void> _addDocument() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<_DocPickResult>(
      context: context,
      backgroundColor: surfacePrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AddDocSheet(),
    );
    if (picked == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: picked.source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (image == null) return;

    final file = File(image.path);
    setState(() {
      _documents.add(_DocEntry(
        name: picked.label,
        type: picked.type,
        icon: picked.icon,
        tint: picked.tint,
        addedAt: DateTime.now(),
        size: '${(file.lengthSync() / 1024).toStringAsFixed(0)} Ko',
        verified: false,
        localFile: file,
      ));
      _uploading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final bytes = await file.readAsBytes();
        final path =
            '${user.id}/${widget.transaction.rawId}/${picked.type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('transaction-docs')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        // Persist storage path in transactions.shipping_docs
        final row = await Supabase.instance.client
            .from('transactions')
            .select('shipping_docs')
            .eq('id', widget.transaction.rawId)
            .single();
        final current = List<String>.from(
            (row['shipping_docs'] as List?)?.cast<String>() ?? []);
        current.add(path);
        await Supabase.instance.client
            .from('transactions')
            .update({'shipping_docs': current})
            .eq('id', widget.transaction.rawId);
      }
    } catch (_) {
      // Bucket ou RLS manquant en démo : le fichier reste visible localement
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _preview(_DocEntry doc) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: doc.localFile != null
                  ? InteractiveViewer(child: Image.file(doc.localFile!))
                  : Container(
                      color: surfaceSecondary,
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(doc.icon, size: 96, color: doc.tint),
                          const SizedBox(height: 16),
                          Text(doc.name,
                              style: AppText.h2(color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(
                              'Aperçu indisponible — fichier sur le serveur',
                              style: AppText.caption(
                                  color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSecondary,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: surfaceSecondary,
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: navyBlue),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _contextBanner(),
          Expanded(
            child: _documents.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _docTile(_documents[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        backgroundColor: orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _contextBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: paleBlue,
      child: Row(
        children: [
          Text(widget.transaction.emoji,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.transaction.product} · #${widget.transaction.id}',
              style: AppText.caption(
                  color: navyBlue, weight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: paleBlue,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.folder_open, size: 36, color: navyBlue),
            ),
            const SizedBox(height: 20),
            Text('Aucun document', style: AppText.h3()),
            const SizedBox(height: 8),
            Text(
              'Ajoutez la facture, le BOL, le certificat d\'origine pour cette transaction.',
              textAlign: TextAlign.center,
              style: AppText.body(color: textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docTile(_DocEntry doc) {
    return Material(
      color: surfacePrimary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _preview(doc),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: doc.tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(doc.icon, color: doc.tint, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name,
                        style: AppText.body(
                            color: textPrimary, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_formatDate(doc.addedAt),
                            style: AppText.caption()),
                        Text(' · ', style: AppText.caption()),
                        Text(doc.size, style: AppText.caption()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (doc.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: successBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 12, color: success),
                      const SizedBox(width: 4),
                      Text('Vérifié',
                          style: AppText.micro(color: successText)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: warningBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 12, color: warning),
                      const SizedBox(width: 4),
                      Text('En attente',
                          style: AppText.micro(color: warningText)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    const mois = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${t.day} ${mois[t.month - 1]}';
  }
}

class _DocPickResult {
  final String label;
  final String type;
  final IconData icon;
  final Color tint;
  final ImageSource source;

  const _DocPickResult({
    required this.label,
    required this.type,
    required this.icon,
    required this.tint,
    required this.source,
  });
}

class _AddDocSheet extends StatefulWidget {
  const _AddDocSheet();

  @override
  State<_AddDocSheet> createState() => _AddDocSheetState();
}

class _AddDocSheetState extends State<_AddDocSheet> {
  static const _types = [
    ('Facture commerciale', 'commercial_invoice', Icons.receipt_long, navyBlue),
    ('Certificat d\'origine', 'certificate_origin', Icons.public, success),
    ('Connaissement (BOL)', 'bill_of_lading', Icons.local_shipping_outlined, orange),
    ('Liste de colisage', 'packing_list', Icons.list_alt, mediumBlue),
    ('Certificat phytosanitaire', 'phytosanitary', Icons.eco, success),
    ('Autre', 'other', Icons.description_outlined, textTertiary),
  ];

  (String, String, IconData, Color)? _selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: 16),
            Text('Type de document', style: AppText.h3()),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _selected == t;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = t);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? t.$4.withValues(alpha: 0.10) : surfaceSecondary,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? t.$4 : borderColor,
                        width: selected ? 1.2 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.$3, size: 16, color: t.$4),
                        const SizedBox(width: 6),
                        Text(
                          t.$1,
                          style: AppText.caption(
                            color: selected ? t.$4 : textSecondary,
                            weight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_selected != null) ...[
              Text('Source', style: AppText.caption()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.photo_camera,
                      label: 'Caméra',
                      onTap: () => _pick(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galerie',
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pick(ImageSource source) {
    final t = _selected!;
    Navigator.pop(
      context,
      _DocPickResult(
        label: t.$1,
        type: t.$2,
        icon: t.$3,
        tint: t.$4,
        source: source,
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: surfacePrimary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: navyBlue.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: navyBlue, size: 22),
            const SizedBox(height: 6),
            Text(label, style: AppText.caption(color: navyBlue)),
          ],
        ),
      ),
    );
  }
}
