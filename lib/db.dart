import 'package:practica_final_flutter/models/photo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:practica_final_flutter/models/user.dart';
import 'package:practica_final_flutter/models/place.dart';

final Exception error = Exception("Ha ocurrido un error inesperado");

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  // ignore: non_constant_identifier_names
  final String DB_NAME = "ExplorePix.db";
  final String tableName = "users";
  final String username = "username";
  final String userPassword = "password";

  // Tabla registros
  final String placesTable = "places";

  final placeName = "name";
  final placeDesc = "descripcion";
  final placeLong = "longitud";
  final placeLat = "latitud";
  final placeUserID = "userID";

  // tabla de imagenes
  final photosTable = "images";

  final photoPath = "path";
  final photoEntryID = "entryID";




  static Database? _db;

  AppDatabase._internal();

  factory AppDatabase() {
    return _instance;
  } 

  Future<Database?> get db async {
    if (_db != null) return _db!;

    _db = await getDb(DB_NAME);
    return _db;
  }

  Future<Database> getDb(String fileName) async {
    String dbPath = await getDatabasesPath();
    String finalPath = p.join(dbPath, fileName);

    return await openDatabase(finalPath, version: 2, onCreate: initDb);
  }

  Future<void> initDb(Database db, int? version) async {
    await db.execute(
    '''
      CREATE TABLE $tableName (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $username TEXT UNIQUE not null, 
        $userPassword TEXT not null
      )
    '''
    );

    await db.execute('''
      CREATE TABLE $placesTable (
        ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $placeName TEXT not null, 
        $placeDesc TEXT not null,
        $placeLong DECIMAL(10,5) not null,
        $placeLat DECIMAL(10,5) not null,
        $placeUserID INTEGER not null,
        FOREIGN KEY ($placeUserID) references $tableName(ID)
      )
    ''');

      await db.execute('''
        CREATE TABLE $photosTable (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          $photoPath TEXT not null, 
          $photoEntryID INTEGER not null,
          FOREIGN KEY ($photoEntryID) references $placesTable(ID)
        )
      ''');
  }

  Future<int> newUser(User usuario) async {
    Database? db = await _instance.db;
    if (db!.isOpen) {
      try {
        return await db.insert(tableName, usuario.toMap());
      }catch(e) {
        print(e);
        return Future.error(Exception("Nombre de usuario ya existe"));
      }
    }else {
      return Future.error(Exception("Conexion no abierta"));
    }
  }

  Future<User?> getUser(String username) async {
    try { 
      final db = await _instance.db;

      List<Map> usuario = await db!.query(tableName, where: "${this.username} = '$username'");

      if (usuario.isNotEmpty) {
        return User.fromMap(usuario[0]);
      }else {
        return null;
      }
    }catch(e) {
      throw error;
    }
  }

  Future<List<Place>> getFavPlaces(int id) async {
    List<Place> places = [];
    final db = await _instance.db;

    final result = await db!.query(placesTable, where: '$placeUserID = ?', whereArgs: [id]);

    result.forEach((place) => places.add(Place.fromMap(place)));

    print("Prueba");
    print(places);

      

    return places;
  }

  Future<int?> addFavPLace(Place place) async {
    final db = await _instance.db;
    try {
      return await db!.insert(placesTable, place.toMap());
      
    }catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> deleteFavPlace(int id) async {
    final db = await _instance.db;
    try {
      final response = await db!.delete(placesTable, where: 'ID = ?', whereArgs: [id]);
      await db.delete(photosTable, where: '$photoEntryID = ?', whereArgs: [id]);
      return response == 1;
    }catch (e) {
      return false;
    } 
  }
  
  Future<int?> addPlacePhoto(Photo foto) async {
    try {
      final db = await _instance.db;
      
      final response = await db!.insert(photosTable, foto.toMap());

      return response == 0? null: response;
    }catch (error) {
      print(error);
      return null;
    }
  }

  Future<List<Photo>> getAllPhotos(int placeID) async {
    final List<Photo> fotos = [];
    try {
      final db = await _instance.db;
      if (db!.isOpen) {
        final result = await db.query(photosTable, where: "$photoEntryID = ?", whereArgs: [placeID]);

        result.forEach((foto) {
          fotos.add(Photo.fromMap(foto));
        });

        return fotos;
      }else {
        return Future.error("Error inesperado");
      }
    }catch (e) {
      print(e);
      return Future.error("Error inesperado");
    }
  }

}