class Photo {
  const Photo({this.ID, required this.path, required this.placeID});

  final int? ID;
  final String path;
  final int placeID;

  factory Photo.fromMap(Map data) => Photo(
    ID: data["ID"], 
    path: data["path"], 
    placeID: data["entryID"]
  );

  toMap() => {
    "ID": ID, 
    "path": path, 
    "placeID": placeID};
}