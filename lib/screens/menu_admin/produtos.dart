import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutosScreenAdmin extends StatelessWidget {
  final String? categoria;

  ProdutosScreenAdmin({this.categoria});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produtos'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('produtos')
            .where('categoria', isEqualTo: categoria)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final produtos = snapshot.data!.docs;

          if (produtos.isEmpty) {
            return Center(child: Text('Nenhum produto encontrado.'));
          }

          return GridView.builder(
            itemCount: produtos.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return Card(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: Center(
                child: Text(produto['titulo'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),)),
              );
            },
          );
        },
      ),
    );
  }
}
