import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting (add dependency if needed: flutter pub add intl)

// --- Constants for Colors ---
const kBackgroundColor = Color(0xFF1D1E33);
const kAppBarColor = Color(0xFF1D1E33); // Or slightly different if needed
const kAppBarTextColor = Color.fromARGB(255, 230, 230, 255); // Softer white
const kInputBackgroundColor = Color.fromARGB(
  255,
  20,
  22,
  50,
); // Slightly darker input bg
const kHintTextColor = Color(0xFF6b7a8f); // Adjusted hint color
const kMyMessageBubbleColor = Color(0xFF007AFF); // Standard blue for sender
const kOtherMessageBubbleColor = Color(0xFF3A3A3C); // Dark grey for receiver
const kTimestampColor = Color(0xFFB0B0B0);
const kIconColor = Color(0xFF8E8E93);
const kDeleteIconColor = Color(0xFFFF453A); // iOS-like delete red
const kSendButtonColor = Color(0xFF007AFF); // Match sender bubble
const kDialogTextColor = Colors.white;
const kDialogMutedTextColor = Colors.white70;
const kDialogActionColorPrimary = Color(0xFF0A84FF); // iOS-like blue action
const kDialogActionColorDestructive = kDeleteIconColor;

class Duty extends StatefulWidget {
  final String receiverId;
  final String receiverEmail; // Keep if needed for display elsewhere

  const Duty({
    Key? key,
    required this.receiverId,
    required this.receiverEmail, // You might use this in the AppBar title
  }) : super(key: key);

  @override
  State<Duty> createState() => _DutyState();
}

// _DutyState, Duty adlı widget'ın durum (state) yönetimini sağlayan sınıfıdır.
// Flutter'da stateful widget'lar, UI'nin dinamik olarak güncellenebilmesi için durumlarını saklarlar.
class _DutyState extends State<Duty> {
  // Kullanıcının mesaj girişi için kullanılan TextEditingController.
  // Bu controller, TextField gibi widget'lardan girilen metni kontrol etmek ve güncellemek için kullanılır.
  final TextEditingController _messageController = TextEditingController();
  
  // ScrollController, mesaj listesinin kaydırma davranışını yönetir.
  // Bu controller ile liste kaydırma konumu kontrol edilebilir, örneğin yeni mesaj geldiğinde otomatik kaydırma yapılabilir.
  final ScrollController _scrollController = ScrollController();
  
  // FirebaseAuth instance'ı, Firebase Authentication servisine erişim sağlar.
  // Kullanıcının kimlik doğrulaması ve oturum yönetimi için kullanılır.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // FirebaseFirestore instance'ı, Firestore veritabanı ile etkileşim kurmak için kullanılır.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // _currentUserId: Geçerli kullanıcının benzersiz ID'sini saklar.
  // _chatId: İki kullanıcı arasında oluşturulan sohbetin benzersiz kimliğini saklar.
  late final String _currentUserId;
  late final String _chatId;
  
  // _isSending bayrağı, mesaj gönderme işleminin kilitlenmesini sağlar.
  // Böylece kullanıcı, mesaj gönderme işlemi devam ederken tekrar göndermeyi tetiklemez.
  bool _isSending = false; // Çift gönderimi önlemek için

  @override
  void initState() {
    // initState, widget ilk oluşturulduğunda çalışan yaşam döngüsü metodudur.
    super.initState();
    
    // Kullanıcının oturum açmış olup olmadığını kontrol eder.
    // Eğer kullanıcı oturum açmamışsa hata durumunu yönetir.
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Eğer kullanıcı oturum açmamışsa burada hata yönetimi yapılabilir.
      // Örneğin, sayfadan çıkma (pop) veya hata mesajı gösterme işlemi gerçekleştirilebilir.
      print("Error: Current user is null in Duty screen initState.");
      // Gerçek uygulamada Navigator.pop(context) gibi yönlendirme yapılabilir.
      _currentUserId = "error_user_not_found"; // Yer tutucu değer atanıyor.
      _chatId = "error_chat_id";
      return; // initState'den erken çıkılır.
    }
    
