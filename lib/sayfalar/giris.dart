import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projeis/sabitler/auth.dart';
import 'package:projeis/sabitler/ext.dart';
import 'package:projeis/sabitler/tema.dart';
import 'package:projeis/sayfalar/home.dart';

// GirisSayfasi, Flutter'da bir StatefulWidget sınıfıdır.
// StatefulWidget, durumu (state) değişebilen ve bu değişikliklere göre
// yeniden oluşturulabilen (rebuild) widget'lar için kullanılır.
class GirisSayfasi extends StatefulWidget {
  // GirisSayfasi sınıfının yapıcı metodu (constructor).
  // Bu yapıcı, widget oluşturulurken çağrılır.
  // `const` anahtar kelimesi, bu widget'ın sabit (immutable) olduğunu belirtir.
  // `super.key`, üst sınıf olan StatefulWidget'a bir anahtar (key) iletilmesini sağlar.
  // Anahtarlar, widget'ları benzersiz şekilde tanımlamak ve durumlarını yönetmek için kullanılır.
  const GirisSayfasi({super.key});

  // createState metodu, StatefulWidget'ın durumunu yönetecek olan
  // bir State nesnesi oluşturur. Bu metod, widget oluşturulduğunda otomatik olarak çağrılır.
  // @override anahtar kelimesi, bu metodun üst sınıftan (StatefulWidget) miras alındığını
  // ve yeniden tanımlandığını belirtir.
  // _GirisSayfasiState, GirisSayfasi widget'ının durumunu yönetecek olan özel bir State sınıfıdır.
  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  Tema tema = Tema(); // tema sınıfından bir nesne oluşturuldu.
  final TextEditingController _emailController =
      TextEditingController(); // email alanı için bir controller oluşturuldu.
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage =
      ''; // oluşacak olan hata mesajlarını göstermek için kullanıır
  bool _showForgotPassword = false;

