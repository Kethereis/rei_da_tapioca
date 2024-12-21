import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rei_da_tapioca/utils/constants.dart';
import 'package:rei_da_tapioca/widget/input_text_widget.dart';

import '../detalhes_pedido/detalhes_pedidos_screen.dart';

class NovoPedidoScreen extends StatefulWidget {
  @override
  _NovoPedidoScreenState createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  final TextEditingController _mesaController = TextEditingController();

  String generateUniqueSixDigitNumber() {
    final random = Random();
    int randomNumber = 100000 + random.nextInt(900000);
    int timestamp = DateTime.now().millisecondsSinceEpoch % 1000000;
    int uniqueNumber = (randomNumber + timestamp) % 1000000;
    return uniqueNumber.toString().padLeft(6, '0');
  }

  void _salvarPedido() {
    final pedido = {
      'mesa': _mesaController.text,
      'uid_atendente': AppConstants.idUsuario,
      'data': FieldValue.serverTimestamp(),
      'valor': 0.1,
      'pedido': generateUniqueSixDigitNumber(),
      'status': "Em Andamento",
      'forma_pagamento': "Indefinido",
      'atendente': AppConstants.nomeUsuario,
      'items': {}
    };

    FirebaseFirestore.instance.collection('pedidos').add(pedido).then((doc) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pedido adicionado com sucesso!")),
      );
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalhesPedidoScreen(pedido: pedido, docId: doc.id,),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao adicionar pedido: $error")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Pedido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
    child:Column(
      mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.6,
            child: InputTextWidget(controller: _mesaController, item: "Número da mesa", isNumber: true,)),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _salvarPedido,
              child: Text('Continuar'),
            ),
          ],
        )),
      ),
    );
  }
}