    // Oturum açmış kullanıcının ID'si alınır.
    _currentUserId = currentUser.uid;
    
    // Sohbetin benzersiz kimliği oluşturulur.
    _createChatId();
  }

  @override
  void dispose() {
    // dispose, widget yok edilirken kaynakların serbest bırakılması için çağrılır.
    // TextEditingController ve ScrollController gibi controller'ların dispose edilmesi önemlidir.
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // _createChatId metodu, sohbet için benzersiz bir kimlik oluşturur.
  // İki kullanıcının ID'lerini sıralayarak, sohbetin başlatan kullanıcısına bağlı olmaksızın sabit bir kimlik elde edilir.
  void _createChatId() {
    // İki kullanıcı ID'sini listeye alıp, sıralıyoruz.
    List<String> ids = [_currentUserId, widget.receiverId];
    ids.sort();
    // Sıralanmış ID'ler, alt çizgiyle birleştirilir.
    _chatId = ids.join('_');
  }

  // _sendMessage metodu, kullanıcının girdiği mesajı Firestore veritabanına gönderir.
  Future<void> _sendMessage() async {
    // Eğer mesaj gönderme işlemi devam ediyorsa, tekrar işlem yapılmasını önler.
    if (_isSending) return; // Hızlı tekrar gönderimleri önlemek için

    // Mesajın başındaki ve sonundaki boşluklar temizlenir.
    final String messageText = _messageController.text.trim();
    final User? user = _auth.currentUser;

    // Mesaj boş değilse ve kullanıcı oturum açmışsa gönderme işlemi başlar.
    if (messageText.isNotEmpty && user != null) {
      setState(() {
        _isSending = true; // Gönderme işlemi kilitlenir
      });
      _messageController.clear(); // Kullanıcı deneyimi için metin kutusu hemen temizlenir

      try {
        // Firestore'da 'chats' koleksiyonu altındaki ilgili sohbet belgesine,
        // 'messages' alt koleksiyonu oluşturularak mesaj eklenir.
        await _firestore
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .add({
          'text': messageText, // Mesaj metni
          'senderId': user.uid, // Gönderenin ID'si
          'receiverId': widget.receiverId, // Alıcının ID'si, sorgular için faydalıdır
          'timestamp': FieldValue.serverTimestamp(), // Sunucu zaman damgası, mesaj sıralaması için güvenilir
        });

        // İsteğe bağlı: Sohbetin ana belgesinde son mesaj bilgisi güncellenebilir.
        // Yorum satırında örnek kod gösterilmiştir.
        /*
        await _firestore.collection('chats').doc(_chatId).set({
          'lastMessage': messageText,
          'lastTimestamp': FieldValue.serverTimestamp(),
          'participants': [_currentUserId, widget.receiverId],
        }, SetOptions(merge: true)); // merge:true, diğer alanların üzerine yazılmamasını sağlar.
        */

        // Mesaj gönderildikten sonra otomatik kaydırma işlemi yapılabilir.
        // Bu örnekte, StreamBuilder güncellemeleri kaydırmayı yönetebilir.
      } catch (e) {
        // Hata durumunda konsola yazdırılır ve kullanıcıya hata mesajı gösterilir.
        print("Error sending message: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mesaj gönderilemedi: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
          // İsteğe bağlı: Mesaj gönderilemezse metin tekrar metin kutusuna yazılabilir.
          // _messageController.text = messageText;
        }
      } finally {
        // İsteğe bağlı: Gönderme işlemi tamamlandıktan sonra kilit kaldırılır.
        if (mounted) {
          setState(() {
            _isSending = false; // Gönderme kilidi kaldırılır
          });
        }
      }
    }
  }

  // _deleteMessage metodu, Firestore'dan belirli bir mesajı silmek için kullanılır.
  // Mesaj silinmeden önce kullanıcıdan onay alınır.
  Future<void> _deleteMessage(String messageId) async {
    // Kullanıcıya mesajı silmek istediğini doğrulaması için onay kutusu gösterilir.
    final bool? confirmDelete = await _showDeleteConfirmationDialog();
    if (confirmDelete != true) {
      return; // Kullanıcı silme işlemini iptal ettiyse çıkılır.
    }

    try {
      // Belirtilen mesaj ID'sine sahip mesaj, Firestore'dan silinir.
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (mounted) {
        // Silme başarılı olduğunda kullanıcıya bildirim gösterilir.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj silindi.'),
            backgroundColor: kDeleteIconColor, // Silme işlemi için belirlenmiş renk
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda konsola yazdırılır ve kullanıcıya hata mesajı gösterilir.
      print("Error deleting message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj silinemedi: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // _showDeleteConfirmationDialog, mesaj silme işlemi öncesinde kullanıcıdan onay almak için kullanılan yardımcı fonksiyondur.
  // Bu fonksiyon, AlertDialog gösterir ve kullanıcının verdiği kararı döndürür.
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kInputBackgroundColor, // Diyalog için belirlenmiş arka plan rengi
        title: const Text(
          'Mesajı Sil',
          style: TextStyle(color: kDialogTextColor), // Diyalog başlık metni rengi
        ),
        content: const Text(
          'Bu mesajı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: kDialogMutedTextColor), // Diyalog içerik metni rengi
        ),
        actions: [
          // İptal butonu: Kullanıcı diyaloğu iptal ederse false döner.
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'İptal',
              style: TextStyle(color: kDialogActionColorPrimary), // İptal butonu rengi
            ),
          ),
          // Sil butonu: Kullanıcı onay verirse true döner.
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sil',
              style: TextStyle(color: kDialogActionColorDestructive), // Silme işlemi için belirlenmiş yıkıcı renk
            ),
          ),
        ],
      ),
    );
  }

