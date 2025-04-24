import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';  // Google Fonts kütüphanesini içe aktarıyoruz.

// Tema adında bir sınıf tanımlanıyor.
// Bu sınıf, uygulamada kullanılacak tema ile ilgili özellikleri ve metotları içerir.
class Tema {
  // inputDec metodu, bir InputDecoration döner.
  // Bu metot, TextField veya TextFormField gibi widget'ların dekorasyonunu özelleştirmek için kullanılır.
  // hinText: Input alanında gösterilecek ipucu metni.
  // icon: Input alanının sol tarafında gösterilecek ikon.
  InputDecoration inputDec(String hinText, IconData icon) {
    return InputDecoration(
      border: InputBorder.none, // Input alanının kenarlığı olmamasını sağlar.
      hintText: hinText, // Input alanında gösterilecek ipucu metni.
      hintStyle: TextStyle(color: Colors.grey), // İpucu metninin stilini belirler (gri renk).
      prefixIcon: Icon(
        icon, // İkonu belirler.
        color: Colors.grey, // İkonun rengini belirler (gri renk).
      ),
    );
  }

  // inputBoxDec metodu, bir BoxDecoration döner.
  // Bu metot, bir Container veya benzeri widget'ların dekorasyonunu özelleştirmek için kullanılır.
  // Bu dekorasyon, genellikle bir input alanını saran bir kutu oluşturmak için kullanılır.
  BoxDecoration inputBoxDec() {
    return BoxDecoration(
      color: Colors.white, // Kutunun arkaplan rengi (beyaz).
      borderRadius: BorderRadius.circular(10), // Kutunun köşelerini yuvarlar (10 piksel yarıçapında).
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5), // Gölge rengi (gri ve %50 opaklık).
          blurRadius: 5, // Gölgenin bulanıklık yarıçapı.
          offset: Offset(0, 3), // Gölgenin konumu (yatayda 0, dikeyde 3 piksel).
        )
      ],
    );
  }
}

// GirisSayfasi adlı StatefulWidget oluşturuluyor.
class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({Key? key}) : super(key: key);

  @override
  _GirisSayfasiState createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  // Tema sınıfından bir nesne oluşturuluyor.
  final Tema tema = Tema();

  // TextEditingController'lar oluşturuluyor.
  // Bu controller'lar, text field'lardaki veriyi okumak ve yönetmek için kullanılır.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controller'ları temizlemek için dispose metodu kullanılıyor.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Giriş Sayfası"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // E-posta giriş alanı
            Container(
              decoration: tema.inputBoxDec(),
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                controller: _emailController, // Controller buraya bağlanıyor
                decoration: tema.inputDec("E-posta girin", Icons.email),
                style: GoogleFonts.golosText(
                  color: const Color.fromARGB(255, 130, 115, 115).withValues(alpha: 0.8),
                ),
              ),
            ),

            // Şifre giriş alanı
            Container(
              decoration: tema.inputBoxDec(),
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                controller: _passwordController, // Controller buraya bağlanıyor
                obscureText: true,
                decoration: tema.inputDec("Şifre giriniz", Icons.lock),
                style: GoogleFonts.golosText(
                  color: const Color.fromARGB(255, 130, 115, 115).withValues(alpha: 0.8),
                ),
              ),
            ),

            // Giriş butonu
            ElevatedButton(
              onPressed: () {
                // Butona tıklandığında yapılacak işlemler
                String email = _emailController.text;
                String password = _passwordController.text;

                // Burada e-posta ve şifre ile ilgili işlemleri yapabilirsiniz.
                // Örneğin, konsola yazdırma:
                print("E-posta: $email");
                print("Şifre: $password");

                // Veya, kimlik doğrulama işlemi yapma:
                // (Bu kısım uygulamanızın gereksinimlerine göre değişecektir.)
                // Örn: Navigator.push(context, MaterialPageRoute(builder: (context) => Anasayfa()));
              },
              child: Text("Giriş Yap"),
            ),
          ],
        ),
      ),
    );
  }
}