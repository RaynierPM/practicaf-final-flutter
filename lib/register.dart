import 'dart:convert';

import 'package:crypt/crypt.dart';
import 'package:flutter/material.dart';
import 'package:practica_final_flutter/db.dart';
import 'package:practica_final_flutter/models/user.dart';
import 'package:practica_final_flutter/main.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("ExplorePix - Registro"),
      automaticallyImplyLeading: false,
    ),

    body: SizedBox(
      height: MediaQuery.of(context).size.height * .9,
      child: const FormRegister()
    )
  );

}


class FormRegister extends StatefulWidget {
  const FormRegister({super.key});

  @override
  State<FormRegister> createState() => _FormRegisterState();
}

class _FormRegisterState extends State<FormRegister> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final mainImage = "https://img.freepik.com/free-vector/concept-banner-turism-realistic-style-with-map-pointer-road-sign-suitcase-camera-vector-illustration_548887-208.jpg?size=626&ext=jpg&ga=GA1.2.1614540901.1691612919&semt=sph";


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
            decoration: InputDecoration(
              labelText: "Nombre de usuario",
              hintText: "Ej: Robert",
              labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0),
              hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0)
            ),
          ),

          TextFormField(
            style: const TextStyle(
              fontSize: 16.0
            ),
            controller: _passwordController,
            validator: validarPassword,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Contraseña",
              hintText: "Escribe tu contraseña",
              labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0),
              hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0)
            ),
          ),

          TextFormField(
            style: const TextStyle(
              fontSize: 16.0
            ),
            controller: _confirmPasswordController,
            validator: validarPassword,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "Confirmación de la contraseña",
              hintText: "Confirma tu contraseña",
              labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0),
              hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20.0)
            ),
          ),
          const SizedBox(height: 20.0),

          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final String username = _usernameController.text;
                  final String password = _passwordController.text;
                  

                  final hashedPassword = Crypt.sha256(password);
                  try {
                    int id = await AppDatabase().newUser(User(username: username.trim(), password: hashedPassword.toString()));
                    
                    

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bienvenido $username"), backgroundColor: Color(0xFF7EAA92),));
                    await session.set("user", jsonEncode({"ID": id, "username":username, "password":password}));
                    Navigator.pushReplacementNamed(context, '/');
                  
                  }on Exception {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El nombre de usuario ya existe"), backgroundColor: Colors.red,));
                  }catch(error) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ha ocurrido un error inesperado"), backgroundColor: Colors.red,));
                  }
                }
              }, 
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text("Registrarse"), 
                  Icon(Icons.save)
                  ],
                )
              )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const Text("¿Ya tienes una cuenta? "),
              TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text("Inicia sesión"))
            ],
          )
        ],
      )
    ),
  );


  String? validarCamposVacios(String? text) {
    if (text!.trim().isEmpty) {
        return "No deje campos vacios";
      }
      return null;
    }

  String? validarPassword(String? text) {
    if (text!.trim().isEmpty) {
      return "No deje campos vacios";
    }

    if (text.trim().length < 7) {
      return "Al menos 7 caracteres";
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      return "Las contraseñas deben ser iguales";
    }
    return null;
  }
}



