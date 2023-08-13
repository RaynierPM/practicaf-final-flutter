import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:practica_final_flutter/main.dart';
import 'package:practica_final_flutter/models/photo.dart';
import 'package:practica_final_flutter/models/place.dart';
import 'package:http/http.dart' as http;
import 'package:practica_final_flutter/db.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';


class PlaceView extends StatefulWidget {
  const PlaceView({super.key, required this.actualPlace, required this.deleter});

  final Place actualPlace;

  final void Function(int id) deleter;

  @override
  State<PlaceView> createState() => _PlaceViewState();
}

class _PlaceViewState extends State<PlaceView> {

  Map? weatherdata;
  Map? placeData;
  List<Photo> fotos = [];

  bool placeLoading = true;
  bool photosLoading = true;
  bool weatherLoading = true;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    hasSession(context)
      .then((value) async {
        if (value) {
            getWeatherData(widget.actualPlace.latitud, widget.actualPlace.longitud).then((value) {
              weatherdata = value;
              setState(() {weatherLoading = false;});
            })
            .catchError((error) {
              generateNotification(context, "No se puedo descargar la info del clima actual", Colors.red);
              weatherLoading = false;
            });

            getPlaceData(widget.actualPlace.latitud, widget.actualPlace.longitud).then((value)  {
              placeData = value;
              setState(() {placeLoading = false;});
            })
            .catchError((error) {
              generateNotification(context, "No se pudo descargar la info del lugar", Colors.red);
              setState(() => placeLoading = false);
            });
            
            AppDatabase().getAllPhotos(widget.actualPlace.ID!).then((value) {
              fotos = value;
              setState(() => photosLoading = false);
            })
            .catchError((error) => generateNotification(context, "Ha ocurrido un error inesperado", Colors.red));
            
          }
        setState(() {});
      });
  }


  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: AppBar(
        title: Text(widget.actualPlace.name),
        actions: [IconButton(onPressed: () {
          showConfirmModal(context, "¿Seguro que quiere eliminarlo?")
            .then((value) {
              if (value) {
                AppDatabase().deleteFavPlace(widget.actualPlace.ID!).then((value) {
                  if (value) {
                    generateNotification(context, "Eliminado correctamente", const Color(0xFF7EAA92));
                    widget.deleter(widget.actualPlace.ID!);
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  } else {
                    generateNotification(context, "Ha ocurrido un error", Colors.red);
                  }
                });
              }
            });
        }, icon: Icon(Icons.delete))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * .3,

            child: GoogleMap(
              scrollGesturesEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.actualPlace.latitud, widget.actualPlace.longitud),
                zoom: 15.3
              ),
              mapType: MapType.normal,
              markers: {
                Marker(
                  markerId: MarkerId(widget.actualPlace.ID.toString()),
                  position: LatLng(widget.actualPlace.latitud, widget.actualPlace.longitud),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                ),
              },
            ),
          ),
          

          Container(
            height: MediaQuery.of(context).size.height * .59,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 5.0),

            child: ListView(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: () async  {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.elliptical(10, 15))),
                          child: Container(
                            padding: const EdgeInsets.all(15.0),
                            width: MediaQuery.of(context).size.width * .5,
                            child: Wrap(
                              alignment: WrapAlignment.spaceAround,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("Origen: ", style: Theme.of(context).textTheme.titleMedium,),
                                IconButton(onPressed: () async {
                                  if (await Permission.camera.request().isGranted) {
                                    imagePicker(ImageSource.camera).then((path) {
                                      final foto = Photo(path: path, entryID: widget.actualPlace.ID!);
                                      AppDatabase().addPlacePhoto(foto).then((result) {
                                        if (result == null) {
                                          generateNotification(context, "No se pudo guardar la imagen", Colors.red);
                                        }else {
                                          generateNotification(context, "Imagen guardada existosamente", const Color(0xff617A55));
                                          setState(() => fotos.add(foto));
                                        } 
                                      });
                                    })
                                    .catchError((error) {
                                      generateNotification(context, "Ha ocurrido un error, trate mas tarde", Colors.red);
                                    });
                                  }
                                }, icon: const Icon(Icons.camera_alt)),
                                IconButton(onPressed: () async {
                                  if (await Permission.accessMediaLocation.request().isGranted) {
                                    imagePicker(ImageSource.gallery).then((path) {
                                      final foto = Photo(path: path, entryID: widget.actualPlace.ID!);
                                      AppDatabase().addPlacePhoto(foto).then((result) {
                                        if (result == null) {
                                          generateNotification(context, "No se pudo guardar la imagen", Colors.red);
                                        }else {
                                          generateNotification(context, "Imagen guardada existosamente", const Color(0xff617A55));
                                          setState(() => fotos.add(foto));
                                        } 
                                      });
                                    })
                                    .catchError((error) {
                                      generateNotification(context, "Ha ocurrido un error, trate mas tarde", Colors.red);
                                    });
                                  }
                                }, icon: const Icon(Icons.image)),
                              ],
                            ),
                          ),
                        )
                      );
                    },
                    child: Icon(Icons.camera_enhance),
                  ),
                ),
                const Divider(height: 10.0,),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0XFFFFF9f7),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: const [BoxShadow(
                        color: Color(0xFFDDDDDD),
                        blurRadius: 7.0,
                        offset: Offset(3, 3)
                      )
                    ]
                  ),
                  padding: const EdgeInsets.all(5.0),
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: fotos.isEmpty? 
                    Center(child:  Text(photosLoading? "Cargando..." :"No hay imagenes agregadas", style: Theme.of(context).textTheme.titleMedium,),)
                  :
                    ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          showDialog(context: context, builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: Image.file(File(fotos[index].path),
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                              fit: BoxFit.contain
                            ),
                          ));
                        },
                        child: Image.file(
                          File(fotos[index].path), 
                          height: 100, 
                          fit: BoxFit.cover,
                          
                        ),
                      ),
                      itemCount: fotos.length,
                      separatorBuilder: (context, index) => SizedBox(width: 5.0,),
                    )
                    // ListView(
                    //   scrollDirection: Axis.horizontal,
                    //   children: fotos.map((foto) => Image.file(File(foto.path), height: 100,) ).toList(),
                    // ),
                ),
                
                const Divider(height: 20.0,),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0XFFFFF9f7),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: const [BoxShadow(
                        color: Color(0xFFDDDDDD),
                        blurRadius: 7.0,
                        offset: Offset(3, 3)
                      )
                    ]
                  ),
                  padding: const EdgeInsets.all(15.0),

                  child: Wrap(
                    direction: Axis.horizontal,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,

                    children: [
                      Text("Descripción", 
                        style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center,
                      ),
                      Text(widget.actualPlace.descripcion !=  null? widget.actualPlace.descripcion! : 'Sin descripcion',
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  )

                ),

                const Divider(height: 20.0,),

                // Places's DATA

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0XFFFFF9f7),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: const [BoxShadow(
                        color: Color(0xFFDDDDDD),
                        blurRadius: 7.0,
                        offset: Offset(3, 3)
                      )
                    ]
                  ),

                  padding: const EdgeInsets.all(15.0),
                  child: 
                    placeLoading ? 
                      const Text("Cargando...",
                    textAlign: TextAlign.justify,)
                    :
                    placeData != null ?  
                    Wrap(
                        direction: Axis.horizontal,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text("Datos del lugar", 
                              style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.start,
                            ),
                          ),

                          const Divider(height: 10.0),

                          SizedBox(
                            width: MediaQuery.of(context).size.width * .4,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                newCell("País: ", placeData!["address"]["country"]),
                                
                              ],
                            ),
                          ),


                          SizedBox(
                            width: MediaQuery.of(context).size.width * .4,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                newCell("Ciudad: ", placeData!["address"]["state"]),
                              ],
                            ),
                          ),

                          const Divider(height: 15.0,),

                          newCell("Ubicacion total: ", placeData!["display_name"])

                        ],
                      )
                    :
                      const Text("No se puedieron cargar los datos",
                    textAlign: TextAlign.center)
                ),

                const Divider(height: 20.0,),

                // Weather's DATA

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0XFFFFF9f7),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: const [BoxShadow(
                        color: Color(0xFFDDDDDD),
                        blurRadius: 7.0,
                        offset: Offset(3, 3)
                      )
                    ]
                  ),

                  padding: const EdgeInsets.all(15.0),
                  child: 
                    weatherLoading ? 
                      const Text("Cargando...",
                    textAlign: TextAlign.justify,)
                    :
                    weatherdata != null ?  
                    Wrap(
                        direction: Axis.horizontal,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Text("Datos del clima", 
                              style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.start,
                            ),
                          ),

                          const Divider(height: 10.0),

                          SizedBox(
                            width: MediaQuery.of(context).size.width * .4,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                newCell("Humedad: ", '${weatherdata!["humidity"]}%'),
                                newCell("Precipitacion: ", '${weatherdata!["precipitationProbability"]}%'),
                                newCell("Intens. lluvia: ", '${weatherdata!["rainIntensity"]}mm/hr'),
                                
                              ],
                            ),
                          ),


                          SizedBox(
                            width: MediaQuery.of(context).size.width * .4,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                newCell("Temperatura: ", '${weatherdata!["temperature"]}°'),
                                newCell("Sensacion térmica: ", '${weatherdata!["temperatureApparent"]}°'),
                                newCell("Indice UV: ", uvToString(weatherdata!['uvIndex'])),
                              ],
                            ),
                          ),

                          const Divider(height: 15.0,),

                          newCell("Viento: ", '${weatherdata!["windSpeed"]}Mph')


                        ],
                      )
                    :
                      const Text("No se puedieron cargar los datos",
                    textAlign: TextAlign.center)
                ),
              ],
            ),
          ),
          
          

        ],
      )
  );



  Future<Map<String, dynamic>?> getWeatherData(double lat, double long) async {
    try {
      final response = await http.get(Uri.parse('https://api.tomorrow.io/v4/weather/realtime?location=$lat,$long&apikey=GB6jE6qMgfLeESMgCX66ULzn8rN7Ltik'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body)["data"]["values"];
        return Future.value(jsonData);
      }else {
        return Future.error("Ha ocurrido un error inesperado");
      }
    }catch(error) {
      return Future.error("No se pudieron cargar los datos");
    }
  }

  Future<Map<String, dynamic>?> getPlaceData(double lat, double long) async {
    try {
      final response = await http.get(Uri.parse('https://geocode.maps.co/reverse?lat=$lat&lon=$long'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Future.value(jsonData);
      }else {
        return Future.error("Ha ocurrido un error inesperado");
      }
    }catch(error) {
      return Future.error("No se pudieron cargar los datos");
    }
  }
}


Widget newCell(String title, String data) => RichText(
  text: TextSpan(
    text: title,
    style: const TextStyle(
      fontWeight: FontWeight.bold, 
      color: Colors.black
    ),
    children: [
      TextSpan(
        text: data,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.normal,
        )
      )
    ]
  )
  );

  String uvToString(int uvIndex) {
    String respuesta = "";

    uvIndex = uvIndex.abs();
    if (uvIndex >= 0 && uvIndex <= 2) {
      respuesta = "Bajo";
    }else if (uvIndex >=3 && uvIndex <= 5) {
      respuesta = "Moderado";

    }else if (uvIndex >=6 && uvIndex <= 7) {
      respuesta = "Alto";

    }else if (uvIndex >=8 && uvIndex <= 10) {
      respuesta = "Muy alto";

    }else {
      respuesta = "Extremadamente alta";
    }
    return respuesta;
  }

// ImagePicker
  Future<String> imagePicker(ImageSource source) async {

    try {
      final picker = ImagePicker();
      final image = await  picker.pickImage(source: source);
      if (image == null) return Future.error("No se genero la imagen");

      return image.path;
    }on PlatformException catch(e) {
      print("Error: $e"); 
      return Future.error("Ha ocurrido un error");
    }

  }