// Material Design ve Flutter widget'ları için temel paket
import 'package:flutter/material.dart';
// Google Fonts kütüphanesi için import
import 'package:google_fonts/google_fonts.dart';

// Sabit arka plan rengi (Hex formatında # işareti olmadan)
const String arka_renk = "3E4050";

// Özel renk sınıfı (Color sınıfından türetilmiş)
class renk extends Color {
  // Hex renk kodunu integer'a çeviren private statik metod
  static int _donustur(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", ""); // Format düzenleme
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor; // Alpha değeri ekleme (tam opak)
    }
    return int.parse(hexColor, radix: 16); // Hex'den integer'a çevirme
  }

  // Constructor: String renk kodunu alıp Color sınıfına dönüştürür
  renk(final String renk_kodu) : super(_donustur(renk_kodu));
}

// Özelleştirilebilir gradient buton widget'ı
Widget customButton({
  required String buttonText, // Buton üzerindeki yazı (zorunlu)
  required Function() onTap, // Tıklama fonksiyonu (zorunlu)
  Color startColor = const Color(
    0xFF6A11CB,
  ), // Başlangıç rengi (varsayılan: mor)
  Color endColor = const Color(0xFF2575FC), // Bitiş rengi (varsayılan: mavi)
  double borderRadius = 15.0, // Köşe yuvarlaklığı (varsayılan: 15px)
  EdgeInsets margin = const EdgeInsets.all(12), // Dış boşluk
  EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  ), // İç boşluk (varsayılan: yatay 24, dikey 16)
  double fontSize = 16.0, // Yazı boyutu (varsayılan: 16)
  FontWeight fontWeight = FontWeight.bold, // Yazı kalınlığı (varsayılan: kalın)
}) {
  return InkWell(
    // Tıklama efektli container
    onTap: onTap,
    child: Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Gradient arka plan
          begin: Alignment.topLeft, // Başlangıç pozisyonu (sol üst)
          end: Alignment.bottomRight, // Bitiş pozisyonu (sağ alt)
          colors: [startColor, endColor], // Renk geçişi
        ),
        borderRadius: BorderRadius.circular(borderRadius), // Köşe yuvarlaklığı
        boxShadow: [
          // Gölge efektleri
          BoxShadow(
            color: startColor.withOpacity(0.3), // Gölge rengi
            spreadRadius: 1, // Yayılma alanı
            blurRadius: 8, // Bulanıklık
            offset: const Offset(0, 4), // Konum (yatay, dikey)
          ),
        ],
      ),
      child: Center(
        // İçerik hizalama
        child: Text(
          buttonText,
          style: GoogleFonts.golosText(
            // Google Fonts ile özel yazı stili
            color: Colors.white, // Yazı rengi
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: 0.5, // Harf aralığı
          ),
        ),
      ),
    ),
  );
}
