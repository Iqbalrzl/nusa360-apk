import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nusa360/pages/landing_pages.dart';
import 'package:nusa360/pages/login.dart';
import 'package:nusa360/services/nusa360_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  String? _avatarUrl;
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  bool _hasChanges = false;
  final apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_checkChanges);
    _emailCtrl.addListener(_checkChanges);
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Ambil dari cache lebih dulu
    final cached = await apiService.getCachedUser();
    final avatar = await apiService.getAvatarUrl();
    setState(() {
      _user = cached;
      _avatarUrl = avatar;
      _loading = false;
    });
    // Set nilai form
    _nameCtrl.text = (_user?['username'] ?? _user?['name'] ?? '').toString();
    _emailCtrl.text = (_user?['email'] ?? '').toString();

    _checkChanges();
  }

  void _checkChanges() {
    final originalName =
        (_user?['username'] ?? _user?['name'] ?? '').toString();
    final originalEmail = (_user?['email'] ?? '').toString();

    final changed =
        _nameCtrl.text.trim() != originalName ||
        _emailCtrl.text.trim() != originalEmail;

    setState(() {
      _hasChanges = changed;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final me = await apiService.getMe();
    final avatar = await apiService.getAvatarUrl();
    setState(() {
      _user = me ?? _user;
      _avatarUrl = avatar ?? _avatarUrl;
      _loading = false;
    });
    _nameCtrl.text = (_user?['username'] ?? _user?['name'] ?? '').toString();
    _emailCtrl.text = (_user?['email'] ?? '').toString();
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final url = await apiService.uploadAvatar(picked);
    setState(() {
      _avatarUrl = url ?? _avatarUrl;
      _uploading = false;
    });
    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal upload avatar')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar diperbarui')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await apiService.updateProfile(
      username: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal memperbarui profil')));
    }
  }

  Future<void> _logout() async {
    await apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // BARU: dialog konfirmasi sebelum logout
  Future<void> _confirmLogout() async {
    const primary = Color(0xFFC84E4E);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _logout();
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFC44B4B);
    return Scaffold(
      body: SafeArea(
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      // Header dengan back button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            tooltip: 'Kembali',
                          ),
                          const SizedBox(width: 4),
                          Image.asset('assets/logo.png', width: 70, height: 70),
                          const Spacer(),
                          IconButton(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Card Profile ringkas
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: primary.withOpacity(0.15),
                                  backgroundImage:
                                      _avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                          : null,
                                  child:
                                      _avatarUrl == null
                                          ? Text(
                                            _initialsFromUser(_user),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          )
                                          : null,
                                ),
                                if (_uploading)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_user?['username'] ??
                                            _user?['name'] ??
                                            'Pengguna')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (_user?['email'] ?? '-').toString(),
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _changeAvatar,
                              icon: const Icon(
                                Icons.photo_camera_rounded,
                                size: 18,
                              ),
                              label: const Text('Ganti'),
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Form edit nama & email
                      Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ubah Informasi',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nama pengguna',
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Nama pengguna tidak boleh kosong'
                                            : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  final ok = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(v.trim());
                                  return ok ? null : 'Format email tidak valid';
                                },
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (!_hasChanges || _saving)
                                          ? null
                                          : _saveProfile,
                                  icon:
                                      _saving
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Icon(Icons.save_rounded),
                                  label: const Text('Simpan perubahan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.blue, // warna background
                                    foregroundColor:
                                        Colors.white, // warna teks & icon
                                    elevation: 0, // hilangin shadow
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side:
                                          BorderSide
                                              .none, // <- ini yang hilangin border hitam
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          // sebelumnya: onPressed: _logout,
                          onPressed:
                              _confirmLogout, // panggil dialog konfirmasi
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Keluar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  String _initialsFromUser(Map<String, dynamic>? u) {
    final name = (u?['username'] ?? u?['name'] ?? 'U').toString();
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
