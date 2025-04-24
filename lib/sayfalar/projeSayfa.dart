import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projeis/sayfalar/duty.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ayarlar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:projeis/sayfalar/giris.dart';
// Firebase Realtime Database referansı oluşturuluyor.
// Bu referans, FirebaseDatabase üzerinden veri işlemleri yapmamızı sağlar.
final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

// ProjeSayfa, belirli bir projenin detaylarını (adı, açıklaması, başlangıç ve bitiş tarihi)
// görüntüleyen ve proje ile ilgili görev işlemlerini yöneten StatefulWidget'tır.
class ProjeSayfa extends StatefulWidget {
  // Projenin adı, açıklaması ve tarih bilgileri widget'ın dışarıdan alacağı parametrelerdir.
  String projeAdi;
  String projeAciklamasi;
  DateTime baslangicTarihi;
  DateTime bitisTarihi;

  ProjeSayfa({
    Key? key,
    required this.projeAdi,
    required this.projeAciklamasi,
    required this.baslangicTarihi,
    required this.bitisTarihi,
  }) : super(key: key);

  @override
  State<ProjeSayfa> createState() => _ProjeSayfaState();
}

// _ProjeSayfaState, ProjeSayfa widget'ının durumunu yönetir.
// Burada görevlerin listesi, proje ilerlemesi, açıklama kontrolü ve veri kaydetme/yükleme işlemleri yer alır.
class _ProjeSayfaState extends State<ProjeSayfa> {
  // Projeye ait görevlerin tutulduğu liste.
  final List<Gorev> gorevler = [];

  // Proje ilerlemesini (tamamlanma oranı) tutan değişken.
  double projeIlerleme = 0.0;

  // Proje açıklamasını düzenlemek için kullanılan TextEditingController.
  final TextEditingController _aciklamaController = TextEditingController();

  // Gereksiz bir getter; örneğin kullanımı yok.
  get icon => null;

  @override
  void initState() {
    super.initState();
    // Widget yüklendiğinde, önceden kaydedilmiş verileri yüklemek için çağrılır.
    _verileriYukle();
    // Proje açıklamasını, widget'tan gelen değere eşitler.
    _aciklamaController.text = widget.projeAciklamasi;
  }

