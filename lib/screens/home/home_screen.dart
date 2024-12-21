import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rei_da_tapioca/screens/adicionar_pedido/novo_pedido_screen.dart';
import 'package:rei_da_tapioca/utils/constants.dart';
import 'package:rei_da_tapioca/widget/card_type_widget.dart';
import 'dart:html' as html;
import '../../service/getOrderData.dart';
import '../adicionar_pedido/categorias_screen.dart';
import '../detalhes_pedido/detalhes_pedidos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _pesquisaController = TextEditingController();
  TextEditingController _pesquisaMesaController = TextEditingController();

  late List<String> _atendentes = [];

  String? _selectedAtendente;
  String? _selectedStatus;
  DateTime? _dataInicial;
  DateTime? _dataFinal;

  List<QueryDocumentSnapshot> pedidosExibidos = [];

  Future<void> gerarExcel(List<QueryDocumentSnapshot> pedidos) async {
    // Crie um objeto Excel
    var excel = excel_lib.Excel.createExcel();

    // Adicione uma nova folha
    var sheet = excel['Sheet1'];

    // Crie o cabeçalho (colunas)
    sheet.appendRow(['ID', 'Data', 'Atendente', 'Status', 'Mesa', 'Valor', 'Forma de Pagamento']);

    // Adicione os dados
    for (var pedido in pedidos) {
      DateTime data = pedido['data'].toDate();

      sheet.appendRow([
      pedido['pedido'] ?? '',
        "${data.day}/${data.month}/${data.year}",
        pedido['atendente'] ?? '',
        pedido['status'] ?? '',
        pedido['mesa'] ?? '',
        pedido['valor'] ?? '',
        pedido['forma_pagamento'] ?? '',

      ]);
    }

    // Converte para bytes
    final bytes = excel.save(fileName: 'pedidos.xlsx');

    // Cria um blob com o conteúdo do arquivo Excel
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'pedidos.xlsx')
      ..click();

    // Libera o URL criado
    html.Url.revokeObjectUrl(url);
  }

  void atualizarResultados() async {
    List<QueryDocumentSnapshot> resultados = await buscarPedidos(
      dataInicial: _dataInicial,
      dataFinal: _dataFinal,
      funcionario: _selectedAtendente,
      status: _selectedStatus,
      palavraChave: _pesquisaController.text.trim(),
      pesquisaMesa: _pesquisaMesaController.text.trim()
    );
    setState(() {
      pedidosExibidos = resultados;
    });
  }

  Future<void> _selecionarDataInicial(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale('pt', 'BR'),
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataInicial) {
      setState(() {
        _dataInicial = picked;
      });
    }
  }

  Future<void> _selecionarDataFinal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale('pt', 'BR'),
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataFinal) {
      setState(() {
        _dataFinal = picked;
      });
    }
  }

  void limparFiltros() {
    setState(() {
      _dataInicial = null;
      _dataFinal = null;
      _selectedAtendente = null;
      _selectedStatus = null;
      _pesquisaController.clear();
      pedidosExibidos = [];
      _pesquisaMesaController.clear();
    });
    atualizarResultados();
  }

  Future<List<String>> buscarNomesUsuarios() async {
    List<String> nomes = [];

    try {
      // Obtem todos os documentos da coleção 'usuarios'
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('usuarios').get();

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
    setState(() async {
      _atendentes = await buscarNomesUsuarios();
    });
  }
  Future<void> loadData() async {
    final categoriesSnapshot =
    await FirebaseFirestore.instance.collection('categorias').get();


    // Limpar as listas antes de preencher com novos dados
    AppConstants.categoriasData.clear();

    // Adicionar somente os títulos à lista categoriasData
    AppConstants.categoriasData.addAll(
      categoriesSnapshot.docs.map((doc) => doc['titulo'].toString()).toList(),
    );

  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    atualizarResultados();
    carregarNomesUsuarios();
    loadData();
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

  Widget _layoutWeb() {
    double _width = MediaQuery
        .sizeOf(context)
        .width;

    return Scaffold(
      floatingActionButton: pedidosExibidos.isNotEmpty ? FloatingActionButton.extended(
        backgroundColor: AppConstants.appPrimaryColor,
        onPressed: (){
          gerarExcel(pedidosExibidos);
        },
        label: Row(children: [
          Icon(Icons.download, color: Colors.white, size: 35),
          SizedBox(width: 5),
          Text("Exportar Dados",
          style: TextStyle(
            color: Colors.white
          ),)
        ],),): null,
        body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    width: _width * 0.7,
                    decoration: BoxDecoration(
                        color: AppConstants.appPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    height: _width * 0.1,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                  width: _width * 0.7,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        color: Colors.white,
                                        width:
                                        MediaQuery
                                            .sizeOf(context)
                                            .width *
                                            0.183,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _selecionarDataInicial(context),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Data Inicial',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(0.0)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(0.0)),
                                                borderSide: BorderSide(
                                                    color: Colors.black12,
                                                    width: 1.0),
                                              ),
                                            ),
                                            child: Text(
                                              _dataInicial == null
                                                  ? 'Selecionar Data'
                                                  : '${_dataInicial!.day < 10
                                                  ? ("0${_dataInicial!.day}")
                                                  : _dataInicial!
                                                  .day}/${_dataInicial!.month <
                                                  10 ? ("0${_dataInicial!
                                                  .month}") : _dataInicial!
                                                  .month}/${_dataInicial!
                                                  .year}',
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        color: Colors.white,
                                        width:
                                        MediaQuery
                                            .sizeOf(context)
                                            .width *
                                            0.183,
                                        child: GestureDetector(
                                          onTap: () =>
                                              _selecionarDataFinal(context),
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Data Final',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(0.0)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(0.0)),
                                                borderSide: BorderSide(
                                                    color: Colors.black12,
                                                    width: 1.0),
                                              ),
                                            ),
                                            child: Text(
                                              _dataFinal == null
                                                  ? 'Selecionar Data'
                                                  : '${_dataFinal!.day < 10
                                                  ? ("0${_dataFinal!.day}")
                                                  : _dataFinal!
                                                  .day}/${_dataFinal!.month <
                                                  10 ? ("0${_dataFinal!
                                                  .month}") : _dataFinal!
                                                  .month}/${_dataFinal!
                                                  .year}',
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 0.2,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            hint: Text(
                                                "Selecione um Atendente"),
                                            underline: SizedBox.shrink(),
                                            value: _selectedAtendente,
                                            alignment:
                                            AlignmentDirectional.center,
                                            items: _atendentes
                                                .map((String item) {
                                              return DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(item),
                                                alignment:
                                                AlignmentDirectional.center,
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedAtendente = newValue;
                                              });
                                            },
                                          )),
                                      Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 0.2,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            hint: Text("Selecione um Status"),
                                            value: _selectedStatus,
                                            underline: SizedBox.shrink(),
                                            alignment:
                                            AlignmentDirectional.center,
                                            items: AppConstants.statusData.map((String item) {
                                              return DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(item),
                                                alignment:
                                                AlignmentDirectional.center,
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedStatus = newValue;
                                              });
                                            },
                                          )),
                                    ],
                                  )),
                              SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                  width: _width * 0.7,
                                  child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        SizedBox(
                                            width: _width * 0.5,
                                            child: TextField(
                                              controller: _pesquisaController,
                                              decoration: InputDecoration(
                                                hintText:
                                                'Pesquisar por número do pedido',
                                                // Texto exibido quando o campo está vazio
                                                hintStyle: TextStyle(
                                                    color: Colors.grey),
                                                // Cor do texto de dica
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: AppConstants
                                                      .appPrimaryColor,
                                                ),
                                                enabledBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      15.0),
                                                  borderSide: BorderSide(
                                                    color: Colors.white,
                                                  ), // Borda normal
                                                ),
                                                focusedBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      15.0),
                                                  borderSide: BorderSide(
                                                      color: Colors
                                                          .blue), // Borda ao focar
                                                ),
                                                fillColor: Colors.white,
                                                // Cor de fundo do campo
                                                filled: true,
                                              ),
                                            )),
                                        InkWell(
                                            onTap: atualizarResultados,
                                            child: Container(
                                              width: 130,
                                              height: 40,
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                  color: AppConstants
                                                      .appPrimaryColor,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      10)),
                                              child: Center(
                                                  child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                      children: [
                                                        Icon(
                                                          Icons.search,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          "Pesquisar",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 16),
                                                        )
                                                      ])),
                                            )),
                                        InkWell(
                                            onTap: limparFiltros,
                                            child: Container(
                                              width: 130,
                                              height: 40,
                                              padding: EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade400,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      10)),
                                              child: Center(
                                                  child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                      children: [
                                                        Icon(
                                                          Icons.close,
                                                          color: AppConstants
                                                              .appPrimaryColor,
                                                        ),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(
                                                          "Limpar",
                                                          style: TextStyle(
                                                              color: AppConstants
                                                                  .appPrimaryColor,
                                                              fontSize: 16),
                                                        )
                                                      ])),
                                            )),
                                      ])),
                            ],
                          ),
                        ])),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeader("Status"),
                _buildHeader("Pedido"),
                _buildHeader("Data"),
                _buildHeader("Valor"),
                _buildHeader("Atendente"),
                _buildHeader("Forma de Pagamento"),
                _buildHeader("Ações"),

              ],
            ),
            const SizedBox(height: 10),

              pedidosExibidos.isNotEmpty ?
             Expanded(
              child: ListView.builder(
                itemCount: pedidosExibidos.length,
                itemBuilder: (context, index) {
                  var pedido = pedidosExibidos[index];
                  DateTime data = pedido['data'].toDate();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContainerStatus(pedido['status']),
                      _buildRowItem("#${pedido['pedido']}"),
                      _buildRowItem("${data.day}/${data.month}/${data.year}"),
                      _buildRowItem(doubleToReal(pedido['valor'])),
                      _buildRowItem(pedido['atendente']?? 'Sistema') ,
                      _buildRowItem(pedido['forma_pagamento']),

                      Expanded(
                        child: IconButton(
                          icon: Icon(Icons.visibility_rounded),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalhesPedidoScreen(pedido: pedido.data() as Map<String, dynamic>, docId: pedido.id,),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ):
            Expanded(
              child: Column(children: [
                LinearProgressIndicator(color: AppConstants.appPrimaryColor,)]))
          ],
        )));
  }



  Widget _buildHeader(String title) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String doubleToReal(double value) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return formatter.format(value);
  }

  Widget _buildContainerStatus(String title) {
    Color color = Color(0xffe2e2e2);
    if (title == 'Em Andamento') {
      color = Color(0xffFCD12A);
    } else if (title == 'Concluído') {
      color = Color(0xff008000);
    }else if(title == 'Cancelado'){
      color = Color(0xffc30010);
    }

    return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
          width: 150,
      height: 35,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
    child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.white),
      )),
    )]));
  }

