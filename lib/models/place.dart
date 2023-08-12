class Place {
  Place({this.ID, required this.name, this.descripcion, required this.longitud, required this.latitud, required this.userID});

  int? ID;
  final String name;
  final String? descripcion;
  final double longitud;
  final double latitud;
  final int userID;

  factory Place.fromMap(Map data) => Place(
    ID: data["ID"], 
    name: data["name"], 
    descripcion: data['descripcion'],
    longitud: data["longitud"], 
    latitud: data["latitud"],
    userID: data["userID"]
  );

  toMap() => {"ID": ID, "name": name,"descripcion":descripcion, "longitud": longitud, "latitud": latitud, "userID": userID};
}