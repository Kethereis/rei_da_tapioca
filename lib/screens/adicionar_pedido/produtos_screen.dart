import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutosScreen extends StatefulWidget {
  ProdutosScreen({
    super.key,
    required this.categoria,
    required this.onConcluir,
  });

  final String categoria;
  final Function(List<Map<String, dynamic>>) onConcluir;

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final Map<String, int> selecionados = {};
  List<Map<String, dynamic>> produtos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('produtos')
          .where('categoria', isEqualTo: widget.categoria) // Filtra pela categoria
          .get();

      setState(() {
        produtos = snapshot.docs
            .map((doc) => {
          'id': doc.id,
          'titulo': doc['titulo'],
          'valor': doc['valor'],
        })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Produtos - ${widget.categoria}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final itens = selecionados.entries.map((e) {
            final produto = produtos.firstWhere((p) => p['id'] == e.key);
            return {
              'produto': produto['titulo'],
              'quantidade': e.value,
              'valor': produto['valor'],
            };
          }).toList();

          widget.onConcluir(itens);
        },
        child: Icon(Icons.check),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : produtos.isEmpty
          ? Center(child: Text('Nenhum produto encontrado.'))
          : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
        ),
        itemCount: produtos.length,
        itemBuilder: (context, index) {
          final produto = produtos[index];
          final quantidade = selecionados[produto['id']] ?? 0;

          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  produto['titulo'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('R\$ ${produto['valor'].toStringAsFixed(2)}'),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (quantidade > 0) {
                            selecionados[produto['id']] =
                                quantidade - 1;
                          }
                        });
                      },
                    ),
                    Text(
                      quantidade.toString(),
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          selecionados[produto['id']] =
                              quantidade + 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
