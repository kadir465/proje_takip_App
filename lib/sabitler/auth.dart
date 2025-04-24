import 'package:firebase_auth/firebase_auth.dart';

// Auth sınıfı, Firebase Authentication kullanarak kullanıcı kaydı, giriş işlemleri
// ve şifre saklama gibi işlemleri gerçekleştiren bir servistir.
class Auth {
  // FirebaseAuth instance'ı, Firebase Authentication servisine erişim sağlamak için kullanılır.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // signUp metodu, verilen e-posta ve şifreyle yeni bir kullanıcı kaydı oluşturur.
  // createUserWithEmailAndPassword metodu, Firebase Authentication üzerinden
  // yeni bir kullanıcı oluşturur. Bu işlem asenkron olarak gerçekleştirilir.
  Future<void> signUp({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,       // Kullanıcının e-posta adresi
      password: password, // Kullanıcının şifresi
    );
  }

  // signIn metodu, mevcut kullanıcıyı verilen e-posta ve şifre ile oturum açtırır.
  // signInWithEmailAndPassword metodu, Firebase Authentication üzerinden
  // kullanıcı girişi işlemini asenkron olarak gerçekleştirir.
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email,       // Kullanıcının e-posta adresi
      password: password, // Kullanıcının şifresi
    );
  }

  // savePassword metodu, şifreyi güvenli bir şekilde saklamak için tasarlanmıştır.
  // Bu örnekte, şifre saklama işlemi için herhangi bir kod bulunmamakta; 
  // ancak gerçek uygulamalarda SharedPreferences, Keychain (iOS) veya
  // benzeri güvenli depolama yöntemleri kullanılmalıdır.
  // Not: Şifrelerin düz metin olarak saklanması güvenli değildir.
  Future<void> savePassword(String password) async {
    // Şifreyi güvenli bir şekilde saklamak için
    // SharedPreferences veya başka bir güvenli depolama yöntemi kullanılabilir.
    // Bu sadece örnek amaçlı boş bırakılmış bir metoddur.
  }
}
