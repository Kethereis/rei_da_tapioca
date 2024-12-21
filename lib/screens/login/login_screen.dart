
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rei_da_tapioca/screens/home/home_screen.dart';

import '../../controllers/navigation/navigation_controller.dart';
import '../../service/getFirebaseData.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key,});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _viewPass = true;
  bool _loading = false;

  void showToastMessageError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // Duração: SHORT ou LONG
      gravity: ToastGravity.TOP_LEFT, // Posição: TOP, CENTER ou BOTTOM
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
  void showToastMessageSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT, // Duração: SHORT ou LONG
      gravity: ToastGravity.TOP_LEFT, // Posição: TOP, CENTER ou BOTTOM
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> fetchDataUser(String documento) async {
    FirebaseService firebaseService = FirebaseService();

    // Busca os dados do Firestore
    Map<String, dynamic>? documentData = await firebaseService.getDocumentData("usuarios", documento);

    if (documentData != null) {

      AppConstants.idUsuario = documento;
      AppConstants.nomeUsuario = documentData['nome'];
      AppConstants.emailUsuario = documentData['email'];
      AppConstants.funcaoUsuario = documentData['funcao'];


      print('Dados do documento: $documentData');
    } else {
      print('Nenhum dado encontrado ou erro na busca.');
    }
  }

  Future<void> _resetPassword() async {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Esqueci minha senha'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Digite seu e-mail'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Fechar o diálogo
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _auth.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                  );
                  Navigator.pop(context); // Fechar o diálogo
                  showToastMessageSuccess("Redefinição enviada para o email ${emailController.text}");

                } catch (e) {
                  Navigator.pop(context); // Fechar o diálogo

                }
              },
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print("Login bem-sucedido!");
      await fetchDataUser(_auth.currentUser!.uid);

      if(AppConstants.funcaoUsuario == 'Admin' && MediaQuery.sizeOf(context).width > 1200) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NavigationController(initialIndex: 0)),
        );
      }else{
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen()),
        );
      }
      setState(() {
        _loading = false;
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
      });

      // Tratamento de erros específicos
      if (e.code == 'user-not-found') {
        showToastMessageError("E-mail não encontrado. Verifique o e-mail digitado.");
      } else if (e.code == 'wrong-password') {
        showToastMessageError("Senha incorreta. Tente novamente.");
      } else if (e.code == 'invalid-email') {
        showToastMessageError("Formato de e-mail inválido.");
      } else {
        // Erro desconhecido
        showToastMessageError("Por favor, verifique suas credenciais");
        setState(() {
          _loading = false;
        });

      }
    } catch (e) {
      setState(() {
        _loading = false;
      });

      // Erro geral
      showToastMessageError("Ocorreu um erro. Tente novamente mais tarde.");
    }
  }

  bool isMobile() {
    if (kIsWeb) return false; // A web não é considerada "mobile".
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool isDesktop() {
    if (kIsWeb) return true; // A web pode ser tratada como desktop.
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: SafeArea(
        child: _width < 1200 ? _layoutMobile(): _layoutWeb(),
    )
    );
  }

  Widget _layoutWeb(){
    double _width = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: _width * 0.5,
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/imagem_login.jpg"), fit: BoxFit.fill),
          ),
        ),
        SizedBox(
            width: _width * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                    width: _width * 0.3,
                    child: Row(children: [
                      const Text(
                        'Bem-Vindo',
                        style: TextStyle(
                            fontSize: 26
                        ),
                      ),
                    ],)
                ),

                SizedBox(height: 15,),
                SizedBox(
                    width: _width * 0.3,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email', // Texto exibido quando o campo está vazio
                        hintStyle: TextStyle(color: Colors.grey), // Cor do texto de dica
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.grey.shade300), // Borda normal
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.blue), // Borda ao focar
                        ),
                        fillColor: Colors.grey.shade100, // Cor de fundo do campo
                        filled: true,
                      ),
                    )
                ),
                SizedBox(height: 15,),
                SizedBox(
                    width: _width * 0.3,
                    child: TextField(
                      obscureText: _viewPass,
                      controller: _passwordController,
                      decoration: InputDecoration(
                          hintText: 'Senha', // Texto exibido quando o campo está vazio
                          hintStyle: TextStyle(color: Colors.grey), // Cor do texto de dica
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.grey.shade300), // Borda normal
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.blue), // Borda ao focar
                          ),
                          fillColor: Colors.grey.shade100, // Cor de fundo do campo
                          filled: true,
                          suffixIcon: IconButton(
                              onPressed: (){
                                setState(() {
                                  if(_viewPass){
                                    _viewPass = false;
                                  }else{
                                    _viewPass = true;
                                  }
                                });

                              },
                              icon: Icon(_viewPass ? Icons.visibility_off: Icons.visibility))
                      ),
                    )
                ),
                SizedBox(
                    width: _width * 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                            onTap:_resetPassword,
                            child: Text("Esqueci minha senha",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12
                              ),)),
                      ],)),
                SizedBox(height: 30,),
                SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.3,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                            onTap: (){
                              setState(() {
                                _loading = true;
                              });
                              _login();
                            },
                            child: Container(
                              width: 150,
                              height: 45,
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                  child: _loading ? LinearProgressIndicator(color: Colors.white,):Text("Acessar",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16
                                    ),)),
                            )),
                      ],)),


              ],)),
      ],
    );
  }
  Widget _layoutMobile(){
    double _width = MediaQuery.sizeOf(context).width;
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: _width * 0.25,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: AssetImage("assets/imagem_login.jpg"))
                  ),
                ),
                SizedBox(height: 20,),
                SizedBox(
                    width: _width * 0.6,
                    child: Row(children: [
                      const Text(
                        'Bem-Vindo',
                        style: TextStyle(
                            fontSize: 24
                        ),
                      ),
                    ],)
                ),

                SizedBox(height: 15,),
                SizedBox(
                    width: _width * 0.6,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email', // Texto exibido quando o campo está vazio
                        hintStyle: TextStyle(color: Colors.grey), // Cor do texto de dica
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.grey.shade300), // Borda normal
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color: Colors.blue), // Borda ao focar
                        ),
                        fillColor: Colors.grey.shade100, // Cor de fundo do campo
                        filled: true,
                      ),
                    )
                ),
                SizedBox(height: 15,),
                SizedBox(
                    width: _width * 0.6,
                    child: TextField(
                      obscureText: _viewPass,
                      controller: _passwordController,
                      decoration: InputDecoration(
                          hintText: 'Senha', // Texto exibido quando o campo está vazio
                          hintStyle: TextStyle(color: Colors.grey), // Cor do texto de dica
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.grey.shade300), // Borda normal
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Colors.blue), // Borda ao focar
                          ),
                          fillColor: Colors.grey.shade100, // Cor de fundo do campo
                          filled: true,
                          suffixIcon: IconButton(
                              onPressed: (){
                                setState(() {
                                  if(_viewPass){
                                    _viewPass = false;
                                  }else{
                                    _viewPass = true;
                                  }
                                });

                              },
                              icon: Icon(_viewPass ? Icons.visibility_off: Icons.visibility))
                      ),
                    )
                ),
                SizedBox(
                    width: _width * 0.6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                            onTap:_resetPassword,
                            child: Text("Esqueci minha senha",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12
                              ),)),
                      ],)),
                SizedBox(height: 30,),
                SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.6,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                            onTap: (){
                              setState(() {
                                _loading = true;
                              });
                              _login();
                            },
                            child: Container(
                              width: 150,
                              height: 35,
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Center(
                                  child: _loading ? LinearProgressIndicator(color: Colors.white,):Text("Acessar",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16
                                    ),)),
                            )),
                      ],)),


              ],
    )]);
  }
}