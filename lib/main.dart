import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:practica_final_flutter/db.dart';
import 'package:practica_final_flutter/login.dart';
import 'package:practica_final_flutter/models/place.dart';
import 'package:practica_final_flutter/place_view.dart';
import 'package:practica_final_flutter/register.dart';
import 'package:practica_final_flutter/style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';

final session = SessionManager();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) => MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const Inicio(),
      '/login' : (context) => const Login(),
      '/register' : (context) =>  const Register()
    },
    color: const Color(0xff617A55),
    title: "ExplorePix",
    theme: style,
    debugShowCheckedModeBanner: false,
  );
}



class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {

  Set<Marker> marcadores = {};

  int counter = 0;

  CameraPosition initialCamPos = const CameraPosition(
    target: LatLng(18.481546, -69.882592),  
  );

  GoogleMapController? _controllerMap;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initMainView();


  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text("ExplorePix"),
      actions: [IconButton(onPressed: () {
        session.destroy();
        Navigator.pushReplacementNamed(context, '/login');
      }, icon: const Icon(Icons.exit_to_app, color: Colors.white,))],
    ),

    body: GoogleMap(
      onTap: (posicion) {
        
        confirmModal(context).then((value) {
          if (value) {
            modalAddingFav(posicion, context, getNewMarker);
          }
        });
      },
      onMapCreated: (controller) => _controllerMap = controller,
      initialCameraPosition: initialCamPos,
      mapType: MapType.normal,
      markers: marcadores,
      padding: const EdgeInsets.all(5.0),
    ),
    
    bottomNavigationBar:ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(150.0, 50.0)
      ),
      onPressed: () {
        mostrarFavoritos(context, deleteMarker);
      }, 
      child: const Icon(Icons.list))
  );

  Future<void> requestAllPermissions() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        generateNotification(context, "Active el permiso para continuar", Color(0xAAFF0000));
        return Future.error('Location permissions are denied');
      }
    }
 
    Position posicion = await Geolocator.getCurrentPosition(); 

    setState(() {
      _controllerMap!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(posicion.latitude, posicion.longitude),
            zoom: 15.0,
          )
        )
      );
      
      marcadores.add(
        Marker(
          markerId: const MarkerId('Posicion actual'), 
          position: LatLng(posicion.latitude, posicion.longitude),
          infoWindow: const InfoWindow(title: "Posicion actual!"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta)
        )
      );
    }); 
  }

  Future<void> initMainView() async  {
  
    // Verify if exists a session
    // request all permisions (Location) 
    if (await hasSession(context)) {
      requestAllPermissions();
      getAllMarkers();
    }
  }

  Future<void> getAllMarkers() async {
    final actualUser = await session.get("user");
    if (actualUser != null) {
      final result = await AppDatabase().getFavPlaces(actualUser["ID"]);
      result.forEach((place) => marcadores.add(Marker(
        markerId: MarkerId(place.ID.toString()),
        position: LatLng(place.latitud, place.longitud),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.descripcion,
          onTap: () => showDialog(context: context, builder: (context) => PlaceView(actualPlace: place, deleter: deleteMarker,)),
        )
      )
    ));
    }
  }

  Future<void> getNewMarker(Place nuevoLugar) async {
    marcadores.add(Marker(
        markerId: MarkerId(nuevoLugar.ID.toString()),
        position: LatLng(nuevoLugar.latitud, nuevoLugar.longitud),
        infoWindow: InfoWindow(
          title: nuevoLugar.name,
          snippet: nuevoLugar.descripcion,
          onTap: () =>
            showDialog(context: context, builder: (context) => PlaceView(actualPlace: nuevoLugar, deleter: deleteMarker,)),
        )
      )
    );

    setState(() {});
  }

  
  void deleteMarker(int id) {
    marcadores.removeWhere((marker) => marker.markerId.value == id.toString());
    setState(() {});
  }
}

Future<bool> hasSession(BuildContext context) async {
  dynamic user = await session.get("user");

  if (user == null) {
    Navigator.pushReplacementNamed(context, '/login');
    return false;
  }else {
    return true;
  }
}


// Confirm modal - Create new point


Future<bool> confirmModal(BuildContext context) async {
  bool modalResponse = false;


  await showDialog(
    context: context, 
    builder:(context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0)
      ),
      child: Container(
          height: 150,
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Text("¿Quieres agregar un nuevo lugar a favoritas?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 15.0,),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(onPressed: () {
                    modalResponse = true;
                    Navigator.pop(context);
                  }, child: const Text("Si, acepto")),
                  ElevatedButton(onPressed: () {
                    Navigator.pop(context);
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("No, cancelar"))
    
                ],
              ),
            ],
          ),
      ),
    )
  );

  return Future.value(modalResponse);

}


void modalAddingFav(LatLng posicion, BuildContext context, void Function(Place) cargarMarcadores) {
  showDialog(context: context, builder: (context) => FormAddingFav(posicion: posicion, cargarMarcadores: cargarMarcadores));
}

class FormAddingFav extends StatefulWidget {
  const FormAddingFav({super.key, required this.posicion, required this.cargarMarcadores});

