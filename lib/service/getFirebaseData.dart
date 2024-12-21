import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para buscar dados de um documento
  Future<Map<String, dynamic>?> getDocumentData(String collectionName, String documentId) async {
    try {
      // Referência ao documento
      DocumentSnapshot documentSnapshot = await _firestore.collection(collectionName).doc(documentId).get();

      // Verifica se o documento existe
      if (documentSnapshot.exists) {
        // Retorna os dados do documento como um Map
        return documentSnapshot.data() as Map<String, dynamic>?;
      } else {
        print('Documento não encontrado na coleção $collectionName.');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar dados do Firestore: $e');
      return null;
    }
  }
}
