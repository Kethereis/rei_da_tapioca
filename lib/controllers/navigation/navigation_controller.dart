import 'package:flutter/material.dart';
import 'package:rei_da_tapioca/screens/adicionar_pedido/categorias_screen.dart';
import 'package:rei_da_tapioca/screens/menu_admin/categorias.dart';
import 'package:rei_da_tapioca/screens/menu_admin/produtos.dart';
import 'package:rei_da_tapioca/screens/menu_admin/usuarios.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../utils/constants.dart';
import '../stream_manager/stream_screens.dart';

class NavigationController extends StatefulWidget {
  NavigationController({super.key, required this.initialIndex});

  int initialIndex;

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Row(
        children: [
          // Menu Lateral
          Container(
            width: 200, // Largura do menu lateral
            color: AppConstants.appColorDefault, // Cor de fundo do menu
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DrawerHeader(
                  child: Image.asset('assets/imagem_login.jpg',
                  )
                ),
                buildMenuItem(Icons.home, 'Home', 0),
                buildMenuItem(Icons.category, 'Categorias', 1),
                buildMenuItem(Icons.shopping_basket, 'Produtos', 2),
                buildMenuItem(Icons.people, 'Atendentes', 3),
              ],
            ),
          ),
          // Área de Conteúdo
          Expanded(
            child: StreamBuilder<int>(
              stream: IndexManager().indexStream,
              initialData: 0,
              builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final index = snapshot.data!;
                return getPageWidget(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _currentIndex == index ? Colors.orange : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _currentIndex == index ? Colors.orange : Colors.white,
        ),
      ),
      onTap: () {
        setState(() {
          _currentIndex = index;
          IndexManager().updateIndex(index);
        });
      },
    );
  }

  Widget getPageWidget(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        return CategoriasScreenAdmin();
      case 2:
        return ProdutosScreenAdmin();
      case 3:
        return UserScreenAdmin();
      default:
        return HomeScreen();
    }
  }
}
