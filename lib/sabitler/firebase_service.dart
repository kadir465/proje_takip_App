// FirebaseService, Firestore veritabanı ile etkileşim kurmak için oluşturulmuş bir servis sınıfıdır.
// Bu sınıf, "gorevler" koleksiyonu üzerinden verileri alıp, Posts modeline dönüştürür.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeis/sabitler/model.dart';

class FirebaseService {
  // Firestore'daki "gorevler" koleksiyonuna erişim sağlamak için bir CollectionReference oluşturuluyor.
  // Bu koleksiyon, kullanıcıya ait görevleri içeriyor olabilir.
  final CollectionReference userCol = FirebaseFirestore.instance.collection(
    "gorevler",
  );

  // getUserPosts metodu, Firestore'dan "gorevler" koleksiyonundaki tüm dökümanları alır
  // ve bunları Posts modeline dönüştürerek asenkron olarak döndürür.
  Future<Posts> getUserPosts() async {
    // Firestore'daki "gorevler" koleksiyonundaki tüm dökümanları get() metodu ile alıyoruz.
    // Bu, veritabanındaki mevcut snapshot'ı getirir.
    QuerySnapshot querySnapshot = await userCol.get();
    
    // Alınan dökümanların her birinin verisini Map<String, dynamic> formatında bir listeye dönüştürüyoruz.
    // querySnapshot.docs, döküman listesine erişim sağlar.
    List<Map<String, dynamic>> docsData =
        querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>) // Her dökümanın data'sını Map formatında alıyoruz.
            .toList();
    
    // Posts modelinin beklentisine uygun formatta veriyi hazırlıyoruz.
    // Modelin JSON formatı {"gorevler": [doc1, doc2, ...]} şeklindedir.
    final postsModel = Posts.fromJson({"gorevler": docsData});
    
    // Hazırlanan Posts modelini geri döndürüyoruz.
    return postsModel;
  }

  // getUserPostsAsStream metodu, Firestore'daki "gorevler" koleksiyonunu gerçek zamanlı olarak dinler.
  // Koleksiyondaki her değişiklikte (ekleme, silme, güncelleme) stream üzerinde yeni Posts modeli yayınlanır.
  Stream<Posts> getUserPostsAsStream() {
    // userCol.snapshots() metodu, koleksiyonun her değişikliğinde güncel snapshot'ı veren bir Stream oluşturur.
    return userCol.snapshots().map((querySnapshot) {
      // Her snapshot'taki dökümanları Map formatında bir listeye dönüştürüyoruz.
      List<Map<String, dynamic>> docsData =
          querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
      
      // Yeni Posts modelini oluşturmak için JSON formatında veriyi kullanıyoruz.
      return Posts.fromJson({"gorevler": docsData});
    });
  }
}
