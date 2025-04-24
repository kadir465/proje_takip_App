import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'projeSayfa.dart';
// HomePage, kullanıcıya aktif projeleri listeleyen ve yeni proje ekleyebileceği 
// bir ana ekran sağlayan StatefulWidget'tır.
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

// _HomePageState, HomePage widget'ının durumunu (state) yönetir.
class _HomePageState extends State<HomePage> {
  // Projeleri saklamak için dinamik bir liste; her proje, ad, durum, görev sayısı ve görevler içerir.
  List<Map<String, dynamic>> projeler = [];

  // Yeni proje eklemek için kullanılan metod.
  void projeEkle() {
    setState(() {
      // setState, widget'ın durumunda (state) değişiklik yapıldığında UI'ı yeniden çizdirmek için kullanılır.
      // Mevcut projeler listesinde en yüksek proje numarasını buluyoruz.
      int enYuksekNumara = 0;
      for (var proje in projeler) {
        // Projenin adını alıyoruz.
        String projeAdi = proje['ad'];
        // Proje adının "Proje " ile başlayıp başlamadığını kontrol ediyoruz.
        if (projeAdi.startsWith('Proje ')) {
          // "Proje " kelimesinden sonrasını sayıya dönüştürüyoruz.
          int numara = int.tryParse(projeAdi.substring(6)) ?? 0;
          if (numara > enYuksekNumara) {
            enYuksekNumara = numara;
          }
        }
      }
      // Yeni projeyi ekliyoruz. Proje adı, en yüksek numaraya 1 eklenerek belirleniyor.
      projeler.add({
        'ad': 'Proje ${enYuksekNumara + 1}',
        'durum': 'Devam Ediyor',  // Proje durumu (örneğin "Devam Ediyor")
        'gorevSayisi': 0,         // Başlangıçta proje için görev sayısı 0
        'gorevler': [],           // Görevler için boş bir liste
      });
    });
  }

  // Belirtilen proje index'indeki projeye yeni bir görev ekler.
  void gorevEkle(int projeIndex) {
    setState(() {
      // Projedeki görev sayısını bir artırıyoruz.
      projeler[projeIndex]['gorevSayisi']++;
      // Yeni görevi, projenin 'gorevler' listesine ekliyoruz.
      // Görev adı, mevcut görev sayısına göre dinamik oluşturuluyor.
      // Görevin tamamlanma durumu başlangıçta false, tamamlanması için henüz yapılmamış.
      // Göreve, bugünden itibaren 7 gün sonrasını tarih olarak ekliyoruz.
      projeler[projeIndex]['gorevler'].add({
        'ad': 'Görev ${projeler[projeIndex]['gorevSayisi']}',
        'tamamlandi': false,
        'tarih': DateTime.now().add(Duration(days: 7)),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold, temel ekran yapısını sağlar; burada arka plan rengi, AppBar, body, floatingActionButton yer alır.
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        elevation: 0, // AppBar gölgesi kaldırılmış
        backgroundColor: Color(0xFF1D1E33),
        title: Text(
          'Proje Yönetimi', // AppBar başlığı
          style: GoogleFonts.golosText(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Body kısmı, projelerin listeleneceği ve içeriklerin gösterileceği alandır.
      body: Container(
        // Container, arka plan için gradient (renk geçişi) tanımlar.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
          ),
        ),
        // İçeriklerin kaydırılabilir olması için SingleChildScrollView kullanılır.
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0), // Tüm kenarlardan 20 piksel boşluk
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Öğeleri sola hizalar
            children: [
              // "Aktif Projeler" başlığı
              Text(
                'Aktif Projeler',
                style: GoogleFonts.golosText(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20), // Başlık ile proje listesi arasında boşluk
              Container(
                // Projelerin gösterileceği alanın yüksekliği, ekran yüksekliğinin %35'i kadar belirlenir.
                height: MediaQuery.of(context).size.height * 0.35,
                child: ListView.builder(
                  // Projeler yatay olarak kaydırılabilir şekilde listelenir.
                  scrollDirection: Axis.horizontal,
                  itemCount: projeler.length, // Listede kaç proje varsa o kadar eleman oluşturur.
                  itemBuilder: (context, index) {
                    // Her proje için GestureDetector ile dokunma (tıklama) olayını algılar.
                    return GestureDetector(
                      onTap: () {
                        // Proje seçildiğinde ProjeSayfa adlı başka bir sayfaya geçiş yapar.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjeSayfa(
                              projeAdi: projeler[index]['ad'], // Seçilen projenin adı
                              projeAciklamasi: '', // Açıklama; burada boş bırakılmış
                              baslangicTarihi: DateTime.now(), // Projenin başlangıç tarihi
                              bitisTarihi: DateTime.now().add(
                                Duration(days: 30), // Projenin bitiş tarihi (30 gün sonra)
                              ),
                            ),
                          ),
                        );
                      },
                      // Proje kartını tanımlayan Container
                      child: Container(
                        width: 280, // Kart genişliği
                        margin: EdgeInsets.only(right: 20), // Kartlar arasında sağ boşluk
                        decoration: BoxDecoration(
                          // Kart için gradient arka plan rengi
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1D1E33), Color(0xFF111328)],
                          ),
                          borderRadius: BorderRadius.circular(20), // Yuvarlatılmış köşeler
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20), // Kart içindeki tüm öğeler için padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Proje adı
                              Text(
                                projeler[index]['ad'],
                                style: GoogleFonts.golosText(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 15), // Proje adı ile durum arasında boşluk
                              // Proje durumu (örn. Devam Ediyor) için kutu
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF24D876).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  projeler[index]['durum'],
                                  style: TextStyle(
                                    color: Color(0xFF24D876),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15), // Durum ile görev sayısı arasında boşluk
                              // Projede bulunan görev sayısını gösteren metin
                              Text(
                                'Görev Sayısı: ${projeler[index]['gorevSayisi']}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Spacer(), // Kalan boşluğu doldurarak, alt kısımda yer alan butonların hizalanmasını sağlar.
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Yeni görev eklemek için buton
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_task,
                                      color: Color(0xFF24D876),
                                      size: 28,
                                    ),
                                    onPressed: () => gorevEkle(index),
                                  ),
                                  // Projeyi silmek için buton
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Color(0xFFEB1555),
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // İlgili proje, projeler listesinden kaldırılır.
                                        projeler.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // FloatingActionButton, kullanıcıya yeni proje eklemesi için görünür bir buton sunar.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF24D876),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Yeni Proje',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: projeEkle, // Butona basıldığında projeEkle metodu çalışır.
      ),
    );
  }
}