// Bu fonksiyon, mesaj listesinin en altına kaydırmak için kullanılır.
void _scrollToBottom() {
  // addPostFrameCallback, widget ağacı tamamen çizildikten sonra çalıştırılacak kodu zamanlar.
  // Böylece layout tamamlanmadan kaydırma işlemi yapılmaz.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Eğer ScrollController bağlı olduğu widget (ListView gibi) varsa çalıştır.
    if (_scrollController.hasClients) {
      // animateTo fonksiyonu, belirtilen konuma animasyonlu şekilde kaydırır.
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // Liste sonuna (en alt) kaydır.
        duration: const Duration(milliseconds: 300), // Animasyon süresi: 300 ms.
        curve: Curves.easeOut, // Animasyon eğrisi: yavaşça bitiş.
      );
    }
  });
}

@override
Widget build(BuildContext context) {
  // Scaffold, temel görsel yapıyı (app bar, body, vs.) sağlayan Material Design widget'ıdır.
  return Scaffold(
    // AppBar, üst kısımda yer alan başlık çubuğunu oluşturur.
    appBar: AppBar(
      // Uygulama başlığı; burada alıcının e-posta adresi veya ismi gösterilebilir.
      title: Text(
        "Mesajlar",
        style: const TextStyle(color: kAppBarTextColor, fontSize: 16),
        overflow: TextOverflow.ellipsis, // Uzun metinlerde ellipsis (...) ekler.
      ),
      backgroundColor: kAppBarColor, // AppBar'ın arka plan rengi.
      elevation: 1.0, // Hafif gölge efekti.
      iconTheme: const IconThemeData(
        color: kAppBarTextColor, // Geri butonu ve diğer ikonların rengi.
      ),
    ),
    backgroundColor: kBackgroundColor, // Scaffold'un genel arka plan rengi.
    // Gövde (body) olarak, dikey bir sütun (Column) kullanılır.
    body: Column(
      children: [
        // --- Mesaj Listesi --- 
        // Expanded widget, kendisini çevreleyen Column içinde kalan tüm alanı kaplamasını sağlar.
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Firestore'dan mesaj verilerini gerçek zamanlı dinlemek için kullanılır.
            stream: _firestore
                .collection('chats') // 'chats' koleksiyonunu seç.
                .doc(_chatId) // Belirli sohbet (chat) dokümanını seç.
                .collection('messages') // Mesajlar alt koleksiyonunu seç.
                .orderBy(
                  'timestamp', // Mesajları zaman damgasına göre sırala.
                  descending: false, // Artan sırada (eski mesajlar önce) sırala.
                )
                .snapshots(), // Verilerdeki değişiklikleri gerçek zamanlı olarak dinle.
            builder: (context, snapshot) {
              // Bağlantı durumu bekleme aşamasındaysa, yükleniyor göstergesi (CircularProgressIndicator) göster.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Eğer hata oluştuysa, hata mesajı gösterilir.
              if (snapshot.hasError) {
                print("Firestore Stream Error: ${snapshot.error}");
                return Center(
                  child: Text(
                    'Mesajlar yüklenemedi: ${snapshot.error}',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              // Veri yoksa veya gelen doküman listesi boşsa, "Henüz mesaj yok..." metni gösterilir.
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Henüz mesaj yok...',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // Yeni mesajlar geldikçe otomatik olarak liste en altına kaydırılır.
              _scrollToBottom();

              // Firestore'dan gelen mesaj dokümanlarını al.
              var messages = snapshot.data!.docs;

              // ListView.builder, uzun listelerde performanslı liste oluşturmak için kullanılır.
              return ListView.builder(
                controller: _scrollController, // Liste kaydırma kontrolü.
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                itemCount: messages.length, // Liste eleman sayısı.
                itemBuilder: (context, index) {
                  // Her bir mesaj dokümanunu al.
                  var messageDoc = messages[index];
                  // Dokümandaki verileri Map olarak dönüştür.
                  var messageData = messageDoc.data() as Map<String, dynamic>;
                  // Mesajı gönderenin kimliğinin, geçerli kullanıcı ile eşleşip eşleşmediğini kontrol et.
                  bool isMe = messageData['senderId'] == _currentUserId;
                  // Mesajın zaman damgasını al (varsa).
                  Timestamp? timestamp = messageData['timestamp'] as Timestamp?;

                  // MessageBubble widget'ı, her mesajı görsel olarak temsil eder.
                  return MessageBubble(
                    messageId: messageDoc.id, // Doküman ID'si, mesajın benzersiz kimliği.
                    message: messageData['text'] ?? '', // Mesaj metni; null kontrolü yapılır.
                    isMe: isMe, // Mesajın gönderici bilgisine göre stil ayarlaması yapılabilir.
                    time: timestamp?.toDate(), // Zaman damgası DateTime formatına çevrilir.
                    onDelete: isMe ? _deleteMessage : null, // Sadece kendi mesajlarını silebilmek için.
                  );
                },
              );
            },
          ),
        ),

        // --- Mesaj Giriş Alanı ---
        // Kullanıcının mesaj yazıp gönderebileceği alan; _buildMessageInput() metodu, bu alanın widget ağacını oluşturur.
        _buildMessageInput(),
      ],
    ),
  );
}
// Mesaj giriş alanını oluşturmak için ayrı bir widget.
// Bu widget, kullanıcının mesaj yazması ve göndermesi için tasarlanmıştır.
Widget _buildMessageInput() {
  return Container(
    // Container widget, içerisindeki öğeleri konumlandırmak ve stil vermek için kullanılır.
    // Burada kenarlardan padding (iç boşluk) eklenmiştir.
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    // Dekorasyon, Container'ın arka plan rengini ve üst kısmında ince bir sınır çizgisini belirler.
    decoration: const BoxDecoration(
      color: kInputBackgroundColor, // Giriş alanı için belirlenmiş arka plan rengi
      border: Border(
        top: BorderSide(color: Colors.black26, width: 0.5), // Üst kenarda ince bir sınır
      ),
    ),
    child: SafeArea(
      // SafeArea widget, sistem UI (örneğin, cihazın altındaki home bar gibi) ile çakışmayı önler.
      child: Row(
        // Row widget, içindeki çocukları yatay olarak sıralar.
        children: [
          Expanded(
            // Expanded, Row içerisinde kalan alanı kaplaması için kullanılır.
            child: TextField(
              // TextField, kullanıcının metin girişi yapabileceği alanı oluşturur.
              controller: _messageController, // _messageController ile girilen metin kontrol edilir.
              style: const TextStyle(color: Colors.white), // Girilen metnin rengi beyaz olarak ayarlanır.
              decoration: const InputDecoration(
                hintText: 'Mesaj yaz...', // Kullanıcıya mesaj girişi yapması için ipucu metin
                hintStyle: TextStyle(color: kHintTextColor), // İpucu metnin rengi
                border: InputBorder.none, // Alt çizgi gibi varsayılan kenarlıklar kaldırılır.
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.0, // Yatay iç boşluk
                  vertical: 10.0,   // Dikey iç boşluk
                ),
              ),
              textCapitalization: TextCapitalization.sentences, 
              // Girilen metinde cümle başlarını otomatik büyük harfe çevirir.
              minLines: 1, // En az 1 satır metin girişi olacak şekilde ayarlanır.
              maxLines: 5, // Maksimum 5 satıra kadar çok satırlı metin girişi sağlanır.
              onSubmitted: (_) => _sendMessage(), 
              // Klavyeden "submit" (örneğin, enter tuşu) yapıldığında _sendMessage() fonksiyonu tetiklenir.
            ),
          ),
          // Gönder butonu: Kullanıcının mesajı göndermesi için ikon butonu.
          IconButton(
            icon: Icon(
              Icons.send, // 'send' (gönder) ikonu kullanılır.
              // Eğer mesaj gönderme işlemi devam ediyorsa ikon rengi gri, aksi halde belirlenmiş gönderme rengi kullanılır.
              color: _isSending ? Colors.grey : kSendButtonColor,
            ),
            // Eğer mesaj gönderme işlemi devam ediyorsa (isSending true ise), buton devre dışı bırakılır.
            onPressed: _isSending ? null : _sendMessage,
            tooltip: 'Gönder', // Butonun üzerine gelindiğinde gösterilecek açıklama.
          ),
        ],
      ),
    ),
  );
}
}