  // _verileriYukle metodu, SharedPreferences kullanarak daha önce kaydedilmiş proje açıklaması
  // ve görev verilerini yerel depodan yükler.
  Future<void> _verileriYukle() async {
    // SharedPreferences instance'ı elde edilir.
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Proje açıklaması için kaydedilmiş değer kontrol edilir.
      final kaydedilmisAciklama = prefs.getString('${widget.projeAdi}_aciklama');
      if (kaydedilmisAciklama != null) {
        // Eğer kaydedilmiş açıklama varsa, widget'ın projeAciklamasi ve kontrol metninde güncellenir.
        widget.projeAciklamasi = kaydedilmisAciklama;
        _aciklamaController.text = kaydedilmisAciklama;
      }

      // Proje görevleri için kaydedilmiş JSON string değeri alınır.
      final gorevlerJson = prefs.getString('${widget.projeAdi}_gorevler');
      if (gorevlerJson != null) {
        // JSON string, dinamik (List) formata dönüştürülür.
        final List<dynamic> gorevlerList = jsonDecode(gorevlerJson);
        // Mevcut görev listesi temizlenir.
        gorevler.clear();
        // Her bir görev verisi, Gorev modeline dönüştürülerek listeye eklenir.
        for (var gorev in gorevlerList) {
          gorevler.add(
            Gorev(
              baslik: gorev['baslik'],
              aciklama: gorev['aciklama'],
              atananKisi: gorev['atananKisi'],
              mail: gorev['mail'] ?? '', // 'mail' değeri null ise varsayılan boş string atanır.
              tamamlandi: gorev['tamamlandi'],
            ),
          );
        }
        // Görevler güncellendikten sonra proje ilerlemesi yeniden hesaplanır.
        ilerlemeHesapla();
      }
    });
  }

  // _verileriKaydet metodu, mevcut proje açıklaması ve görev listesini SharedPreferences'e kaydeder.
  Future<void> _verileriKaydet() async {
    // SharedPreferences instance'ı elde edilir.
    final prefs = await SharedPreferences.getInstance();
    // Proje açıklaması, proje adıyla eşleştirilmiş bir anahtar kullanılarak kaydedilir.
    await prefs.setString(
      '${widget.projeAdi}_aciklama',
      widget.projeAciklamasi,
    );

    // Görevler listesindeki her bir Gorev nesnesi, Map formatına dönüştürülür.
    final gorevlerList = gorevler.map(
      (gorev) => {
        'baslik': gorev.baslik,
        'aciklama': gorev.aciklama,
        'atananKisi': gorev.atananKisi,
        'tamamlandi': gorev.tamamlandi,
      },
    ).toList();

    // Görevler listesini JSON string'e dönüştürüp kaydeder.
    await prefs.setString(
      '${widget.projeAdi}_gorevler',
      jsonEncode(gorevlerList),
    );
  }

  // gorevEkle metodu, parametre olarak verilen bilgilerle yeni bir görev ekler.
  // Eklenen görev listesine eklenir, proje ilerlemesi yeniden hesaplanır ve veriler kaydedilir.
  void gorevEkle(
    String baslik,
    String aciklama,
    String atananKisi,
    String mail,
  ) {
    setState(() {
      // Yeni görev, gorevler listesine eklenir.
      gorevler.add(
        Gorev(
          baslik: baslik,
          aciklama: aciklama,
          atananKisi: atananKisi,
          mail: mail,
          tamamlandi: false, // Yeni görev başlangıçta tamamlanmamış olarak eklenir.
        ),
      );
      // Görev eklenmesi sonrası proje ilerlemesi yeniden hesaplanır.
      ilerlemeHesapla();
      // Güncellenen veriler, yerel depoya kaydedilir.
      _verileriKaydet();
    });
  }

  // gorevDurumDegistir metodu, belirli bir görev için tamamlanma durumunu günceller.
  // Görev tamamlandıysa, proje ilerlemesi yeniden hesaplanır ve veriler kaydedilir.
  void gorevDurumDegistir(int index, bool tamamlandi) {
    setState(() {
      gorevler[index].tamamlandi = tamamlandi;
      ilerlemeHesapla();
      _verileriKaydet();
    });
  }

  // ilerlemeHesapla metodu, projedeki tamamlanmış görevlerin oranını hesaplar.
  // Görev listesi boşsa, ilerleme %0 kabul edilir.
  void ilerlemeHesapla() {
    if (gorevler.isEmpty) {
      projeIlerleme = 0.0;
      return;
    }
    // Tamamlanmış görevlerin sayısı hesaplanır.
    int tamamlananGorevler = gorevler.where((g) => g.tamamlandi).length;
    // Proje ilerlemesi, tamamlanan görevlerin toplam görevlere oranı olarak belirlenir.
    projeIlerleme = tamamlananGorevler / gorevler.length;
  }

