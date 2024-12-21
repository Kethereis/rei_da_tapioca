import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<QueryDocumentSnapshot>> buscarPedidos({
  DateTime? dataInicial,
  DateTime? dataFinal,
  String? funcionario,
  String? status,
  String? palavraChave,
  String? pesquisaMesa,

}) async {
  CollectionReference pedidos = FirebaseFirestore.instance.collection('pedidos');

  Query query = pedidos;

  if (dataInicial != null) {
    query = query.where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicial));
  }
  if (dataFinal != null) {
    query = query.where('data', isLessThanOrEqualTo: Timestamp.fromDate(dataFinal));
  }
  if (funcionario != null && funcionario.isNotEmpty) {
    query = query.where('atendente', isEqualTo: funcionario);
  }
  if (status != null && status.isNotEmpty) {
    print(status);
    query = query.where('status', isEqualTo: status);
  }
  if (palavraChave != null && palavraChave.isNotEmpty) {
    query = query.where('pedido', isEqualTo: palavraChave);
  }
  if (pesquisaMesa != null && pesquisaMesa.isNotEmpty) {
    query = query.where('mesa', isEqualTo: pesquisaMesa);
  }

  QuerySnapshot result = await query.get();
  return result.docs;
}