// --- Message Bubble Widget ---
// MessageBubble, her bir mesajı görsel olarak temsil eden stateless widget'tır.
// Stateless widget kullanılarak, mesajın içeriği, gönderen bilgisi, zaman bilgisi gibi
// veriler widget'ın parametreleri üzerinden alınır ve görüntülenir.
class MessageBubble extends StatelessWidget {
  // Mesajın benzersiz ID'si (örn. Firestore'daki doküman ID'si)
  final String messageId;
  // Mesaj metni
  final String message;
  // Mesajı gönderenin geçerli kullanıcıya ait olup olmadığını belirten bayrak.
  // true ise mesajı gönderen "ben" (geçerli kullanıcı) demektir.
  final bool isMe;
  // Mesajın gönderilme zamanı (opsiyonel, null olabilir)
  final DateTime? time;
  // Mesaj silme işlemi için geri çağırma fonksiyonu (callback). 
  // Eğer null değilse, mesaj silme butonu gösterilir.
  final Function(String messageId)? onDelete;

  // Constructor: Zorunlu parametreler messageId, message ve isMe olarak belirlenmiş,
  // zaman ve onDelete opsiyonel parametrelerdir.
  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.message,
    required this.isMe,
    this.time,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Zaman bilgisini biçimlendirme:
    // Eğer 'time' null değilse, 'HH:mm' formatında (örn. 14:35) biçimlendirilir.
    // 'intl' paketinin DateFormat sınıfı kullanılarak yerelleştirme destekli biçimlendirme yapılabilir.
    // Eğer time null ise, placeholder olarak '--:--' gösterilir.
    final String formattedTime =
        time != null ? DateFormat('HH:mm').format(time!) : '--:--';

