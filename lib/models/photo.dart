class Photo {
  const Photo({this.ID, required this.path, required this.entryID});

  final int? ID;
  final String path;
  final int entryID;

  factory Photo.fromMap(Map data) => Photo(
    ID: data["ID"], 
    path: data["path"], 
    entryID: data["entryID"]
  );

  toMap() => {
    "ID": ID, 
    "path": path, 
    "entryID": entryID};
}