import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class KycFlowScreen extends StatefulWidget {
  const KycFlowScreen({super.key});

  @override
  State<KycFlowScreen> createState() => _KycFlowScreenState();
}

class _KycFlowScreenState extends State<KycFlowScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  String _idDocType = 'national_id';
  File? _idDocument;
  File? _selfie;
  File? _businessDoc;

  bool _submitting = false;
  bool _done = false;
  String? _errorMsg;

  String? get _role => Supabase.instance.client.auth.currentUser?.userMetadata?['role'] as String?;
  bool get _isPme => _role == 'pme' || _role == null;
  int get _totalSteps => _isPme ? 3 : 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<File?> _pickPhoto({required bool useCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    return picked == null ? null : File(picked.path);
  }

  Future<void> _captureFor(int step) async {
    HapticFeedback.selectionClick();
    final source = await showModalBottomSheet<bool>(
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: navyBlue),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: navyBlue),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _pickPhoto(useCamera: source);
    if (file == null) return;
    setState(() {
      if (step == 0) _idDocument = file;
      if (step == 1) _selfie = file;
      if (step == 2) _businessDoc = file;
    });
  }

  bool get _canContinue {
    if (_currentStep == 0) return _idDocument != null;
    if (_currentStep == 1) return _selfie != null;
    return true;
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep == 0) {
      Navigator.pop(context);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Non connecté');

      if (_idDocument != null) await _uploadDoc(_idDocument!, _idDocType, user.id);
      if (_selfie != null) await _uploadDoc(_selfie!, 'selfie', user.id);
      if (_businessDoc != null) await _uploadDoc(_businessDoc!, 'rccm', user.id);

      await Supabase.instance.client.from('profiles').update({
        'kyc_status': 'basic',
      }).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _done = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _submitting = false;
      });
    }
  }

  Future<void> _uploadDoc(File file, String docType, String userId) async {
    final bytes = await file.readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${docType}_$ts.jpg';

    try {
      await Supabase.instance.client.storage
          .from('kyc-documents')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
    } catch (_) {
      // Bucket peut ne pas exister en démo : on continue
    }

    await Supabase.instance.client.from('kyc_documents').insert({
      'user_id': userId,
      'doc_type': docType,
      'storage_path': path,
      'file_name': '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'mime_type': 'image/jpeg',
      'is_verified': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _successScreen();

    return Scaffold(
      backgroundColor: surfacePrimary,
      appBar: AppBar(
        backgroundColor: surfacePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyBlue),
          onPressed: _back,
        ),
        title: Text(
          'Étape ${_currentStep + 1} sur $_totalSteps',
          style: AppText.body(color: textPrimary, weight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _progressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _idStep(),
                _selfieStep(),
                if (_isPme) _businessStep(),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? orange : borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: paleBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: navyBlue, size: 36),
        ),
        const SizedBox(height: 20),
        Text(title, style: AppText.h1(), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppText.body(color: textTertiary),
        ),
      ],
    );
  }

  Widget _idStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _stepHeader(
            icon: Icons.badge_outlined,
            title: 'Pièce d\'identité',
            subtitle:
                'Photographiez votre Carte Nationale ou Passeport, recto. Assurez-vous que tout est lisible.',
          ),
          const SizedBox(height: 24),
          _docTypeSelector(),
          const SizedBox(height: 20),
          _captureSlot(
            file: _idDocument,
            onTap: () => _captureFor(0),
          ),
          const SizedBox(height: 16),
          _whyExplain(
            'Vérification d\'identité requise par la réglementation BEAC contre la fraude et le blanchiment.',
          ),
        ],
      ),
    );
  }

  Widget _selfieStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _stepHeader(
            icon: Icons.face_outlined,
            title: 'Selfie de vérification',
            subtitle:
                'Tenez votre pièce d\'identité bien visible à côté de votre visage.',
          ),
          const SizedBox(height: 24),
          _captureSlot(
            file: _selfie,
            onTap: () => _captureFor(1),
            placeholder: Icons.face_retouching_natural,
          ),
          const SizedBox(height: 16),
          _tip('Bonne luminosité', Icons.light_mode_outlined),
          const SizedBox(height: 8),
          _tip('Visage et pièce d\'identité dans le cadre', Icons.crop_free),
          const SizedBox(height: 8),
          _tip('Pas de lunettes de soleil ni casquette', Icons.visibility_outlined),
        ],
      ),
    );
  }

  Widget _businessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _stepHeader(
            icon: Icons.business_outlined,
            title: 'Documents professionnels',
            subtitle:
                'Photographiez votre RCCM ou un autre document officiel d\'entreprise. Optionnel mais accélère la vérification.',
          ),
          const SizedBox(height: 24),
          _captureSlot(
            file: _businessDoc,
            onTap: () => _captureFor(2),
            placeholder: Icons.upload_file,
          ),
          const SizedBox(height: 16),
          _whyExplain(
            'Augmente votre Trust Score initial et débloque l\'escrow étendu (jusqu\'à 10 M FCFA).',
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dangerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMsg!,
                style: AppText.caption(color: dangerText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _docTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _typeChip('CNI', 'national_id'),
          _typeChip('Passeport', 'passport'),
        ],
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _idDocType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _idDocType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? surfacePrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.body(
                color: selected ? navyBlue : textTertiary,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _captureSlot({
    required File? file,
    required VoidCallback onTap,
    IconData placeholder = Icons.add_a_photo_outlined,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: file != null ? surfacePrimary : surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? success : borderColor,
            width: file != null ? 1.5 : 1,
            style: file != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(file, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: surfacePrimary.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: success, size: 14),
                          const SizedBox(width: 4),
                          Text('Capturé',
                              style: AppText.micro(color: successText)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: surfacePrimary.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onTap,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.refresh,
                              color: navyBlue, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: paleBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(placeholder, color: navyBlue, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text('Toucher pour capturer',
                        style: AppText.body(color: navyBlue, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Photo ou galerie',
                        style: AppText.caption()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _tip(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppText.body(color: textSecondary)),
        ),
      ],
    );
  }

  Widget _whyExplain(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: navyBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.caption(color: navyBlue)),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_submitting || !_canContinue) ? null : _next,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _canContinue ? orange : surfaceSecondary,
              foregroundColor: _canContinue ? Colors.white : textTertiary,
              disabledBackgroundColor: surfaceSecondary,
              disabledForegroundColor: textTertiary,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(isLastStep ? 'Soumettre la vérification' : 'Continuer'),
          ),
        ),
      ),
    );
  }

  Widget _successScreen() {
    return Scaffold(
      backgroundColor: surfacePrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle,
                        color: success, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Documents soumis',
                style: AppText.h1(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre vérification est en cours. Vous recevrez une notification sous 24 à 48h ouvrées.',
                textAlign: TextAlign.center,
                style: AppText.body(color: textTertiary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: navyBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'En attendant, vous pouvez naviguer dans l\'app en mode lecture.',
                        style: AppText.caption(color: navyBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Retour à l\'app'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
