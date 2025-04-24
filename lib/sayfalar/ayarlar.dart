import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Ayarlar {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String password;
  final bool bildirimAktif;
  final String dilSecenegi;
  final String tema;

  Ayarlar({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
    required this.bildirimAktif,
    required this.dilSecenegi,
    required this.tema,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'password': password,
      'bildirimAktif': bildirimAktif,
      'dilSecenegi': dilSecenegi,
      'tema': tema,
    };
  }

  factory Ayarlar.fromMap(Map<String, dynamic> map) {
    return Ayarlar(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      password: map['password'] ?? '',
      bildirimAktif: map['bildirimAktif'] ?? false,
      dilSecenegi: map['dilSecenegi'] ?? 'tr',
      tema: map['tema'] ?? 'light',
    );
  }

  Ayarlar copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? password,
    bool? bildirimAktif,
    String? dilSecenegi,
    String? tema,
  }) {
    return Ayarlar(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      password: password ?? this.password,
      bildirimAktif: bildirimAktif ?? this.bildirimAktif,
      dilSecenegi: dilSecenegi ?? this.dilSecenegi,
      tema: tema ?? this.tema,
    );
  }
}

class AyarlarPage extends StatefulWidget {
  final Ayarlar ayarlar;

  const AyarlarPage({Key? key, required this.ayarlar}) : super(key: key);

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late bool _bildirimAktif;
  late String _dilSecenegi;
  late String _tema;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ayarlar.name);
    _emailController = TextEditingController(text: widget.ayarlar.email);
    _phoneController = TextEditingController(text: widget.ayarlar.phone);
    _bildirimAktif = widget.ayarlar.bildirimAktif;
    _dilSecenegi = widget.ayarlar.dilSecenegi;
    _tema = widget.ayarlar.tema;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.golosText()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil Bilgileri',
              style: GoogleFonts.golosText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'İsim',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Uygulama Ayarları',
              style: GoogleFonts.golosText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bildirimler'),
                      value: _bildirimAktif,
                      secondary: const Icon(Icons.notifications),
                      onChanged: (value) {
                        setState(() {
                          _bildirimAktif = value;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Dil Seçeneği'),
                      trailing: DropdownButton<String>(
                        value: _dilSecenegi,
                        items:
                            ['tr', 'en'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value == 'tr' ? 'Türkçe' : 'English',
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _dilSecenegi = newValue!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Tema'),
                      trailing: DropdownButton<String>(
                        value: _tema,
                        items:
                            ['light', 'dark'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'light' ? 'Açık' : 'Koyu'),
                              );
                            }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _tema = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ayarlar kaydedildi')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
