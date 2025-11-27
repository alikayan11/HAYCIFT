// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// FlutterFire CLI ile üretilen dosyanız:
import 'firebase_options.dart';

/* =============================================================================
  UYGULAMA GİRİŞ NOKTASI
  ============================================================================= */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

/* =============================================================================
  UYGULAMA KAPSAYICI
  ============================================================================= */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Basit ortak tema/renk sabitleri
  static const Color primary = Color(0xFF00C853);
  static const Color accent = Color(0xFF29B6F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Staj Proje',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        chipTheme: const ChipThemeData(
          side: BorderSide(color: Colors.white24),
          selectedColor: Colors.white10,
          backgroundColor: Colors.white10,
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

/* =============================================================================
  GENEL AMAÇLI YARDIMCILAR
  ============================================================================= */

/// Basit boşluk helper’ı
Widget gap(double h) => SizedBox(height: h);

/// Ekranın ortasında dönen progress göstergesi
class Busy extends StatelessWidget {
  final String? label;
  const Busy({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            gap(12),
            Text(label!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// Sabit genişlikte sayfa gövdesi
class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const PageContainer({super.key, required this.child, this.maxWidth = 520});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}

/// Uyarı/boş durum bileşeni
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Colors.white70),
            gap(10),
            Text(title, style: const TextStyle(fontSize: 16)),
            if (subtitle != null) ...[
              gap(6),
              Text(subtitle!, style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}

/* =============================================================================
  AUTH: Login & Register
  ============================================================================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool obscure = true;

  Future<void> _login() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı profili bulunamadı.")),
        );
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final role = (data['role'] ?? '').toString();

      // ROL ROUTING
      Widget home;
      if (role == "Çiftçi") {
        home = const FarmerHomePage();
      } else if (role == "Hayvancı") {
        home = const BreederHomePage();
      } else if (role == "Ziraat Mühendisi") {
        home = const EngineerHomePage();
      } else if (role == "Veteriner") {
        home = const VetHomePage();
      } else if (role == "Admin") {
        home = const AdminHomePage(); // TabBar: Sorular | Profiller
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bilinmeyen rol: $role")));
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => home),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Giriş hatası: ${e.code}")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.agriculture, size: 56, color: MyApp.primary),
            gap(10),
            const Text(
              "Staj Proje",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            gap(24),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            gap(12),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: "Şifre",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            gap(18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : _login,
                icon:
                    busy
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.login),
                label: Text(busy ? "Giriş yapılıyor..." : "Giriş Yap"),
              ),
            ),
            gap(10),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              icon: const Icon(Icons.person_add_alt),
              label: const Text("Hesabın yok mu? Kayıt ol"),
            ),
          ],
        ),
      ),
    );
  }
}

/* -----------------------------------------------------------------------------
  REGISTER
----------------------------------------------------------------------------- */

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = "Çiftçi";
  bool busy = false;
  bool obscure = true;

  Future<void> _register() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            'email': emailController.text.trim(),
            'role': selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı. Giriş yapabilirsiniz.")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kayıt hatası: ${e.code}")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Giriş Ekranı",
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.login),
          ),
        ],
      ),
      body: PageContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.app_registration, size: 56, color: MyApp.accent),
            gap(14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            gap(12),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: "Şifre",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            gap(12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Rol Seçin",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              isExpanded: true,
              onChanged: (v) => setState(() => selectedRole = v!),
              items:
                  const [
                        "Çiftçi",
                        "Hayvancı",
                        "Ziraat Mühendisi",
                        "Veteriner",
                        "Admin",
                      ]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
            ),
            gap(18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : _register,
                icon:
                    busy
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check),
                label: Text(busy ? "Kaydediliyor..." : "Kayıt Ol"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================================================================
  PROFIL SAYFASI
  - Kullanıcı email ve rolünü görür.
  - Çıkış yapabilir.
  ============================================================================= */

/* ======================================================================
   COMMON: Profile Page (güncellendi)
   ====================================================================== */
/* =============================================================================
  KÜÇÜK YARDIMCI: StatCard (analiz kutusu)
============================================================================= */
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.greenAccent),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================================================================
  PROFIL SAYFASI – Kullanıcı bilgileri + Çiftçi analizleri
============================================================================= */
/* =============================================================================
  PROFIL SAYFASI – Kullanıcı bilgileri + (Çiftçi) üretim alanları + (Hayvancı) listeler
============================================================================= */

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DocumentReference<Map<String, dynamic>>? _userRef;
  Map<String, dynamic>? _data;

  String _email = "";
  String _role = "";

  // Çiftçi alanları
  List<Map<String, dynamic>> _treeTypes = []; // [{name, count}]
  List<Map<String, dynamic>> _cropProducts = []; // [{name, yieldKg}]
  DateTime? _lastPruning;
  DateTime? _lastHarvest;

  // Hayvancı alanları
  List<Map<String, dynamic>> _animals = []; // [{name, count}]
  List<Map<String, dynamic>> _barns = []; // [{name, capacity}]
  List<Map<String, dynamic>> _livestockProducts = []; // [{name, quantity}]

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    _userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    final snap = await _userRef!.get();
    _data = snap.data() ?? {};

    _email = (_data?['email'] ?? user.email ?? "").toString();
    _role = (_data?['role'] ?? "").toString();

    // Çiftçi
    _treeTypes = _parseListOfMap(
      _data?['treeTypes'],
      nameKey: 'name',
      numKey: 'count',
      intPreferred: true,
    );
    _cropProducts = _parseListOfMap(
      _data?['cropProducts'] ?? _data?['products'], // geri uyum
      nameKey: 'name',
      numKey: 'yieldKg',
      intPreferred: false,
    );

    final tp = _data?['lastPruning'];
    if (tp is Timestamp) _lastPruning = tp.toDate();
    final th = _data?['lastHarvest'];
    if (th is Timestamp) _lastHarvest = th.toDate();

    // Hayvancı
    _animals = _parseListOfMap(
      _data?['animals'],
      nameKey: 'name',
      numKey: 'count',
      intPreferred: true,
    );
    _barns = _parseListOfMap(
      _data?['barns'],
      nameKey: 'name',
      numKey: 'capacity',
      intPreferred: true,
    );
    _livestockProducts = _parseListOfMap(
      _data?['livestockProducts'] ?? _data?['products'], // geri uyum
      nameKey: 'name',
      numKey: 'quantity',
      intPreferred: false,
    );

    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _parseListOfMap(
    dynamic raw, {
    required String nameKey,
    required String numKey,
    required bool intPreferred,
  }) {
    final List<Map<String, dynamic>> out = [];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final name = (e[nameKey] ?? '').toString();
          num number;
          if (intPreferred) {
            number =
                e[numKey] is num
                    ? (e[numKey] as num).toInt()
                    : (int.tryParse('${e[numKey]}') ?? 0);
          } else {
            number =
                e[numKey] is num
                    ? (e[numKey] as num)
                    : (double.tryParse('${e[numKey]}') ?? 0.0);
          }
          out.add({'name': name, numKey: number});
        }
      }
    }
    return out;
  }

  String _fmtDate(DateTime? d) =>
      d == null
          ? "Seçilmedi"
          : "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (_saving || _userRef == null) return;
    setState(() => _saving = true);

    try {
      final update = <String, dynamic>{
        // Çiftçi
        'treeTypes': _treeTypes,
        'cropProducts': _cropProducts,
        'lastPruning':
            _lastPruning == null ? null : Timestamp.fromDate(_lastPruning!),
        'lastHarvest':
            _lastHarvest == null ? null : Timestamp.fromDate(_lastHarvest!),

        // Hayvancı
        'animals': _animals,
        'barns': _barns,
        'livestockProducts': _livestockProducts,

        'profileUpdatedAt': FieldValue.serverTimestamp(),
      };

      await _userRef!.set(update, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil kaydedildi ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kaydetme hatası: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // -----------------------------
  // Çiftçi: Ekle dialogları
  // -----------------------------
  Future<void> _addTreeDialog() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Ağaç Türü Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Ağaç Türü"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Ağaç Sayısı"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final count = int.tryParse(countCtrl.text.trim());
                  if (name.isEmpty || count == null) return;
                  setState(
                    () => _treeTypes.add({'name': name, 'count': count}),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check),
                label: const Text("Ekle"),
              ),
            ],
          ),
    );
  }

  Future<void> _addCropProductDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Ürün Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Ürün Adı"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: "Miktar (kg)"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final qty = double.tryParse(qtyCtrl.text.trim());
                  if (name.isEmpty || qty == null) return;
                  setState(
                    () => _cropProducts.add({'name': name, 'yieldKg': qty}),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check),
                label: const Text("Ekle"),
              ),
            ],
          ),
    );
  }

  // -----------------------------
  // Hayvancı: Ekle dialogları ✅ (YENİDEN EKLENDİ)
  // -----------------------------
  Future<void> _addAnimalDialog() async {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Hayvan Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Hayvan Türü"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Adet"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final count = int.tryParse(countCtrl.text.trim());
                  if (name.isEmpty || count == null) return;
                  setState(() => _animals.add({'name': name, 'count': count}));
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check),
                label: const Text("Ekle"),
              ),
            ],
          ),
    );
  }

  Future<void> _addBarnDialog() async {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Barınak Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Barınak Adı"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Kapasite"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final cap = int.tryParse(capCtrl.text.trim());
                  if (name.isEmpty || cap == null) return;
                  setState(() => _barns.add({'name': name, 'capacity': cap}));
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check),
                label: const Text("Ekle"),
              ),
            ],
          ),
    );
  }

  Future<void> _addLivestockProductDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Ürün Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ürün Adı (örn. Süt)",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: "Miktar"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final qty = double.tryParse(qtyCtrl.text.trim());
                  if (name.isEmpty || qty == null) return;
                  setState(
                    () =>
                        _livestockProducts.add({'name': name, 'quantity': qty}),
                  );
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.check),
                label: const Text("Ekle"),
              ),
            ],
          ),
    );
  }

  void _removeFrom(List<Map<String, dynamic>> list, int index) {
    setState(() => list.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon:
                _saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: const Text("Kaydet"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgileri
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(_email.isEmpty ? "Email yok" : _email),
                subtitle: Text("Rol: ${_role.isEmpty ? 'Belirsiz' : _role}"),
              ),
            ),
            const SizedBox(height: 12),

            // -----------------------------
            // Çiftçi Bloğu
            // -----------------------------
            if (_role == "Çiftçi") ...[
              const Text(
                "Ağaç Türleri",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Kayıtlı Türler")),
                  FilledButton.icon(
                    onPressed: _addTreeDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Ekle"),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children:
                      _treeTypes.isEmpty
                          ? [
                            const ListTile(
                              leading: Icon(Icons.forest_outlined),
                              title: Text("Kayıtlı ağaç yok"),
                            ),
                          ]
                          : _treeTypes.asMap().entries.map((e) {
                            return ListTile(
                              leading: const Icon(Icons.forest),
                              title: Text("${e.value['name']}"),
                              subtitle: Text("Sayı: ${e.value['count']}"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _removeFrom(_treeTypes, e.key),
                              ),
                            );
                          }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Hasat Edilen Ürünler",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Ürün Listesi")),
                  FilledButton.icon(
                    onPressed: _addCropProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Ekle"),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children:
                      _cropProducts.isEmpty
                          ? [
                            const ListTile(
                              leading: Icon(Icons.inventory_2_outlined),
                              title: Text("Kayıtlı ürün yok"),
                            ),
                          ]
                          : _cropProducts.asMap().entries.map((e) {
                            return ListTile(
                              leading: const Icon(Icons.inventory),
                              title: Text("${e.value['name']}"),
                              subtitle: Text(
                                "Miktar: ${e.value['yieldKg']} kg",
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed:
                                    () => _removeFrom(_cropProducts, e.key),
                              ),
                            );
                          }).toList(),
                ),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Son Budama")),
                  TextButton.icon(
                    onPressed:
                        () => _pickDate(
                          current: _lastPruning,
                          onPicked: (d) => setState(() => _lastPruning = d),
                        ),
                    icon: const Icon(Icons.event),
                    label: Text(_fmtDate(_lastPruning)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text("Son Hasat")),
                  TextButton.icon(
                    onPressed:
                        () => _pickDate(
                          current: _lastHarvest,
                          onPicked: (d) => setState(() => _lastHarvest = d),
                        ),
                    icon: const Icon(Icons.event_available),
                    label: Text(_fmtDate(_lastHarvest)),
                  ),
                ],
              ),
            ],

            // -----------------------------
            // Hayvancı Bloğu (Ekle butonları GERİ eklendi)
            // -----------------------------
            if (_role == "Hayvancı") ...[
              const Text(
                "Hayvanlar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Kayıtlı Hayvanlar")),
                  FilledButton.icon(
                    onPressed: _addAnimalDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Ekle"),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children:
                      _animals.isEmpty
                          ? [const ListTile(title: Text("Kayıtlı hayvan yok"))]
                          : _animals.asMap().entries.map((e) {
                            return ListTile(
                              leading: const Icon(Icons.pets),
                              title: Text("${e.value['name']}"),
                              subtitle: Text("Adet: ${e.value['count']}"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _removeFrom(_animals, e.key),
                              ),
                            );
                          }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Barınaklar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Kayıtlı Barınaklar")),
                  FilledButton.icon(
                    onPressed: _addBarnDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Ekle"),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children:
                      _barns.isEmpty
                          ? [const ListTile(title: Text("Kayıtlı barınak yok"))]
                          : _barns.asMap().entries.map((e) {
                            return ListTile(
                              leading: const Icon(Icons.home_work),
                              title: Text("${e.value['name']}"),
                              subtitle: Text(
                                "Kapasite: ${e.value['capacity']}",
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _removeFrom(_barns, e.key),
                              ),
                            );
                          }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Ürünler",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Expanded(child: Text("Ürün Listesi")),
                  FilledButton.icon(
                    onPressed: _addLivestockProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Ekle"),
                  ),
                ],
              ),
              Card(
                child: Column(
                  children:
                      _livestockProducts.isEmpty
                          ? [const ListTile(title: Text("Kayıtlı ürün yok"))]
                          : _livestockProducts.asMap().entries.map((e) {
                            return ListTile(
                              leading: const Icon(Icons.inventory),
                              title: Text("${e.value['name']}"),
                              subtitle: Text("Miktar: ${e.value['quantity']}"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed:
                                    () =>
                                        _removeFrom(_livestockProducts, e.key),
                              ),
                            );
                          }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Çıkış Yap"),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================================================================
  SORU SORMA DİYALOĞU (Kategori Seçimi ile)
  - askerRole: "Çiftçi" | "Hayvancı"
  - Firestore: /questions (userId, role, category, content, createdAt)
  ============================================================================= */

Future<void> showAskDialog({
  required BuildContext context,
  required String askerRole,
}) async {
  final controller = TextEditingController();
  String category = askerRole == 'Çiftçi' ? "Gübreleme" : "Yem";
  bool saving = false;

  await showDialog(
    context: context,
    barrierDismissible: !saving,
    builder: (ctx) {
      void setLocal(void Function() fn) {
        fn();
        (ctx as Element).markNeedsBuild();
      }

      return AlertDialog(
        title: const Text("Soru Sor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: "Sorunuzu yazın...",
                border: OutlineInputBorder(),
              ),
            ),
            gap(12),
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 18),
                gap(6),
                const Text("Kategori"),
              ],
            ),
            gap(6),
            DropdownButtonFormField<String>(
              value: category,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Kategori seçin",
              ),
              onChanged:
                  saving
                      ? null
                      : (v) => setLocal(() => category = v ?? category),
              items:
                  (askerRole == 'Çiftçi'
                          ? const ["Gübreleme", "Hastalık", "Bakım", "Sulama"]
                          : const ["Yem", "Bakım", "Hastalık", "Barınak"])
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton.icon(
            onPressed:
                saving
                    ? null
                    : () async {
                      final content = controller.text.trim();
                      if (content.isEmpty) return;
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      setLocal(() => saving = true);
                      try {
                        await FirebaseFirestore.instance
                            .collection('questions')
                            .add({
                              'userId': user.uid,
                              'role': askerRole,
                              'category': category,
                              'content': content,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (context.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Soru kaydedildi ✅")),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                        }
                      } finally {
                        setLocal(() => saving = false);
                      }
                    },
            icon:
                saving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save_outlined),
            label: Text(saving ? "Kaydediliyor..." : "Kaydet"),
          ),
        ],
      );
    },
  );
}

/* =============================================================================
  SAHİBİNİN SORULARI + CEVAPLARI (Çiftçi/Hayvancı)
  - Kendi sorularını ve altındaki answers altkoleksiyonunu gösterir.
  - Query: where('userId', isEqualTo: uid).orderBy('createdAt', desc)
  - NOT: where + orderBy için composite index gerekir (ekledik).
  ============================================================================= */

class MyQuestionsList extends StatelessWidget {
  const MyQuestionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: "Giriş yapılmadı",
        subtitle: "Sorularınızı görebilmek için lütfen giriş yapın.",
      );
    }

    final query = FirebaseFirestore.instance
        .collection('questions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Busy(label: "Sorular yükleniyor...");
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: "Bir hata oluştu",
            subtitle: "${snap.error}",
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: "Henüz soru yok",
            subtitle: "Yeni bir soru sormak için alttaki + butonunu kullanın.",
          );
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>? ?? {};
            final content = (data['content'] ?? '').toString();
            final role = (data['role'] ?? '').toString();
            final category = (data['category'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline),
                title: Text(content),
                subtitle: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text("Rol: $role")),
                    if (category.isNotEmpty)
                      Chip(label: Text("Kategori: $category")),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.forum_outlined, size: 18),
                        SizedBox(width: 6),
                        Text("Cevaplar"),
                      ],
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        d.reference
                            .collection('answers')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, ansSnap) {
                      if (ansSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: LinearProgressIndicator(),
                        );
                      }
                      if (ansSnap.hasError) {
                        return ListTile(
                          leading: const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          title: Text("Cevaplar yüklenemedi: ${ansSnap.error}"),
                        );
                      }
                      if (!ansSnap.hasData || ansSnap.data!.docs.isEmpty) {
                        return const ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text("Henüz cevap yok"),
                        );
                      }
                      final answers = ansSnap.data!.docs;
                      return Column(
                        children:
                            answers.map((a) {
                              final adata =
                                  a.data() as Map<String, dynamic>? ?? {};
                              final acontent =
                                  (adata['content'] ?? '').toString();
                              final arole = (adata['role'] ?? '').toString();
                              return ListTile(
                                leading: const Icon(Icons.reply),
                                title: Text(acontent),
                                subtitle: Text("Rol: $arole"),
                              );
                            }).toList(),
                      );
                    },
                  ),
                  gap(10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/* =============================================================================
  ÇİFTÇİ ANASAYFA
  - Kendi sorularını + cevaplarını görür
  - + düğmesi ile soru sorar (kategori ile)
  ============================================================================= */

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this); // Özet + Sorular
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Çiftçi"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Özet"),
            Tab(icon: Icon(Icons.question_answer), text: "Sorularım"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [FarmerDashboardView(), MyQuestionsList()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) {
          return _tab.index == 1
              ? FloatingActionButton.extended(
                onPressed:
                    () => showAskDialog(context: context, askerRole: 'Çiftçi'),
                icon: const Icon(Icons.add),
                label: const Text("Soru Sor"),
              )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

// Çiftçi Dashboard
class FarmerDashboardView extends StatelessWidget {
  const FarmerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: "Giriş yapılmadı",
        subtitle: "Bilgilerinizi görmek için giriş yapın.",
      );
    }

    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Busy(label: "Yükleniyor...");
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};

        final treeTypes = (data['treeTypes'] as List?) ?? [];
        final products = (data['cropProducts'] as List?) ?? [];

        final lastPruning = (data['lastPruning'] as Timestamp?)?.toDate();
        final lastHarvest = (data['lastHarvest'] as Timestamp?)?.toDate();

        final totalTrees = treeTypes.fold<int>(
          0,
          (sum, t) => sum + ((t['count'] ?? 0) as num).toInt(),
        );
        final totalYield = products.fold<num>(
          0,
          (sum, p) => sum + ((p['yieldKg'] ?? 0) as num),
        );

        // 🎨 renk paleti
        final barColors = [
          Colors.greenAccent,
          Colors.blueAccent,
          Colors.orangeAccent,
          Colors.purpleAccent,
          Colors.tealAccent,
          Colors.redAccent,
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Özet kartlar
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Toplam Ağaç",
                    value: "$totalTrees",
                    icon: Icons.forest,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: "Toplam Hasat (kg)",
                    value: "$totalYield",
                    icon: Icons.scale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ağaç Türleri
            const Text(
              "Ağaç Türleri",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Card(
              child: Column(
                children:
                    treeTypes.isEmpty
                        ? [const ListTile(title: Text("Kayıtlı ağaç türü yok"))]
                        : treeTypes.map((t) {
                          return ListTile(
                            leading: const Icon(Icons.eco),
                            title: Text("${t['name']}"),
                            subtitle: Text("Sayı: ${t['count']}"),
                          );
                        }).toList(),
              ),
            ),

            // Pie Chart: Ağaç türü dağılımı
            if (treeTypes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Ağaç Türü Dağılımı",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: [
                      for (final t in treeTypes)
                        PieChartSectionData(
                          title: "${t['name']}",
                          value: ((t['count'] ?? 0) as num).toDouble(),
                          radius: 80,
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Ürünler listesi
            const Text(
              "Ürünler",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Card(
              child: Column(
                children:
                    products.isEmpty
                        ? [const ListTile(title: Text("Kayıtlı ürün yok"))]
                        : products.map((p) {
                          return ListTile(
                            leading: const Icon(Icons.inventory),
                            title: Text("${p['name']}"),
                            subtitle: Text("Miktar: ${p['yieldKg']} kg"),
                          );
                        }).toList(),
              ),
            ),

            // Bar Chart: Ürün miktarları
            if (products.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Ürünlere Göre Hasat Miktarı",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= products.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              products[index]['name'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < products.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY:
                                  ((products[i]['yieldKg'] ?? 0) as num)
                                      .toDouble(),
                              width: 18,
                              color: barColors[i % barColors.length], // 🎨 renk
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Tarihler
            const Text(
              "Tarih Bilgileri",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text("Son Budama"),
                    subtitle: Text(
                      lastPruning == null
                          ? "Kayıtlı değil"
                          : "${lastPruning.year}-${lastPruning.month}-${lastPruning.day}",
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_available),
                    title: const Text("Son Hasat"),
                    subtitle: Text(
                      lastHarvest == null
                          ? "Kayıtlı değil"
                          : "${lastHarvest.year}-${lastHarvest.month}-${lastHarvest.day}",
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/* =============================================================================
  HAYVANCI ANASAYFA
  - Kendi sorularını + cevaplarını görür
  - + düğmesi ile soru sorar (kategori ile)
  ============================================================================= */
// ======================
// HAYVANCI ANASAYFA
// ======================
class BreederHomePage extends StatefulWidget {
  const BreederHomePage({super.key});

  @override
  State<BreederHomePage> createState() => _BreederHomePageState();
}

class _BreederHomePageState extends State<BreederHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this); // ✅ Özet + Sorular
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hayvancı"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Özet"),
            Tab(icon: Icon(Icons.question_answer), text: "Sorularım"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [BreederDashboardView(), MyQuestionsList()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (context, _) {
          return _tab.index == 1
              ? FloatingActionButton.extended(
                onPressed:
                    () =>
                        showAskDialog(context: context, askerRole: 'Hayvancı'),
                icon: const Icon(Icons.add),
                label: const Text("Soru Sor"),
              )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

// ======================
// HAYVANCI DASHBOARD
// ======================
class BreederDashboardView extends StatelessWidget {
  const BreederDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: "Giriş yapılmadı",
        subtitle: "Bilgilerinizi görmek için giriş yapın.",
      );
    }

    final docRef = FirebaseFirestore.instance.collection("users").doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Busy(label: "Yükleniyor...");
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final animals = (data['animals'] as List?) ?? [];
        final barns = (data['barns'] as List?) ?? [];
        final products = (data['products'] as List?) ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Hayvan",
                    value:
                        "${animals.fold<int>(0, (p, e) => p + ((e['count'] ?? 0) as num).toInt())}",
                    icon: Icons.pets,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: "Bakım Evleri",
                    value: "${barns.length}",
                    icon: Icons.home_work,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (products.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text("Ürünler"),
                  subtitle: Text(
                    products
                        .map(
                          (p) =>
                              "${p['name']} (${(p['quantity'] ?? 0).toString()})",
                        )
                        .join(", "),
                  ),
                ),
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inventory_2_outlined),
                  title: Text("Ürün kaydı yok"),
                ),
              ),
          ],
        );
      },
    );
  }
}

