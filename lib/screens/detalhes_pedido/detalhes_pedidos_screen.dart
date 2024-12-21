import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rei_da_tapioca/screens/adicionar_pedido/categorias_screen.dart';
import 'package:rei_da_tapioca/screens/home/home_screen.dart';
import 'package:rei_da_tapioca/widget/input_text_widget.dart';

import '../../utils/constants.dart';

class DetalhesPedidoScreen extends StatefulWidget {
  final Map pedido;
  String docId;

  DetalhesPedidoScreen({required this.pedido, required this.docId});

  @override
  State<DetalhesPedidoScreen> createState() => _DetalhesPedidoScreenState();
}

class _DetalhesPedidoScreenState extends State<DetalhesPedidoScreen> {
  TextEditingController _mesaController = TextEditingController();

  TextEditingController _pedidoController = TextEditingController();

  TextEditingController _valorController = TextEditingController();

  late List<String> _atendentes = [];

  String? _selectedAtendente;
  String? _selectedStatus;
  String? _selectedFormaPagamento;

  Map<String, TextEditingController> _produtoControllers = {};
  Map<String, TextEditingController> _quantidadeControllers = {};
  Map<String, TextEditingController> _valorControllers = {};

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Excluir Pedido"),
          content: Text("Tem certeza de que deseja excluir o pedido ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                // Excluir pedido do Firebase
                FirebaseFirestore.instance
                    .collection('pedidos')
                    .doc(widget.docId)
                    .delete();

                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                );


              },
              child: Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> buscarNomesUsuarios() async {
    List<String> nomes = [];

    try {
      // Obtem todos os documentos da coleção 'usuarios'
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('usuarios').get();

      // Itera sobre os documentos e extrai o campo 'nome'
      for (var doc in snapshot.docs) {
        if (doc.data() is Map<String, dynamic>) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('nome') && data['nome'] is String) {
            nomes.add(data['nome']);
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar usuários: $e');
    }

    return nomes;
  }

  void carregarNomesUsuarios() async {
    try {
      setState(() {
        _atendentes = buscarNomesUsuarios() as List<String>;
        _selectedAtendente = widget.pedido['atendente'];
      });
    }catch (e){}
  }

  void _adicionarItem() async {
    // Redireciona para a tela de categorias e espera os itens selecionados
    List<Map<String, dynamic>> novosItens = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasScreen(
          onSelecionarItens: (itens) {
            Navigator.pop(context, itens); // Retorna os itens selecionados
          },
        ),
      ),
    );
    print(novosItens);

    if (novosItens != null && novosItens.isNotEmpty) {
      setState(() {
        for (var item in novosItens) {
          // Gera uma chave única para cada novo item
          final newKey = DateTime.now().millisecondsSinceEpoch.toString();

          // Adiciona o item ao pedido
          widget.pedido['items'][newKey] = {
            'nome': item['produto'], // Nome do produto selecionado
            'quantidade': item['quantidade'],
            'valor': item['valor'], // Valor inicial (pode ajustar conforme necessário)
          };

          // Inicializa os controladores para o novo item
          _produtoControllers[newKey] = TextEditingController(text: item['produto']);
          _quantidadeControllers[newKey] = TextEditingController(text: item['quantidade'].toString());
          _valorControllers[newKey] = TextEditingController(text: doubleToReal(item['valor']));
        }
      });
    } else {
      // Caso não sejam adicionados itens (ex.: usuário cancelou)
      print("Nenhum item foi adicionado.");
    }
  }

  void _removerItem(String nomeProduto) {
    setState(() {
      widget.pedido['items'].remove(nomeProduto);
    });
  }

  void _atualizarItem(String nomeProduto, int quantidade, double valor) {
    setState(() {
      if (widget.pedido['items'].containsKey(nomeProduto)) {
        widget.pedido['items'][nomeProduto] = {
          'quantidade': quantidade,
          'valor': valor,
        };
      }
    });
  }
  @override
  void dispose() {
    _quantidadeControllers.values.forEach((controller) => controller.dispose());
    _valorControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }


  void _salvarAlteracoes() {
    // Cria um novo mapa para os itens com o nome correto como chave
    final Map<String, dynamic> updatedItems = {};
    double totalValor = 0.0; // Variável para armazenar o valor total

    widget.pedido['items'].forEach((key, item) {
      final nomeProduto = _produtoControllers[key]?.text ?? '';
      if (nomeProduto.isNotEmpty) {
        final quantidade =
        int.parse(_quantidadeControllers[key]?.text ?? '0');
        final valorUnitario = double.parse(
            _valorControllers[key]?.text.replaceAll("R\$", "").trim().replaceAll(",", ".") ?? '0.0');
        final valorTotalItem = quantidade * valorUnitario;

        // Adiciona o item com o nome do produto como chave
        updatedItems[nomeProduto] = {
          'quantidade': quantidade,
          'valor': valorUnitario,
        };

        // Soma o valor total deste item ao total geral
        totalValor += valorTotalItem;
      }
    });

    // Atualiza no Firebase
    FirebaseFirestore.instance
        .collection('pedidos')
        .doc(widget.docId)
        .update({
      'mesa': _mesaController.text,
      'valor': totalValor, // Envia o valor total calculado
      'status': _selectedStatus,
      'forma_pagamento': _selectedFormaPagamento,
      'atendente': _selectedAtendente,
      'items': updatedItems, // Salva o mapa atualizado
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pedido atualizado com sucesso!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao atualizar pedido: $error")),
      );
      Navigator.pop(context);

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    carregarNomesUsuarios();
    _mesaController.text = widget.pedido['mesa'];
    _pedidoController.text = widget.pedido['pedido'];
    _valorController.text = doubleToReal(widget.pedido['valor']);
    _selectedStatus = widget.pedido['status'];
    _selectedFormaPagamento = widget.pedido['forma_pagamento'];

    if (widget.pedido['items'] != null) {
      widget.pedido['items'].forEach((key, item) {
        _produtoControllers[key] = TextEditingController(text: key);
        _quantidadeControllers[key] =
            TextEditingController(text: item['quantidade'].toString());
        _valorControllers[key] =
            TextEditingController(text: doubleToReal(item['valor']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery
        .sizeOf(context)
        .width;
    return Scaffold(
        body: SafeArea(
          child: _width < 1200 ? _layoutMobile() : _layoutWeb(),
        ));
  }

  String doubleToReal(double value) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return formatter.format(value);
  }

  Widget _layoutWeb(){
    double _width = MediaQuery.sizeOf(context).width;
    var items = widget.pedido['items'];
    return Scaffold(
        appBar: AppBar(
          title: Text("Detalhes do Pedido #${widget.pedido['pedido']}"),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 0.2,
                        ),
                      ),
                      child: DropdownButton<String>(
                        hint: Text("Selecione um Status"),
                        value: _selectedStatus,
                        underline: SizedBox.shrink(),
                        alignment: AlignmentDirectional.center,
                        items: AppConstants.statusData.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                            alignment: AlignmentDirectional.center,
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        },
                      )),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 0.2,
                        ),
                      ),
                      child: DropdownButton<String>(
                        hint: Text("Forma de Pagamento"),
                        value: _selectedFormaPagamento,
                        underline: SizedBox.shrink(),
                        alignment: AlignmentDirectional.center,
                        items: AppConstants.meiosPagamentoData.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                            alignment: AlignmentDirectional.center,
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFormaPagamento = newValue;
                          });
                        },
                      )),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 0.2,
                        ),
                      ),
                      child: DropdownButton<String>(
                        hint: Text("Selecione um Atendente"),
                        underline: SizedBox.shrink(),
                        value: _selectedAtendente,
                        alignment: AlignmentDirectional.center,
                        items: _atendentes.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                            alignment: AlignmentDirectional.center,
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAtendente = newValue;
                          });
                        },
                      )),
                  SizedBox(
                    width: _width * 0.15,
                    child: InputTextWidget(
                        controller: _mesaController, item: "Mesa"),
                  ),
                  SizedBox(
                    width: _width * 0.15,
                    child: InputTextWidget(
                        controller: _valorController, item: "Valor"),
                  ),
                ],
              ),

              SizedBox(
                height: 50,
              ),

              Divider(),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Items do Pedido",
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle),
                        onPressed: () {
                          _adicionarItem();
                        },
                      ),
                    ],
                  )),
              SizedBox(
                height: 30,
              ),
              Column(
                children: [
                  // ListView para exibir os itens
                  ListView.builder(
                    shrinkWrap: true,
                    // Permite que o ListView interno calcule seu tamanho com base no conteúdo.
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.keys.length,
                    itemBuilder: (context, index) {
                      String itemKey = items.keys.elementAt(index);
                      var item = items[itemKey];
                      return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: _width * 0.15,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,

                                  controller: _produtoControllers[itemKey],
                                  onChanged: (value) {
                                    _atualizarItem(
                                        value, item['quantidade'], item['valor']);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Produto",
                                    labelText: "Produto",
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(5.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),

                              Container(
                                width: _width * 0.15,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,

                                  controller: _quantidadeControllers[itemKey],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _atualizarItem(
                                        itemKey, int.parse(value), item['valor']);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Quantidade",
                                    labelText: "Quantidade",
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(5.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),

                              Container(
                                  width: _width * 0.15,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    controller: _valorControllers[itemKey],
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _atualizarItem(
                                          itemKey,
                                          item['quantidade'],
                                          double.parse(value.replaceAll("R\$ ", "").replaceAll(",", ".").trim()));
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Valor",
                                      labelText: "Valor",
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(5.0),
                                    ),
                                  )),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _removerItem(itemKey);
                                },
                              ),


                            ],
                          ));
                    },
                  ),
                  SizedBox(height: 10,)
                ],
              ),
              SizedBox(
                height: 50,
              ),

              // Botão para salvar alterações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        onTap: () {
                          _salvarAlteracoes();
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            "Salvar Alterações",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        onTap: () {
                          _showDeleteDialog(context);
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            "Excluir Pedido",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        )),
                  ),
                ],
              )
            ],
          ),
        ));
  }
  Widget _layoutMobile(){
    double _width = MediaQuery.sizeOf(context).width;
    var items = widget.pedido['items'];
    return Scaffold(
        appBar: AppBar(
          title: Text("Pedido #${widget.pedido['pedido']}",
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 0.2,
                        ),
                      ),
                      child: DropdownButton<String>(
                        hint: Text("Forma de Pagamento"),
                        value: _selectedFormaPagamento,
                        underline: SizedBox.shrink(),
                        alignment: AlignmentDirectional.center,
                        items: AppConstants.meiosPagamentoData.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                            alignment: AlignmentDirectional.center,
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFormaPagamento = newValue;
                          });
                        },
                      )),
                  SizedBox(
                    width: _width * 0.4,
                    child: InputTextWidget(
                        controller: _mesaController, item: "Mesa", isNumber: true,),
                  ),
                ],
              ),

              SizedBox(
                height: 20,
              ),

              Divider(),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Items do Pedido",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                            onTap: _adicionarItem,
                            child: Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: AppConstants.appPrimaryColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                Icon(Icons.add_circle, size: 20, color: Colors.white,),
                                SizedBox(width: 5,),

                                Text(
                                "Adicionar Item",
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),],)
                            )),
                      ),

                    ],
                  )),
              SizedBox(
                height: 10,
              ),
               Column(
                children: [
                  // ListView para exibir os itens
                  ListView.builder(
                    shrinkWrap: true,
                    // Permite que o ListView interno calcule seu tamanho com base no conteúdo.
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: items.keys.length,
                    itemBuilder: (context, index) {
                      String itemKey = items.keys.elementAt(index);
                      var item = items[itemKey];
                      return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: _width * 0.25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,

                                  controller: _produtoControllers[itemKey],
                                  onChanged: (value) {
                                    _atualizarItem(
                                        value, item['quantidade'], item['valor']);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Produto",
                                    labelText: "Produto",
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(5.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),

                              Container(
                                width: _width * 0.25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  controller: _quantidadeControllers[itemKey],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _atualizarItem(
                                        itemKey, int.parse(value), item['valor']);
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Quantidade",
                                    labelText: "Quantidade",
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(5.0),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10,),

                              Container(
                                  width: _width * 0.25,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: TextField(
                                    textAlign: TextAlign.center,
                                    controller: _valorControllers[itemKey],
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      _atualizarItem(
                                          itemKey,
                                          item['quantidade'],
                                          double.parse(value.replaceAll("R\$ ", "").replaceAll(",", ".").trim()));
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Valor",
                                      labelText: "Valor",
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(5.0),
                                    ),
                                  )),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _removerItem(itemKey);
                                },
                              ),


                            ],
                          ));
                    },
                  ),
                  SizedBox(height: 10,)
                ],
              ),
              SizedBox(
                height: 80,
              ),

              // Botão para salvar alterações
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        onTap: () {
                          _salvarAlteracoes();
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            "Salvar Alterações",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        onTap: () {
                          _showDeleteDialog(context);

                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            "Excluir Pedido",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        )),
                  ),
                ],
              )
            ],
          ),
        ));
  }

}
