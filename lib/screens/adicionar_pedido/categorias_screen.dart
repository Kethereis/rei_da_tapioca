import 'package:flutter/material.dart';
import 'package:rei_da_tapioca/screens/adicionar_pedido/produtos_screen.dart';
import 'package:rei_da_tapioca/utils/constants.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({
    super.key,
    required this.onSelecionarItens
  });
  final Function(List<Map<String, dynamic>>) onSelecionarItens;

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery
        .sizeOf(context)
        .width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Categorias"),
      ),
        body: SafeArea(
          child:  GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
          childAspectRatio: 3 / 2,
        ),
      itemCount: AppConstants.categoriasData.length,
      itemBuilder: (context, index) {
        final category = AppConstants.categoriasData[index];
        return GestureDetector(
          onTap: () async {
            final itensSelecionados = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProdutosScreen(
                  categoria: category,
                  onConcluir: (itensSelecionados) {
                    widget.onSelecionarItens(itensSelecionados);
                    Navigator.pop(context, itensSelecionados); // Retorna os itens selecionados
                  },
                ),
              ),
            );
            // Verifica se existem itens selecionados e passa para `onSelecionarItens`
            if (itensSelecionados != null) {
             // Navigator.pop(context, itensSelecionados); // Passa para a tela original
            }
          },

          child: Card(
            child: Center(
              child: Text(category.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold
              ),),
            ),
          ),
        );
      },
    ),
    ),
        );
  }

}
