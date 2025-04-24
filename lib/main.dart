import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';// flutter temel uı elemanlarını kullanmak için gerekli
import 'package:projeis/sayfalar/giris.dart';
import 'firebase_options.dart';

//main fonksiyonu uygulamanın başlangıç noktasıdır ilk bura çalışır
//async ve await anahtar kelimeleri ile asenkron bir fonksiyon oluşturulmuştur zamanlayıcı şeklinde çalışır
//Firebase.initializeApp() fonksiyonu ile Firebase projesi başlatılır
//runApp() fonksiyonu ile uygulama çalıştırılır
void main ()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:  DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}
//MyApp sınıfı StatelessWidget sınıfından türetilmiştir
//build metodu ile uygulamanın başlangıç noktası belirlenir
//MaterialApp sınıfı ile uygulamanın temel özellikleri belirlenir

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  
       debugShowCheckedModeBanner: false,//debug modunda uygulamanın sağ üst köşesindeki debug yazısını kaldırır
      theme: ThemeData(//uygulamanın teması belirlenir
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
     home: GirisSayfasi(),//uygulamanın başlangıç sayfası belirlenir ama ilk olarak import etmek lazım
    );
  }
}