@override
Widget build(BuildContext context) {
  // topCenter, LinearGradient başlangıç konumunu tanımlar.
  var topCenter = Alignment.topCenter;
  return Scaffold(
    // Scaffold, temel ekran yapısını sağlar. Arka plan rengi ayarlanmış.
    backgroundColor: Color(0xFF0A0E21),
    appBar: AppBar(
      // AppBar arka plan rengi ayarlanmış.
      backgroundColor: Color(0xFF1D1E33),
      // leading kısmı, sol üstteki geri butonunu temsil eder.
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFF24D876)),
        // Geri butonuna basıldığında Navigator.pop ile önceki sayfaya dönülür.
        onPressed: () => Navigator.pop(context),
      ),
      // AppBar başlığı, widget'ın proje adını gösterir.
      title: Text(widget.projeAdi, style: TextStyle(color: Colors.white)),
      actions: [
        // Sağ üstte yer alan ayarlar butonu.
        IconButton(
          icon: Icon(Icons.settings, color: Color(0xFF24D876)),
          onPressed: () {
            // Ayarlar butonuna basıldığında, AyarlarPage ekranına geçiş yapılır.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AyarlarPage(
                  // AyarlarPage'e sabit ayarlar bilgileri gönderiliyor.
                  ayarlar: Ayarlar(
                    name: 'Kullanıcı',
                    email: 'kullanici@email.com',
                    phone: '+90 555 555 5555',
                    role: 'Kullanıcı',
                    password: '******',
                    bildirimAktif: true,
                    dilSecenegi: 'Türkçe',
                    tema: 'Koyu',
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    // Body, ekranın ana içeriğini barındırır.
    body: Container(
      // Arka plan için gradient (renk geçişi) uygulanıyor.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E21), Color(0xFF1D1E33)],
        ),
      ),
      // SingleChildScrollView, içeriğin ekran boyutundan büyük olması durumunda kaydırılmasını sağlar.
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0), // Tüm kenarlardan 16 piksel padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Çocuk widget'lar sola hizalanır.
          children: [
            // "Proje Detayları" başlığı.
            Text(
              'Proje Detayları',
              style: GoogleFonts.golosText(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Başlık ile detay kartı arasına boşluk.
            SizedBox(height: 16.0),
            // Proje detaylarını içeren kart.
            Card(
              color: Color(0xFF1D1E33), // Kart arka plan rengi.
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proje açıklamasını düzenlemek için TextFormField kullanılır.
                    TextFormField(
                      controller: _aciklamaController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Açıklama',
                        labelStyle: TextStyle(color: Color(0xFF24D876)),
                        // Alt çizgi gibi varsayılan kenarlık kaldırılarak özel stil veriliyor.
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF24D876)),
                        ),
                      ),
                      // Kullanıcı metni değiştirdiğinde projeAciklamasi güncellenir ve veriler kaydedilir.
                      onChanged: (value) {
                        setState(() {
                          widget.projeAciklamasi = value;
                          _verileriKaydet();
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    // Başlangıç tarihini gösteren ve değiştirmeye olanak tanıyan satır.
                    Row(
                      children: [
                        Text(
                          'Başlangıç: ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        // Tarih seçici butonu.
                        TextButton(
                          child: Text(
                            // Tarih, yıl-ay-gün formatında gösterilir.
                            widget.baslangicTarihi.toString().split(' ')[0],
                            style: TextStyle(color: Color(0xFF24D876)),
                          ),
                          onPressed: () async {
                            // Tarih seçici diyalog açılır.
                            final date = await showDatePicker(
                              context: context,
                              initialDate: widget.baslangicTarihi,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              // Tarih seçicinin temasını özelleştirmek için builder kullanılır.
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFF24D876),
                                      surface: Color(0xFF1D1E33),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            // Kullanıcı yeni tarih seçtiyse, başlangıç tarihi güncellenir.
                            if (date != null) {
                              setState(() {
                                widget.baslangicTarihi = date;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // Bitiş tarihini gösteren ve değiştirmeye olanak tanıyan satır.
                    Row(
                      children: [
                        Text(
                          'Bitiş: ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          child: Text(
                            widget.bitisTarihi.toString().split(' ')[0],
                            style: TextStyle(color: Color(0xFF24D876)),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: widget.bitisTarihi,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFF24D876),
                                      surface: Color(0xFF1D1E33),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                widget.bitisTarihi = date;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Proje ilerlemesini gösteren metin.
            Text(
              'Proje İlerlemesi: %${(projeIlerleme * 100).toInt()}',
              style: GoogleFonts.golosText(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Lineer ilerleme çubuğu, proje ilerlemesini görsel olarak sunar.
            LinearProgressIndicator(
              value: projeIlerleme, // 0.0 ile 1.0 arasında bir değer
              minHeight: 10,
              backgroundColor: Color(0xFF1D1E33),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF24D876)),
            ),
            SizedBox(height: 20),
            // Görevler başlığı ve "Görev Ekle" butonunu içeren satır.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Görevler',
                  style: GoogleFonts.golosText(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // ElevatedButton.icon, buton üzerinde ikon ve metin gösterir.
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF24D876),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // "Görev Ekle" butonuna basıldığında, GorevEkleDialog adlı diyalog açılır.
                    showDialog(
                      context: context,
                      builder: (context) => GorevEkleDialog(onGorevEkle: gorevEkle),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Görev Ekle'),
                ),
              ],
            ),
            // Görev listesini görüntülemek için ListView.builder kullanılır.
            // shrinkWrap true olduğu için, ListView mevcut içeriğe göre daralır.
            // physics: NeverScrollableScrollPhysics() ile kaydırma engellenir, çünkü SingleChildScrollView kullanılıyor.
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: gorevler.length, // Listedeki görev sayısı kadar öğe oluşturulur.
              itemBuilder: (context, index) {
                // Her bir görev için GorevKarti widget'ı oluşturulur.
                return GorevKarti(
                  gorev: gorevler[index],
                  // Görevin tamamlanma durumu değiştiğinde gorevDurumDegistir metodu çağrılır.
                  onDurumDegistir: (tamamlandi) => gorevDurumDegistir(index, tamamlandi),
                  // Görev silindiğinde, ilgili görev listeden çıkarılır ve veriler kaydedilir.
                  onSil: () {
                    setState(() {
                      gorevler.removeAt(index);
                      _verileriKaydet();
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
}// Görev modelini temsil eden sınıf.
// Her bir görev, başlık, açıklama, atanan kişi, e-posta ve tamamlanma durumunu içerir.
class Gorev {
  String baslik;         // Görevin başlığı
  String aciklama;       // Görevin açıklaması
  String atananKisi;     // Görev için atanan kişinin adı
  bool tamamlandi;       // Görevin tamamlanıp tamamlanmadığını belirten boolean (varsayılan false)
  String mail;           // Atanan kişinin e-posta adresi

  Gorev({
    required this.baslik,
    required this.aciklama,
    required this.atananKisi,
    required this.mail,
    this.tamamlandi = false, // Yeni görevler varsayılan olarak tamamlanmamış kabul edilir
  });
}

// GörevKarti widget'ı, tek bir görevin görsel temsilini sağlayan StatelessWidget'tır.
// Bu widget, görevin bilgilerini (başlık, açıklama, atanan kişi) gösterir ve
// görevle ilgili durum değiştirme, silme veya mesaj gönderme işlemleri için butonlar içerir.
class GorevKarti extends StatelessWidget {
  final Gorev gorev;                    // Gösterilecek görev modeli
  final Function(bool) onDurumDegistir;  // Görevin tamamlanma durumunu değiştiren callback fonksiyon
  final VoidCallback onSil;              // Görevi silmek için çağrılan callback fonksiyon

  const GorevKarti({
    Key? key,
    required this.gorev,
    required this.onDurumDegistir,
    required this.onSil,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      // Kartın arka plan rengi ayarlanıyor
      color: Color(0xFF1D1E33),
      // Kartın üst ve alt kenarlarında 8 piksel boşluk bırakılır
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        // Görev başlığı, kartın ana başlık kısmında beyaz renkli metin olarak gösterilir.
        title: Text(gorev.baslik, style: TextStyle(color: Colors.white)),
        // Alt bilgi kısmında, görev açıklaması ve atanan kişinin adı yer alır.
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gorev.aciklama, style: TextStyle(color: Colors.white70)),
            Text(
              'Atanan: ${gorev.atananKisi}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        // Kartın sağ kısmında (trailing) görevle ilgili işlemleri yapacak butonlar yer alır.
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Sadece ihtiyaç duyulan alanı kaplar
          children: [
            // Checkbox, görevin tamamlanma durumunu gösterir ve değiştirilmesine olanak tanır.
            Checkbox(
              value: gorev.tamamlandi,
              onChanged: (value) => onDurumDegistir(value ?? false),
              activeColor: Color(0xFF24D876), // Seçildiğinde aktif renk
              checkColor: Colors.white,       // İşaretin rengi
            ),
            // Silme işlemi için çöp kutusu ikonu. Basıldığında silme işlemi başlatılır.
            IconButton(
              icon: Icon(Icons.delete, color: Color(0xFFEB1555)),
              onPressed: () {
                // Silme işlemini onaylamak için diyalog açılır.
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Color(0xFF1D1E33),
                    title: Text(
                      'Görevi Sil',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Bu görevi silmek istediğinizden emin misiniz?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      // İptal butonu: Diyaloğu kapatır, hiçbir işlem yapmaz.
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'İptal',
                          style: TextStyle(color: Color(0xFF24D876)),
                        ),
                      ),
                      // Sil butonu: onSil callback'ini çağırır ve ardından diyalog kapanır.
                      TextButton(
                        onPressed: () {
                          onSil();
                          Navigator.pop(context);
                          // Silme işlemi sonrası kullanıcıya bilgi vermek için SnackBar gösterilir.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Görev silindi'),
                              backgroundColor: Color(0xFFEB1555),
                            ),
                          );
                        },
                        child: Text(
                          'Sil',
                          style: TextStyle(color: Color(0xFFEB1555)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Mesaj gönderme işlemi için mesaj ikonu butonu.
            // Basıldığında Duty adlı başka bir sayfaya yönlendirir.
            IconButton(
              icon: const Icon(Icons.message, color: Color(0xFF24D876)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Duty(
                      // Burada örnek receiverId ve receiverEmail değerleri verilmiştir.
                      receiverId: 'someReceiverId', // Gerçek değerle değiştirilmelidir.
                      receiverEmail: 'someReceiverEmail', // Gerçek değerle değiştirilmelidir.
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// GorevEkleDialog, yeni görev eklemek için açılan diyalog penceresidir.
// Kullanıcıdan görevle ilgili bilgiler (başlık, açıklama, atanan kişi, mail) alınır.
class GorevEkleDialog extends StatefulWidget {
  // onGorevEkle callback fonksiyonu, diyalogda girilen bilgileri ana ekrana geri göndermek için kullanılır.
  final void Function(String, String, String, String) onGorevEkle;

  const GorevEkleDialog({Key? key, required this.onGorevEkle}) : super(key: key);

  @override
  _GorevEkleDialogState createState() => _GorevEkleDialogState();
}

// GorevEkleDialog'un durumunu yöneten state sınıfı.
class _GorevEkleDialogState extends State<GorevEkleDialog> {
  // Kullanıcının görev eklerken girdiği verileri kontrol etmek için TextEditingController'lar.
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _atananKisiController = TextEditingController();
  final _mailController = TextEditingController();

  // Firebase Realtime Database referansı,
  // "gorevler" adlı alt koleksiyona erişim sağlamak için kullanılır.
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child(
    "gorevler",
  );

  // Diğer metodlar (örneğin, verilerin gönderilmesi veya diyalogun kapatılması) bu state sınıfında tanımlanabilir.
  // (Bu kısım kod örneğinde henüz tamamlanmamış ancak genellikle form gönderme işlemi burada yapılır.)


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Text('Yeni Görev', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _baslikController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Görev Başlığı',
                labelStyle: const TextStyle(color: Color(0xFF24D876)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFF24D876)),
                ),
              ),
            ),
            TextField(
              controller: _aciklamaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Görev Açıklaması',
                labelStyle: const TextStyle(color: Color(0xFF24D876)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF24D876)),
                ),
              ),
            ),
            TextField(
              controller: _atananKisiController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Atanan Kişi',
                labelStyle: const TextStyle(color: Color(0xFF24D876)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF24D876)),
                ),
              ),
            ),
            TextField(
              controller: _mailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress, //E-mail için düzenlendi
              decoration: InputDecoration(
                labelText: 'E-Mail',
                labelStyle: const TextStyle(color: Color(0xFF24D876)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF24D876)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'İptal',
            style: TextStyle(color: Color(0xFF24D876)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24D876),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_baslikController.text.isNotEmpty) {
              // Firebase'e kaydetme işlemini çağırın
              _saveGorevToFirebase();

              widget.onGorevEkle(
                _baslikController.text,
                _aciklamaController.text,
                _atananKisiController.text,
                _mailController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Görev eklendi'),
                  backgroundColor: Color(0xFF24D876),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Görev başlığı boş olamaz'),
                  backgroundColor: Color(0xFFEB1555),
                ),
              );
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }

  // Firebase'e veri kaydetme fonksiyonu
  Future<void> _saveGorevToFirebase() async {
    try {
      // Rastgele bir anahtar oluştur
      String? key = _databaseRef.push().key;
      if (key == null) {
        print("Hata: Anahtar oluşturulamadı.");
        return;
      }

      // Veriyi bir Map olarak hazırla
      Map<String, String> gorevData = {
        'baslik': _baslikController.text,
        'aciklama': _aciklamaController.text,
        'atananKisi': _atananKisiController.text,
        'mail': _mailController.text,
      };

      // Veriyi Firebase'e kaydet
      await _databaseRef.child(key).set(gorevData);

      print("Görev Firebase'e başarıyla kaydedildi.");
    } catch (error) {
      print("Firebase'e veri kaydetme hatası: $error");
      // Hata durumunda kullanıcıya bilgi verebilirsiniz
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _atananKisiController.dispose();
    _mailController.dispose();
    super.dispose();
  }
}
