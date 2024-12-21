import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rei_da_tapioca/screens/menu_admin/produtos.dart';

class CategoriasScreenAdmin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categorias'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('categorias').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final categorias = snapshot.data!.docs;

          return GridView.builder(
            itemCount: categorias.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('produtos')
                    .where('categoria', isEqualTo: categoria.id)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData) {
                    return Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Text(categoria['titulo'],
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                            )),
                        Text('Carregando...'),
                      ],)),
                    );
                  }

                  final productCount = productSnapshot.data!.docs.length;

                  return InkWell(
                    child: Card(
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(categoria['titulo'],
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          )),
                      SizedBox(height: 10,),
                      Text('$productCount produtos'),

                    ],))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProdutosScreenAdmin(categoria: categoria['titulo']),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddCategoriaDialog(context),
      ),
    );
  }

  void _showAddCategoriaDialog(BuildContext context) {
    final TextEditingController categoriaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Categoria'),
        content: TextField(
          controller: categoriaController,
          decoration: InputDecoration(hintText: 'Nome da Categoria'),
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Adicionar'),
            onPressed: () {
              final nomeCategoria = categoriaController.text.trim();
              if (nomeCategoria.isNotEmpty) {
                FirebaseFirestore.instance.collection('categorias').add({
                  'titulo': nomeCategoria,
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