/* =============================================================================
  ZİRAAT MÜHENDİSİ
  - Çiftçi sorularını listeler
  - Her soruya "Cevap Yaz" ile altkoleksiyona cevap ekler
  ============================================================================= */

class EngineerHomePage extends StatelessWidget {
  const EngineerHomePage({super.key});

  Future<void> _writeAnswer(
    BuildContext context,
    DocumentReference questionRef,
  ) async {
    final controller = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) {
        void setLocal(void Function() fn) {
          fn();
          (ctx as Element).markNeedsBuild();
        }

        return AlertDialog(
          title: const Text("Cevap Yaz"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: "Cevabınızı yazın...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton.icon(
              onPressed:
                  saving
                      ? null
                      : () async {
                        final content = controller.text.trim();
                        if (content.isEmpty) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        setLocal(() => saving = true);
                        try {
                          await questionRef.collection('answers').add({
                            'userId': user.uid,
                            'role': 'Ziraat Mühendisi',
                            'content': content,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Cevap gönderildi ✅"),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                          }
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
              icon:
                  saving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send_outlined),
              label: Text(saving ? "Gönderiliyor..." : "Kaydet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('questions')
        .where('role', isEqualTo: 'Çiftçi')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ziraat Mühendisi — Çiftçi Soruları"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Busy(label: "Sorular yükleniyor...");
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: "Hata",
              subtitle: "${snap.error}",
            );
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: "Soru yok",
            );
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>? ?? {};
              final content = (m['content'] ?? '').toString();
              final category = (m['category'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.question_answer,
                    color: MyApp.primary,
                  ),
                  title: Text(content),
                  subtitle:
                      category.isEmpty
                          ? null
                          : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text("Kategori: $category")),
                              ],
                            ),
                          ),
                  trailing: ElevatedButton(
                    onPressed: () => _writeAnswer(context, d.reference),
                    child: const Text("Cevap Yaz"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* =============================================================================
  VETERİNER
  - Hayvancı sorularını listeler
  - Her soruya "Cevap Yaz" ile altkoleksiyona cevap ekler
  ============================================================================= */

class VetHomePage extends StatelessWidget {
  const VetHomePage({super.key});

  Future<void> _writeAnswer(
    BuildContext context,
    DocumentReference questionRef,
  ) async {
    final controller = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) {
        void setLocal(void Function() fn) {
          fn();
          (ctx as Element).markNeedsBuild();
        }

        return AlertDialog(
          title: const Text("Cevap Yaz"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: "Cevabınızı yazın...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton.icon(
              onPressed:
                  saving
                      ? null
                      : () async {
                        final content = controller.text.trim();
                        if (content.isEmpty) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        setLocal(() => saving = true);
                        try {
                          await questionRef.collection('answers').add({
                            'userId': user.uid,
                            'role': 'Veteriner',
                            'content': content,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Cevap gönderildi ✅"),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                          }
                        } finally {
                          setLocal(() => saving = false);
                        }
                      },
              icon:
                  saving
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send_outlined),
              label: Text(saving ? "Gönderiliyor..." : "Kaydet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('questions')
        .where('role', isEqualTo: 'Hayvancı')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Veteriner — Hayvancı Soruları"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Busy(label: "Sorular yükleniyor...");
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: "Hata",
              subtitle: "${snap.error}",
            );
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: "Soru yok",
            );
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data() as Map<String, dynamic>? ?? {};
              final content = (m['content'] ?? '').toString();
              final category = (m['category'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.question_answer,
                    color: MyApp.accent,
                  ),
                  title: Text(content),
                  subtitle:
                      category.isEmpty
                          ? null
                          : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                Chip(label: Text("Kategori: $category")),
                              ],
                            ),
                          ),
                  trailing: ElevatedButton(
                    onPressed: () => _writeAnswer(context, d.reference),
                    child: const Text("Cevap Yaz"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* =============================================================================
  ADMIN PANELİ
  - Tüm soruları ve cevapları listeler
  - Filtreler: Rol, Kategori
  - Silme: Soru + (altındaki tüm cevaplar), Cevap tekil
  ============================================================================= */

class AdminQuestionsPage extends StatefulWidget {
  const AdminQuestionsPage({super.key});

  @override
  State<AdminQuestionsPage> createState() => _AdminQuestionsPageState();
}

class _AdminQuestionsPageState extends State<AdminQuestionsPage> {
  String? roleFilter; // "Çiftçi" | "Hayvancı" | null
  String? categoryFilter; // kategori adı | null
  bool deleting = false;

  Future<void> _deleteQuestion(DocumentReference ref) async {
    if (deleting) return;
    setState(() => deleting = true);
    try {
      final answers = await ref.collection('answers').get();
      for (final doc in answers.docs) {
        await doc.reference.delete();
      }
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Soru silindi ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> _deleteAnswer(DocumentReference ref) async {
    if (deleting) return;
    setState(() => deleting = true);
    try {
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cevap silindi ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Query _buildQuery() {
    Query q = FirebaseFirestore.instance
        .collection('questions')
        .orderBy('createdAt', descending: true);

    if (roleFilter != null && roleFilter!.isNotEmpty) {
      q = q.where('role', isEqualTo: roleFilter);
    }
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      q = q.where('category', isEqualTo: categoryFilter);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final roleChips = ["Çiftçi", "Hayvancı"];
    final categoryChips = [
      "Gübreleme",
      "Hastalık",
      "Bakım",
      "Sulama",
      "Yem",
      "Barınak",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli — Tüm Sorular & Cevaplar"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre Alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text("Rol:"),
                ChoiceChip(
                  label: const Text("Tümü"),
                  selected: roleFilter == null,
                  onSelected: (_) => setState(() => roleFilter = null),
                ),
                ...roleChips.map(
                  (r) => ChoiceChip(
                    label: Text(r),
                    selected: roleFilter == r,
                    onSelected: (_) => setState(() => roleFilter = r),
                  ),
                ),
                const SizedBox(width: 16),
                const Text("Kategori:"),
                ChoiceChip(
                  label: const Text("Tümü"),
                  selected: categoryFilter == null,
                  onSelected: (_) => setState(() => categoryFilter = null),
                ),
                ...categoryChips.map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    selected: categoryFilter == c,
                    onSelected: (_) => setState(() => categoryFilter = c),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18),
          // Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Busy(label: "Kayıtlar yükleniyor...");
                }
                if (snap.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: "Hata",
                    subtitle: "${snap.error}",
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: "Kayıtlı soru yok",
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final m = d.data() as Map<String, dynamic>? ?? {};
                    final content = (m['content'] ?? '').toString();
                    final role = (m['role'] ?? '').toString();
                    final category = (m['category'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: const Icon(Icons.help_outline),
                        title: Text(content),
                        subtitle: Wrap(
                          spacing: 8,
                          children: [
                            Chip(label: Text("Rol: $role")),
                            if (category.isNotEmpty)
                              Chip(label: Text("Kategori: $category")),
                          ],
                        ),
                        trailing: IconButton(
                          tooltip: deleting ? "Siliniyor..." : "Soruyu Sil",
                          onPressed:
                              deleting
                                  ? null
                                  : () => _deleteQuestion(d.reference),
                          icon: Icon(
                            deleting
                                ? Icons.hourglass_top_rounded
                                : Icons.delete_forever,
                            color: Colors.redAccent,
                          ),
                        ),
                        children: [
                          // Cevaplar (Admin kurala göre hepsini görebilir)
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                d.reference
                                    .collection('answers')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                            builder: (context, ansSnap) {
                              if (ansSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: LinearProgressIndicator(),
                                );
                              }
                              if (ansSnap.hasError) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    "Cevaplar yüklenemedi: ${ansSnap.error}",
                                  ),
                                );
                              }
                              if (!ansSnap.hasData ||
                                  ansSnap.data!.docs.isEmpty) {
                                return const ListTile(
                                  leading: Icon(Icons.info_outline),
                                  title: Text("Bu soruya cevap yok"),
                                );
                              }
                              final answers = ansSnap.data!.docs;
                              return Column(
                                children:
                                    answers.map((a) {
                                      final ad =
                                          a.data() as Map<String, dynamic>? ??
                                          {};
                                      final acontent =
                                          (ad['content'] ?? '').toString();
                                      final arole =
                                          (ad['role'] ?? '').toString();
                                      return ListTile(
                                        leading: const Icon(Icons.reply),
                                        title: Text(acontent),
                                        subtitle: Text("Rol: $arole"),
                                        trailing: IconButton(
                                          tooltip:
                                              deleting
                                                  ? "Siliniyor..."
                                                  : "Cevabı Sil",
                                          onPressed:
                                              deleting
                                                  ? null
                                                  : () => _deleteAnswer(
                                                    a.reference,
                                                  ),
                                          icon: Icon(
                                            deleting
                                                ? Icons.hourglass_top_rounded
                                                : Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                          gap(8),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProfilesPage extends StatelessWidget {
  const AdminProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy(
          'createdAt',
          descending: true,
        ); // kayıt sırasında alanı yazıyoruz

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Busy(label: "Kullanıcılar yükleniyor...");
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: "Hata",
            subtitle: "${snap.error}",
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const EmptyState(
            icon: Icons.group_outlined,
            title: "Kullanıcı yok",
          );
        }

        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final m = d.data() as Map<String, dynamic>? ?? {};
            final email = (m['email'] ?? '').toString();
            final role = (m['role'] ?? '').toString();

            // çiftçi alanları (varsa)
            final treeType = (m['treeType'] ?? '').toString();
            final treeCount = (m['treeCount'] ?? '').toString();
            final product = (m['productName'] ?? '').toString();
            final lastYield = (m['lastYieldKg'] ?? '').toString();

            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(email.isEmpty ? "(email yok)" : email),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Rol: ${role.isEmpty ? '-' : role}"),
                    if (treeType.isNotEmpty)
                      Text(
                        "Ürün: $treeType (${treeCount.isEmpty ? '-' : treeCount} ağaç)",
                      ),
                    if (product.isNotEmpty || lastYield.isNotEmpty)
                      Text(
                        "Son Hasat: ${product.isEmpty ? '-' : product} - ${lastYield.isEmpty ? '-' : lastYield} kg",
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// =======================
// 1) ADMIN HOME (TabBar)
// =======================
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 3,
      vsync: this,
    ); // Dashboard + Sorular + Profiller
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: "Dashboard"),
            Tab(icon: Icon(Icons.question_answer), text: "Sorular"),
            Tab(icon: Icon(Icons.people), text: "Profiller"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          AdminDashboardView(),
          AdminQuestionsView(),
          AdminUsersView(),
        ],
      ),
    );
  }
}

// ========================================
// 2) ADMIN QUESTIONS VIEW
// ========================================
class AdminQuestionsView extends StatefulWidget {
  const AdminQuestionsView({super.key});

  @override
  State<AdminQuestionsView> createState() => _AdminQuestionsViewState();
}

class _AdminQuestionsViewState extends State<AdminQuestionsView> {
  String? roleFilter;
  String? categoryFilter;
  bool deleting = false;

  Future<void> _deleteQuestion(DocumentReference ref) async {
    if (deleting) return;
    setState(() => deleting = true);
    try {
      final answers = await ref.collection('answers').get();
      for (final doc in answers.docs) {
        await doc.reference.delete();
      }
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Soru silindi ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> _deleteAnswer(DocumentReference ref) async {
    if (deleting) return;
    setState(() => deleting = true);
    try {
      await ref.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cevap silindi ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Query _buildQuery() {
    Query q = FirebaseFirestore.instance
        .collection('questions')
        .orderBy('createdAt', descending: true);

    if (roleFilter != null && roleFilter!.isNotEmpty) {
      q = q.where('role', isEqualTo: roleFilter);
    }
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      q = q.where('category', isEqualTo: categoryFilter);
    }
    return q;
  }

  @override
  Widget build(BuildContext context) {
    final roleChips = ["Çiftçi", "Hayvancı"];
    final categoryChips = [
      "Gübreleme",
      "Hastalık",
      "Bakım",
      "Sulama",
      "Yem",
      "Barınak",
    ];

    return Column(
      children: [
        // Filtre Alanı
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Rol:"),
              ChoiceChip(
                label: const Text("Tümü"),
                selected: roleFilter == null,
                onSelected: (_) => setState(() => roleFilter = null),
              ),
              ...roleChips.map(
                (r) => ChoiceChip(
                  label: Text(r),
                  selected: roleFilter == r,
                  onSelected: (_) => setState(() => roleFilter = r),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Kategori:"),
              ChoiceChip(
                label: const Text("Tümü"),
                selected: categoryFilter == null,
                onSelected: (_) => setState(() => categoryFilter = null),
              ),
              ...categoryChips.map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: categoryFilter == c,
                  onSelected: (_) => setState(() => categoryFilter = c),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 18),

        // Liste
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery().snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Busy(label: "Kayıtlar yükleniyor...");
              }
              if (snap.hasError) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: "Hata",
                  subtitle: "${snap.error}",
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: "Kayıtlı soru yok",
                );
              }

              final docs = snap.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final m = d.data() as Map<String, dynamic>? ?? {};
                  final content = (m['content'] ?? '').toString();
                  final role = (m['role'] ?? '').toString();
                  final category = (m['category'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(content),
                      subtitle: Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text("Rol: $role")),
                          if (category.isNotEmpty)
                            Chip(label: Text("Kategori: $category")),
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: deleting ? "Siliniyor..." : "Soruyu Sil",
                        onPressed:
                            deleting
                                ? null
                                : () => _deleteQuestion(d.reference),
                        icon: Icon(
                          deleting
                              ? Icons.hourglass_top_rounded
                              : Icons.delete_forever,
                          color: Colors.redAccent,
                        ),
                      ),
                      children: [
                        // Cevaplar
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              d.reference
                                  .collection('answers')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                          builder: (context, ansSnap) {
                            if (ansSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8),
                                child: LinearProgressIndicator(),
                              );
                            }
                            if (ansSnap.hasError) {
                              return ListTile(
                                leading: const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  "Cevaplar yüklenemedi: ${ansSnap.error}",
                                ),
                              );
                            }
                            if (!ansSnap.hasData ||
                                ansSnap.data!.docs.isEmpty) {
                              return const ListTile(
                                leading: Icon(Icons.info_outline),
                                title: Text("Bu soruya cevap yok"),
                              );
                            }
                            final answers = ansSnap.data!.docs;
                            return Column(
                              children:
                                  answers.map((a) {
                                    final ad =
                                        a.data() as Map<String, dynamic>? ?? {};
                                    final acontent =
                                        (ad['content'] ?? '').toString();
                                    final arole = (ad['role'] ?? '').toString();
                                    return ListTile(
                                      leading: const Icon(Icons.reply),
                                      title: Text(acontent),
                                      subtitle: Text("Rol: $arole"),
                                      trailing: IconButton(
                                        tooltip:
                                            deleting
                                                ? "Siliniyor..."
                                                : "Cevabı Sil",
                                        onPressed:
                                            deleting
                                                ? null
                                                : () =>
                                                    _deleteAnswer(a.reference),
                                        icon: Icon(
                                          deleting
                                              ? Icons.hourglass_top_rounded
                                              : Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
                        gap(8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ========================================
// 3) ADMIN USERS VIEW (PROFİL LİSTESİ)
// ========================================
// ========================================
// 3) ADMIN USERS VIEW (GÜNCELLENMİŞ)
//  - users koleksiyonunu listeler
//  - En üstte toplam kullanıcı sayısı gösterir
//  - Admin istediği kullanıcıyı silebilir
// ========================================
// ========================================
// 3) ADMIN USERS VIEW (YENİ PROFİL LİSTESİ)
//  - users koleksiyonunu listeler
//  - Çiftçi'lerde (varsa) üretim özetini gösterir
//  - Admin kullanıcı silebilir (onay ile)
// ========================================
class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  Future<void> _deleteUser(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text("Kullanıcıyı Sil"),
            content: const Text("Bu kullanıcıyı silmek istediğine emin misin?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Sil"),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kullanıcı silindi ✅")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('users');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Busy(label: "Kullanıcılar yükleniyor...");
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: "Hata",
            subtitle: "${snap.error}",
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const EmptyState(
            icon: Icons.person_off,
            title: "Kullanıcı bulunamadı",
          );
        }

        final users = snap.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Toplam Kullanıcı: ${users.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final doc = users[i];
                  final u = doc.data() as Map<String, dynamic>? ?? {};
                  final email = (u['email'] ?? '').toString();
                  final role = (u['role'] ?? '').toString();

                  // Çiftçi üretim alanları
                  final treeType = (u['treeType'] ?? '').toString();
                  final treeCount = (u['treeCount'] ?? '').toString();
                  final productName = (u['productName'] ?? '').toString();
                  final lastYieldKg = (u['lastYieldKg'] ?? '').toString();

                  final lastPruning =
                      u['lastPruning'] is Timestamp
                          ? u['lastPruning'] as Timestamp
                          : null;
                  final lastHarvest =
                      u['lastHarvest'] is Timestamp
                          ? u['lastHarvest'] as Timestamp
                          : null;

                  String fmt(Timestamp? t) {
                    if (t == null) return "-";
                    final d = t.toDate();
                    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                  }

                  // Hayvancı üretim alanları
                  final animals = (u['animals'] as List?) ?? [];
                  final barns = (u['barns'] as List?) ?? [];
                  final products = (u['products'] as List?) ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(email.isEmpty ? "(emailsiz)" : email),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rol: ${role.isEmpty ? '-' : role}"),

                          // Çiftçi gösterimi
                          if (role == "Çiftçi") ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (treeType.isNotEmpty)
                                  Chip(label: Text("Ürün: $treeType")),
                                if (treeCount.isNotEmpty)
                                  Chip(label: Text("Ağaç: $treeCount")),
                                if (productName.isNotEmpty)
                                  Chip(label: Text("Hasat: $productName")),
                                if (lastYieldKg.isNotEmpty)
                                  Chip(label: Text("Miktar: $lastYieldKg kg")),
                                if (lastPruning != null)
                                  Chip(
                                    label: Text("Budama: ${fmt(lastPruning)}"),
                                  ),
                                if (lastHarvest != null)
                                  Chip(
                                    label: Text("Hasat: ${fmt(lastHarvest)}"),
                                  ),
                              ],
                            ),
                          ],

                          // Hayvancı gösterimi
                          if (role == "Hayvancı") ...[
                            const SizedBox(height: 6),
                            const Text(
                              "Hayvanlar:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (animals.isEmpty) const Text("- Kayıt yok"),
                            for (var a in animals)
                              Text("${a['name']} (${a['count']} adet)"),

                            const SizedBox(height: 6),
                            const Text(
                              "Barınaklar:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (barns.isEmpty) const Text("- Kayıt yok"),
                            for (var b in barns)
                              Text("${b['name']} (Kapasite: ${b['capacity']})"),

                            const SizedBox(height: 6),
                            const Text(
                              "Ürünler:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (products.isEmpty) const Text("- Kayıt yok"),
                            for (var p in products)
                              Text("${p['name']} (${p['amount']})"),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        tooltip: "Kullanıcıyı Sil",
                        onPressed: () => _deleteUser(context, doc.id),
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final usersCol = FirebaseFirestore.instance.collection("users");
    final questionsCol = FirebaseFirestore.instance.collection("questions");

    return FutureBuilder(
      future: Future.wait([usersCol.get(), questionsCol.get()]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Busy(label: "Dashboard yükleniyor...");
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: "Hata",
            subtitle: "${snap.error}",
          );
        }

        final users = (snap.data?[0] as QuerySnapshot).docs;
        final questions = (snap.data?[1] as QuerySnapshot).docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Kullanıcılar",
                    value: "${users.length}",
                    icon: Icons.people,
                  ),
                ),
                Expanded(
                  child: StatCard(
                    title: "Sorular",
                    value: "${questions.length}",
                    icon: Icons.question_answer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Son Eklenen Sorular",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...questions.take(5).map((q) {
              final data = q.data() as Map<String, dynamic>? ?? {};
              final content = (data['content'] ?? '').toString();
              final role = (data['role'] ?? '').toString();
              final category = (data['category'] ?? '').toString();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(content),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text("Rol: $role")),
                      if (category.isNotEmpty)
                        Chip(label: Text("Kategori: $category")),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
// ilk deneme yorumu