    return Padding(
      // Mesaj balonları arasına dikey ve yatay boşluk eklemek için Padding kullanılır.
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        // Mesaj balonlarını gönderene göre hizalamak için Row kullanılır.
        // Eğer mesajı ben gönderdi isem (isMe true), mesaj sağa hizalanır;
        // aksi halde sola hizalanır.
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        // Satır içerisindeki öğelerin alt kısımda hizalanmasını sağlar.
        // Bu, ileride avatar gibi öğeler eklendiğinde dikey hizalamayı düzenler.
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Eğer mesajı ben gönderdiğim (isMe true) ve onDelete fonksiyonu sağlandıysa,
          // mesaj silme butonunu göster.
          if (isMe && onDelete != null)
            Padding(
              // Mesaj balonundan önce (sağa yakın) boşluk eklemek için.
              padding: const EdgeInsets.only(
                right: 6.0,
                bottom: 0,
              ),
              child: IconButton(
                // Silme işlemi için silme ikonu kullanılır.
                icon: const Icon(
                  Icons.delete_outline,
                  color: kIconColor, // İkon rengi, uygulamanın tema rengine uygun ayarlanmış.
                  size: 18, // İkon boyutu
                ),
                // Butona basıldığında onDelete callback'ini çağırır,
                // mesajId parametresini geçirir.
                onPressed: () => onDelete!(messageId),
                padding: EdgeInsets.zero, // Varsayılan padding kaldırılır.
                constraints: const BoxConstraints(), // Varsayılan buton kısıtlamaları kaldırılır.
                tooltip: 'Mesajı Sil', // Buton üzerine gelindiğinde gösterilecek açıklama.
                splashRadius: 20, // Dokunma efektinin yarıçapı.
              ),
            ),

          // Mesaj içeriğini gösteren balon (bubble)
          Flexible(
            // Flexible widget, mesaj balonunun aşırı genişlemesini engeller.
            child: Container(
              // Mesaj balonunun maksimum genişliğini belirler.
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Material(
                // Material widget, mesaja materyal tasarımı özellikleri (gölge, renk, köşe yuvarlama) ekler.
                // Köşe yuvarlama ayarları, gönderenin kimliğine göre farklılık gösterir.
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 18 : 4),
                  // Eğer mesajı ben gönderdiğim ise, sol üst köşe daha yuvarlak,
                  // aksi halde daha keskin.
                  topRight: Radius.circular(isMe ? 4 : 18),
                  // Sağ üst köşe de benzer şekilde ayarlanır.
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                elevation: 1.0, // İnce bir gölge efekti
                // Mesaj balonunun arka plan rengi, mesajı gönderen kullanıcıya göre ayarlanır.
                color: isMe ? kMyMessageBubbleColor : kOtherMessageBubbleColor,
                child: Padding(
                  // Mesaj metni ve zaman bilgisinin arasında ve kenarlarda boşluk ekler.
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  child: Column(
                    // Mesaj metni ve zaman bilgisini dikey olarak sıralar.
                    // Mesajın gönderici durumuna göre metin hizalaması değiştirilir.
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Mesaj metninin görüntülendiği Text widget'ı.
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white, // Mesaj metni rengi
                          fontSize: 16, // Yazı boyutu
                          height: 1.3, // Satır yüksekliği, metin okunabilirliğini artırır.
                        ),
                      ),
                      const SizedBox(height: 4), // Mesaj metni ile zaman arasında boşluk.
                      // Zaman bilgisini gösteren Text widget'ı.
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: kTimestampColor, // Zaman metni rengi
                          fontSize: 10, // Küçük yazı boyutu
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Eğer mesajı ben göndermediğim (isMe false) ve silme butonu yoksa,
          // sağda boşluk bırakılarak hizalamanın dengelenmesi sağlanır.
          if (!isMe && onDelete == null)
            const SizedBox(width: 44), // IconButton ve padding genişliği kadar boşluk.
        ],
      ),
    );
  }
}
