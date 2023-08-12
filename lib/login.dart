import 'dart:convert';
import 'package:crypt/crypt.dart';
import 'package:flutter/material.dart';
import 'package:practica_final_flutter/db.dart';
import 'package:practica_final_flutter/main.dart';
import 'package:practica_final_flutter/models/user.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("ExplorePix - Inicio de sesión"),
      automaticallyImplyLeading: false,
    ),

    body: SizedBox(
      height: MediaQuery.of(context).size.height * .9,
      child: const FormLogin()
    )
  );

}


class FormLogin extends StatefulWidget {
  const FormLogin({super.key});

  @override
  State<FormLogin> createState() => _FormLoginState();
}

class _FormLoginState extends State<FormLogin> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final mainImage = "https://img.freepik.com/free-vector/hand-drawn-colorful-travel-background_23-2149033528.jpg?size=626&ext=jpg&ga=GA1.2.1614540901.1691612919&semt=sph";


  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10.0),

    child: Form(
      key: formKey,
      
      child: ListView(

        children: [
          
          Image.network(mainImage),
          const SizedBox(height: 20.0),
          TextFormField(
            style: const TextStyle(
              fontSize: 16.0
            ),
            controller: _usernameController,
            validator: validarCamposVacios,
            decoration: const InputDecoration(
              labelText: "Nombre de usuario",
              hintText: "Ej: Robert",
            ),
            
          ),

          TextFormField(
            style: const TextStyle(
              fontSize: 16.0
            ),
            controller: _passwordController,
            validator: validarCamposVacios,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Contraseña",
              hintText: "Escribe tu contraseña",
            ),
          ),

          const SizedBox(height: 20.0),

          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  User? usuario = await AppDatabase().getUser(_usernameController.text);
                  
                  if (usuario != null) {
                    Crypt hashedPassword = Crypt(usuario.password);
                    if (hashedPassword.match(_passwordController.text)) {
                      await session.set("user", jsonEncode(usuario.toMap()));

                      // ignore: use_build_context_synchronously
                      generateNotification(context, "Bienvenido, ${_usernameController.text}", Color(0xFF7EAA92));
                      Navigator.pushReplacementNamed(context, '/');
                    }else {
                      generateNotification(context, "Usuario y/o contraseña incorrecto!", Colors.red);
                    }
                  }else {
                    generateNotification(context, "Este usuario no existe", Colors.red);
                  }
                }
              }, 
              child: const 
              Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text("Iniciar sesión"), 
                  Icon(Icons.save)],
              )
            )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Text("¿No tienes una cuenta? "),
              TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/register'), child: const Text("Registrate gratis"))
            ],
          )
        ],
      )
    ),
  );
}

String? validarCamposVacios(String? text) {
  if (text!.trim().isEmpty) {
      return "No deje campos vacios";
    }
    return null;
}