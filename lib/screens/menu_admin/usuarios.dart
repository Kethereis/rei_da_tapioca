import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rei_da_tapioca/widget/input_text_widget.dart';

class UserScreenAdmin extends StatefulWidget {
  @override
  _UserScreenAdminState createState() => _UserScreenAdminState();
}

class _UserScreenAdminState extends State<UserScreenAdmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'Atendente';

  void _addUser() async {
    try {
      // Cria o usuário no Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Adiciona o usuário ao Firestore
      await _firestore.collection('usuarios').doc(userCredential.user?.uid).set({
        'nome': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'funcao': _selectedRole,
        'uid': userCredential.user?.uid
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário adicionado com sucesso!')),
      );

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _selectedRole = 'Atendente';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar usuário: $e')),
      );
    }
  }

  void _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({'funcao': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Função atualizada com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar função: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gerenciar Usuários')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulário para adicionar usuários
            InputTextWidget(controller: _nameController, item: 'Nome'),
            SizedBox(height: 10),
            InputTextWidget(controller: _emailController, item: 'E-mail'),
            SizedBox(height: 10),
            InputTextWidget(controller: _passwordController, item: 'Senha'),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text("Função:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),),

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
                    value: _selectedRole,
                    alignment:
                    AlignmentDirectional.center,
                    items:  ['Atendente', 'Admin']
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
                        _selectedRole = newValue!;
                      });
                    },
                  )),

            ],),

            ElevatedButton(
              onPressed: _addUser,
              child: Text('Adicionar Usuário'),
            ),

            SizedBox(height: 20),

            // Lista de usuários
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('usuarios').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Nenhum usuário encontrado.'));
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userId = user.id;
                      final nome = user['nome'];
                      final email = user['email'];
                      final funcao = user['funcao'];

                      return ListTile(
                        title: Text(nome),
                        subtitle: Text('E-mail: $email\nFunção: $funcao'),
                        trailing: DropdownButton<String>(
                          value: funcao,
                          onChanged: (value) {
                            if (value != null) {
                              _updateUserRole(userId, value);
                            }
                          },
                          items: ['Atendente', 'Admin']
                              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                              .toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