// Função para construir os itens da lista
  Widget _buildRowItem(String content) {
    return Expanded(
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _layoutMobile() {
    double _width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NovoPedidoScreen(
                ),
              ),
            );


          },
          backgroundColor: AppConstants.appPrimaryColor,
          label: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.white,),
              SizedBox(width: 5,),
              Text("Novo Pedido",
              style: TextStyle(
                color: Colors.white
              ),)

          ],)),
        body: Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                TextField(
                  controller: _pesquisaMesaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por número da mesa',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                SizedBox(height: 8,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: atualizarResultados,
                      icon: Icon(Icons.search),
                      label: Text("Pesquisar"),
                    ),
                    ElevatedButton.icon(
                      onPressed: limparFiltros,
                      icon: Icon(Icons.close),
                      label: Text("Limpar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: pedidosExibidos.length,
              itemBuilder: (context, index) {
                var pedido = pedidosExibidos[index];
                DateTime data = pedido['data'].toDate();
                Color color = Color(0xffe2e2e2);
                if (pedido['status'] == 'Em Andamento') {
                  color = Color(0xffFCD12A);
                } else if (pedido['status'] == 'Concluído') {
                  color = Color(0xff008000);
                }else if(pedido['status'] == 'Cancelado'){
                  color = Color(0xffc30010);
                }
                return InkWell(
                  onTap: (){
                    Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalhesPedidoScreen(
                                    pedido: pedido.data() as Map<String, dynamic>,
                                    docId: pedido.id,
                                  ),
                                ),
                              );
                  },
                    child: Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                  Text("#${pedido['pedido']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),),
                        Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: Text(pedido['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white
                          ),),
                        )

                    ],),
                    SizedBox(height: 15,),
                    Row(children: [
                  Row(children: [
                    Icon(Icons.table_bar_outlined, color: AppConstants.appPrimaryColor,),
                    SizedBox(width: 5,),
                    Text("Mesa:", style: TextStyle(fontWeight: FontWeight.bold),)
                  ],),
                      SizedBox(width: 5,),
                      Text("${pedido['mesa']}")
                      ]),

                  SizedBox(height: 15,),


                  Row(children: [
                    Row(children: [
                      Icon(Icons.receipt_long_outlined, color: AppConstants.appPrimaryColor,),
                      SizedBox(width: 5,),
                      Text("Pagamento:", style: TextStyle(fontWeight: FontWeight.bold),)
                    ],),
                    SizedBox(width: 5,),
                    Text("${pedido['forma_pagamento']}")
                  ]),

                  SizedBox(height: 15,),


                  Row(children: [
                    Row(children: [
                      Icon(Icons.attach_money_outlined, color: AppConstants.appPrimaryColor,),
                      SizedBox(width: 5,),
                      Text("Valor:", style: TextStyle(fontWeight: FontWeight.bold),)
                    ],),
                    SizedBox(width: 5,),
                    Text(doubleToReal(pedido['valor']))
                  ]),

                  SizedBox(height: 30,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    InkWell(
                        onTap: atualizarResultados,
                        child: Container(
                          width: 120,
                          height: 35,
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius:
                              BorderRadius.circular(
                                  10)),
                          child: Center(
                              child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      "Concluir",
                                      style: TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize: 14),
                                    )
                                  ])),
                        )),
                    InkWell(
                        onTap: atualizarResultados,
                        child: Container(
                          width: 120,
                          height: 35,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                              BorderRadius.circular(
                                  10)),
                          child: Center(
                              child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  children: [
                                    Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      "Cancelar",
                                      style: TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize: 14),
                                    )
                                  ])),
                        )),

                  ],)



                  ],),

                  // child: ListTile(
                  //   title: Text("#${pedido['pedido']} - ${pedido['status']}"),
                  //   subtitle: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text("Data: ${data.day}/${data.month}/${data.year}"),
                  //       Text("Valor: ${doubleToReal(pedido['valor'])}"),
                  //       Text("Atendente: ${pedido['atendente']}"),
                  //     ],
                  //   ),
                  //   trailing: IconButton(
                  //     icon: Icon(Icons.visibility_rounded),
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => DetalhesPedidoScreen(
                  //             pedido: pedido.data() as Map<String, dynamic>,
                  //             docId: pedido.id,
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                )));
              },
            )
          ),
        ],
      ),
    ));
  }

}
