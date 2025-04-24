import 'package:flutter/material.dart';

// Posts sınıfı, bir liste halinde Post nesnelerini saklamak için kullanılır.
class Posts {
  // Post nesnelerinin bulunduğu liste.
  final List<Post> posts;

  // Yapıcı (constructor): posts listesini almak zorundadır.
  Posts({required this.posts});

  // factory constructor: JSON formatındaki veriden Posts nesnesi oluşturur.
  // Beklenen JSON formatı {"gorevler": [postJson1, postJson2, ...]} şeklindedir.
  factory Posts.fromJson(Map<String, dynamic> json) {
    // Post nesnelerini saklamak için boş bir liste oluşturulur.
    List<Post> postList = [];
    // "gorevler" anahtarındaki her bir öğeyi (her biri bir Map) Post nesnesine dönüştürüyoruz.
    for (var i in json["gorevler"]) {
      postList.add(Post.fromJson(i));
    }
    // Oluşturulan Post nesnelerinin listesini kullanarak Posts nesnesi döndürülür.
    return Posts(posts: postList);
  }
}

// Post sınıfı, tek bir gönderiyi (örneğin bir görev veya makale) temsil eder.
class Post {
  // Post ile ilgili açıklama metni.
  final String aciklama;
  // Post başlığı.
  final String baslik;
  // Görev ya da gönderiye atanan kişinin adı.
  final String atanan;
  // İlgili e-posta adresi.
  final String mail;

  // Yapıcı (constructor): Tüm alanların sağlanması zorunludur.
  Post({
    required this.aciklama,
    required this.baslik,
    required this.atanan,
    required this.mail,
  });

  // factory constructor: JSON formatındaki veriden Post nesnesi oluşturur.
  // Beklenen JSON formatı örneğin:
  // {
  //   "aciklama": "Görev açıklaması",
  //   "baslik": "Görev başlığı",
  //   "atanan": "Atanan kişinin adı",
  //   "mail": "E-posta adresi"
  // }
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      aciklama: json["aciklama"],
      baslik: json["baslik"],
      atanan: json["atanan"],
      mail: json["mail"],
    );
  }
}