  final LatLng posicion;
  final void Function(Place) cargarMarcadores;

  @override
  State<FormAddingFav> createState() => _FormAddingFavState();
}

class _FormAddingFavState extends State<FormAddingFav> {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      
      child: Container(
        constraints: 
        const BoxConstraints(maxHeight: 300),
        child: Form(
          
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: [
                Text("Informacion del lugar", 
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(color: const Color(0xFF617A55))
                ),
                TextFormField(
                  style: const TextStyle(
                    fontSize: 16.0
                  ),
                  controller: _nameController,
                  validator: (text) {
                    if (text!.trim().isEmpty) {
                      return "No dejes el campo vacio";
                    }else if (text.trim().length > 30) {
                      return "Menos de 30 caracteres";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Nombre del lugar",
                    hintText: "Ej: Parque de la esquina",
                    labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14.0),
                    hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14.0)
                  ),
                ),
          
                TextFormField(
                  style: const TextStyle(
                    fontSize: 16.0
                  ),
                  controller: _descriptionController,
                  validator: validarCamposVacios,
                  decoration: InputDecoration(
                    labelText: "Descripcion del lugar",
                    hintText: "Ej: Gran lugar lleno de arboles y naturaleza",
                    labelStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14.0),
                    hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 14.0),
                  ),
                  maxLines: 4,
                ),

                ElevatedButton(onPressed: () async {
                  final actualUser = await session.get("user");
                  if (_formKey.currentState!.validate() && actualUser != null) {
                    final nuevoLugar = Place(
                      name: _nameController.text,
                      descripcion: _descriptionController.text,
                      latitud: widget.posicion.latitude,
                      longitud: widget.posicion.longitude,
                      userID: actualUser["ID"]
                    );
                    
                    AppDatabase().addFavPLace(nuevoLugar).then((value) {
                      if (value != null) {
                        generateNotification(context, "Nuevo lugar favorito :3", Color(0xFF7EAA92));
                        nuevoLugar.ID = value;
                        widget.cargarMarcadores(nuevoLugar);
                      }else {
                        generateNotification(context, "Ha ocurrido algo inesperado, trate mas tarde", Colors.red);
                      }
                      Navigator.pop(context);
                    });

                  }
                }, child: const Text("Guardar"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// fullScreen modal - View All FavPlaces
void mostrarFavoritos(BuildContext context, Function(int) deleteMarker) {
  showDialog(
    context: context, 
    builder: (context) => Scaffold(
      appBar: AppBar(
          title: const Text("Lista de favoritos"),
      ),

      body: ListaFavoritos(deleter: deleteMarker)
    )
  );
}

class ListaFavoritos extends StatefulWidget {
  const ListaFavoritos({super.key, required this.deleter});

  final void Function(int) deleter; 

  @override
  State<ListaFavoritos> createState() => _ListaFavoritosState();
}

class _ListaFavoritosState extends State<ListaFavoritos> {

  int? id;

  List<Place> favPlaces = <Place>[];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getPlacesData();
    

  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10.0),
    child: SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: favPlaces.isEmpty?
        Center(
          child: Text("No tienes lugares favoritos",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        )
      :
        ListView.separated(
          itemBuilder: ((context, index) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => showDialog(context: context, builder: (context) => PlaceView(actualPlace: favPlaces[index], deleter: widget.deleter)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(favPlaces[index].name, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: const Color(0xFF7EAA92)),),
                  IconButton(onPressed: () {
                      showConfirmModal(context, "¿Seguro que quiere eliminarlo?")
                        .then((value) {
                          if (value) {
                            AppDatabase().deleteFavPlace(favPlaces[index].ID!).then((value) => {
                              if (value) {
                                generateNotification(context, "Eliminado correctamente", const Color(0xFF7EAA92)),
                                widget.deleter(favPlaces[index].ID!),
                                favPlaces.removeWhere((place) => place.ID == favPlaces[index].ID),
                                setState(() {})
                              }else {
                                generateNotification(context, "Ha ocurrido un error", Colors.red)
                              }
                            });
                          }
                        });
                    }, 
                    icon: const Icon(Icons.delete, color: Color(0xFF617A55),)
                  )
                ],
              ),
            ),
          )), 
          separatorBuilder: (context, index) => const Divider(height: 10.0), 
          itemCount: favPlaces.length),
      ),
  
  );

  Future<void> getPlacesData() async {
    id = await session.get("user").then((value) => value["ID"]);
    
    final places = await AppDatabase().getFavPlaces(id!);
    
    setState(() => favPlaces = places);
    
  }
  
}

generateNotification(BuildContext context, String message, Color color) => 
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
    )
);

Future<bool> showConfirmModal(BuildContext context, String title) async {
  bool response = false;

  await showDialog(context: context, builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0)
    ),
    child: Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.spaceAround,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox( 
              width: MediaQuery.of(context).size.width,
              child: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,)
            ),
            ElevatedButton(onPressed: () {
              response = true;
              Navigator.pop(context);
            }, child: const Text("Sí, estoy seguro")),
      
            ElevatedButton(onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("No, cancelar"),
            )
          ],
        ),
      ),
    ),
  ));

  return Future.value(response);
}
