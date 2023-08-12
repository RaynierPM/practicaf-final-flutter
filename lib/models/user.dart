class User {
  User({this.ID, required this.username, required this.password});

  int? ID;
  final String username;
  final String password;

  factory User.fromMap(Map data) => User(ID: data["ID"], username: data["username"], password: data["password"]);

  toMap() => {"ID": ID, "username": username, "password": password};
}