import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _country = 'CM';

  String? _avatarUrl;
  File? _newAvatarFile;

  bool _loading = true;
  bool _saving = false;
  String? _errorMsg;

  String _initialFirst = '';
  String _initialLast = '';
  String _initialPhone = '';
  String _initialCity = '';
  String _initialCountry = 'CM';

  bool get _isDirty =>
      _firstNameCtrl.text.trim() != _initialFirst ||
      _lastNameCtrl.text.trim() != _initialLast ||
      _phoneCtrl.text.trim() != _initialPhone ||
      _cityCtrl.text.trim() != _initialCity ||
      _country != _initialCountry ||
      _newAvatarFile != null;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onChanged);
    _lastNameCtrl.addListener(_onChanged);
    _phoneCtrl.addListener(_onChanged);
    _cityCtrl.addListener(_onChanged);
    _loadProfile();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final fullName = (row['full_name'] as String?) ?? '';
      final parts = fullName.split(' ').where((s) => s.isNotEmpty).toList();
      _initialFirst = parts.isNotEmpty ? parts.first : '';
      _initialLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _initialPhone = (row['phone'] as String?) ?? '';
      _initialCity = (row['city'] as String?) ?? '';
      _initialCountry = (row['country'] as String?) ?? 'CM';
      _avatarUrl = row['avatar_url'] as String?;

      _firstNameCtrl.text = _initialFirst;
      _lastNameCtrl.text = _initialLast;
      _phoneCtrl.text = _initialPhone;
      _cityCtrl.text = _initialCity;
      _country = _initialCountry;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: navyBlue),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: navyBlue),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty ||
                _newAvatarFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: danger),
                title: const Text('Retirer la photo',
                    style: TextStyle(color: danger)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _newAvatarFile = null;
                    _avatarUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _newAvatarFile = File(picked.path));
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Prénom et nom sont requis');
      return;
    }
    setState(() {
      _saving = true;
      _errorMsg = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      String? newAvatarUrl = _avatarUrl;

      if (_newAvatarFile != null) {
        try {
          final bytes = await _newAvatarFile!.readAsBytes();
          final path = '${user.id}.jpg';
          await Supabase.instance.client.storage.from('avatars').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );
          newAvatarUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(path);
        } catch (_) {
          // Storage bucket 'avatars' manquant : on continue sans bloquer
        }
      }

      await Supabase.instance.client.from('profiles').update({
        'full_name':
            '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'phone': _phoneCtrl.text.trim().isNotEmpty
            ? _phoneCtrl.text.trim()
            : null,
        'city': _cityCtrl.text.trim().isNotEmpty
            ? _cityCtrl.text.trim()
            : null,
        'country': _country,
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        _saving = false;
      });
    }
  }

  Future<bool> _confirmExit() async {
    if (!_isDirty) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Modifications non enregistrées'),
        content: const Text('Vos changements seront perdus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer la modification'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (!shouldExit || !mounted) return;
        if (!context.mounted) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modifier mon profil'),
          actions: [
            if (_isDirty && !_loading)
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  'Sauver',
                  style: AppText.body(color: orange, weight: FontWeight.bold),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: navyBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _avatarPicker()),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: Text(
                          _newAvatarFile != null ||
                                  (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? 'Changer la photo'
                              : 'Ajouter une photo',
                          style: AppText.body(color: navyBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Prénom',
                            controller: _firstNameCtrl,
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            label: 'Nom',
                            controller: _lastNameCtrl,
                            icon: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'Téléphone',
                      controller: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _countryDropdown(),
                    const SizedBox(height: 16),
                    _field(
                      label: 'Ville',
                      controller: _cityCtrl,
                      icon: Icons.location_city_outlined,
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dangerBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: AppText.caption(color: dangerText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_saving || !_isDirty) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isDirty ? orange : surfaceSecondary,
                          foregroundColor:
                              _isDirty ? Colors.white : textTertiary,
                          disabledBackgroundColor: surfaceSecondary,
                          disabledForegroundColor: textTertiary,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _avatarPicker() {
    return Hero(
      tag: 'profile-avatar',
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: navyBlue,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: _newAvatarFile != null
                  ? Image.file(_newAvatarFile!, fit: BoxFit.cover)
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsAvatar(),
                        )
                      : _initialsAvatar(),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: orange,
                shape: BoxShape.circle,
                border: Border.all(color: surfacePrimary, width: 3),
              ),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsAvatar() {
    final initials =
        (_firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text[0] : '') +
            (_lastNameCtrl.text.isNotEmpty ? _lastNameCtrl.text[0] : '');
    return Center(
      child: Text(
        initials.isEmpty ? 'U' : initials.toUpperCase(),
        style: AppText.h1(color: Colors.white),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption()),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 20)),
        ),
      ],
    );
  }

  Widget _countryDropdown() {
    const countries = [
      ('CM', 'Cameroun'),
      ('CI', 'Côte d\'Ivoire'),
      ('SN', 'Sénégal'),
      ('GA', 'Gabon'),
      ('CG', 'Congo'),
      ('TD', 'Tchad'),
      ('NG', 'Nigeria'),
      ('MA', 'Maroc'),
      ('KE', 'Kenya'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pays', style: AppText.caption()),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _country,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.public, size: 20),
          ),
          items: countries
              .map((c) => DropdownMenuItem(
                    value: c.$1,
                    child: Text(c.$2, style: AppText.body(color: textPrimary)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _country = v);
          },
        ),
      ],
    );
  }
}