  Future<void> creatUser() async {
    //createUser metodu yeni bir kulllanıcı eklemk için asenkron olark çalıştırı
    try {
      await Auth().signUp(
        ///*Auth sınıfından signUp metodu çağrıldı
        email:
            _emailController
                .text, //kulanıcıdan alınan email ve şifre değerleri signUp metoduna gönderildi
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        //? navigator.pushReplacement metodu ile bu sayfayı kaldırı yeni sayfayı getir
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        //eğer kayıt sırasında hata olursa firbase özel hata mesajını gösterir
        errorMessage = e.message!;
      });
    }
  }

  Future<void> signIn() async {
    //signIn metodu kullanıcı girişi yapmak için asenkron olarak çalıştırılır
    try {
      await Auth().signIn(
        //kullanıcıdan alınan email ve şifre değerleri signIn metoduna gönderilir//?bu sayede ferbase ile kimlik doğrulaması yazpılır
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      //firebase tipinde bir hata varsa bu blok çalıştırılır
      if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                //alert diyolag ile arka plan rengi ayarlandı
                backgroundColor: Color(0xFF1D1E33),
                title: Text(
                  'Kullanıcı Bulunamadı',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  'Kayıtlı değilsiniz. Kayıt olmak ister misiniz?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); //dialog kapatılır
                    },
                    child: Text(
                      'İptal',
                      style: TextStyle(color: Color(0xFFEB1555)),
                    ),
                  ),
                  TextButton(
                    // kayıt ol butonuna basıldığında creatUser metodu çalıştırılır ve kullanıcı kayıt edilir
                    onPressed: () {
                      Navigator.pop(context);
                      creatUser();
                    },
                    child: Text(
                      'Kayıt Ol',
                      style: TextStyle(color: Color(0xFF24D876)),
                    ),
                  ),
                ],
              ),
        );
      } else {
        setState(() {
          errorMessage = e.message!;
        });
      }
    }
  }

  //restartPasword methodu kullanıcı şifresini sıfırlaması için kullanılan asenkron bir metoddur
  void resetPassword() async {
    if (_emailController.text.isEmpty) {
      //e postanını boş mu değil mi onu kontrol edilir eğer boşsa hat mesajı gönderir
      setState(() {
        errorMessage = "Lütfen bir e-posta adresi girin";
      });
      return;
    }
    try {
      //*firebase instanceyi kullanarak kullanıcı masil adresine şifre sıfırlama bağlantısı gönderilir
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        //şifre sıfırlama bağlantısı email adresine gönderildi bilgilendirmesi gönderir
        SnackBar(
          backgroundColor: Color(
            0xFF1D1E33,
          ), //snackbar arka plan rengini beirler
          content: Text(
            'Şifre sıfırlama bağlantısı email adresinize gönderildi',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      setState(() {
        _showForgotPassword = false;
      });
    } on FirebaseAuthException catch (e) {
      setState() {
        // firebase tipinde bir hata oluşursa onu gosterir sayfayı günceller ve tamamlar
        errorMessage = e.message!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      //cihazın çentik,durum çubuğu gibi sistemlerin oluşturduğu alanlardan uzak bir şekilde çalıştırılır ve içeriklerin kesilmesini önler
      child: Scaffold(
        //scaffold ile bir sayfa oluşturulur temel dizanlar burda belirlenir
        backgroundColor: Color(0xFF0A0E21), //arkaplan rengi ayarlama
        body: Container(
          width:
              MediaQuery.of(
                context,
              ).size.width, //containerin genişliği cihazın genişliği kadar olur
          height:
              MediaQuery.of(context)
                  .size
                  .height, //containerin yüksekliği cihazın yüksekliği kadar olur
          child: SingleChildScrollView(
            //singleChildScrollView ile ekranın dışına taşan içeriklerin kaydırılmasını sağlar
            child: Column(
              //colum cocuk widhtlerini sütun şeklinde düzenler
              children: [
                Container(
                  //bu contenir dairesel bir öge barındırır
                  //!   CONTANİERLER BİR NESNE OLUŞTURULMADAN ÖNCE KULLANILIR İLK CONTANİER OLUŞTURULUR SONRA DİĞER KISIMLAR OLUR
                  //! contenier içinde başka contenirler de olabilir dizayn b contenirlera göre yapılır
                  width: 180, //SABİT GRNİŞLİK
                  height: 180, //sabit yükseklik
                  padding: const EdgeInsets.all(
                    12,
                  ), //tüm kenarlara boşluk ekler
                  decoration: BoxDecoration(
                    //contaniera sitil ve decor özelliği ekler
                    borderRadius: BorderRadius.circular(
                      90,
                    ), //border radius ile kenarları yuvarlatır
                    gradient: LinearGradient(
                      //iki renk arasında geçiş sağlar
                      begin: Alignment.topLeft, // başlangıç noktası sol üst
                      end: Alignment.bottomRight, //bitiş noktası sağ alt
                      colors: [
                        Color(0xFF1D1E33),
                        Color(0xFF111328),
                      ], //geçiş yapılacak renkler
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      border: Border.all(
                        color: Color(0xFF24D876),
                      ), //kenarlık ekler nesneye
                      color: Color(0xFF1D1E33),
                    ),
                    child: Icon(
                      Icons.login, // icon ekler burda giriş ionu eklenmiş
                      size: 50, //icon boyutu 50 olarak ayarlanmış
                      color: Color(0xFF24D876),
                    ),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(
                    top: 20,
                  ), //üs kısmında boşluk bırakır
                  child: Text(
                    _showForgotPassword ? "Şifre Sıfırlama" : "Giriş Yap",
                    style: GoogleFonts.golosText(
                      //import edilmiş olan google fontları kullanılır
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (errorMessage
                    .isNotEmpty) //eğer hata mesajı varsa bu blok çalışır
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.golosText(
                        //hata mesajı rengi kırmızı olmuştur
                        color: Color(0xFFEB1555),
                        fontSize: 16,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1D1E33),
                    borderRadius: BorderRadius.circular(
                      15,
                    ), //yuvarlaştırma yapılır
                    boxShadow: [
                      // gölgelendirme yapılır
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(
                          0,
                          4,
                        ), //golge konumu başlangıç noktası 0,4
                        blurRadius: 10, //gölge yumuşaklığı
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20, //yatayda  boşluk bırakır
                    vertical: 10, //dikeyde boşluk bırakır
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "E-posta adresinizi girin",
                      hintStyle: GoogleFonts.golosText(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined, //email iconu eklenir
                        color: Color(0xFF24D876),
                      ),
                      border: InputBorder.none, //kenarlıkmkaldırma
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    style: GoogleFonts.golosText(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),

                if (!_showForgotPassword)
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1D1E33),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26, //opaklığı ayarlar
                          offset: Offset(0, 4),
                          blurRadius: 10, //bulanıklık sağlar
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.symmetric(
                      //yatay ve dikey boyutun girilerk bir boşluk bırakır
                      horizontal: 20,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true, //metini*** şeklinde gizler
                      decoration: InputDecoration(
                        hintText:
                            "Şifre giriniz", //herhangi bir şey yazılmadığı dumuda görünür
                        hintStyle: GoogleFonts.golosText(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF24D876),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      style: GoogleFonts.golosText(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showForgotPassword = !_showForgotPassword;
                      errorMessage = '';
                    });
                  },
                  child: Text(
                    _showForgotPassword ? "Giriş Yap" : "Şifremi Unuttum",
                    style: GoogleFonts.golosText(
                      color: Color(0xFF24D876),
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_showForgotPassword)
                  Container(
                    width: double.infinity, //contanier i tam genişlik yapar
                    margin: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF24D876),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          //köşe şekli verir
                          borderRadius: BorderRadius.circular(
                            10,
                          ), //yuvarlak köşe oluşturur
                        ),
                      ),
                      child: Text(
                        "Şifre Sıfırlama Linki Gönder",
                        style: GoogleFonts.golosText(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF24D876),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Giriş Yap",
                        style: GoogleFonts.golosText(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    child: ElevatedButton(
                      onPressed: creatUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1D1E33),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Kayıt Ol",
                        style: GoogleFonts.golosText(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
