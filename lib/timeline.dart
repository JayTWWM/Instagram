import 'dart:io';
import 'dart:math';
import 'package:Flippo/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Flippo/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MyTimeLinePage extends StatefulWidget {
  @override
  _MyTimeLinePageState createState() => _MyTimeLinePageState();
}

class _MyTimeLinePageState extends State<MyTimeLinePage> {
  @override
  void initState() {
    super.initState();
    storageReference = FirebaseStorage().ref();
    getCurrentUser().then((results) {
      _db
          .collection("Users")
          .document(currentUser.email)
          .get()
          .then((DocumentSnapshot ds) {
        username = ds.data["username"];
        count = ds.data["count"];
      }).whenComplete(() {
        currentSize = 0;
        getPostList().then((results) {
          querySnapshot = results;
          for (DocumentSnapshot i in querySnapshot.documents) {
            docList.add(i.documentID);
            uploaderList.add(i.data["uploader"]);
            urlList.add(i.data["uploadUrl"]);
            captionList.add(i.data["caption"]);
            List<dynamic> likers = i.data["likedBy"];
            likeCount.add(likers.length);
            likeList.add(likers.contains(username));
            flareList.add(FlareControls());
            currentSize++;
            if (currentSize == 10) {
              break;
            }
          }
          setState(() {});
        });
      });
    });
  }

  getCurrentUser() async {
    currentUser = await _auth.currentUser();
  }

  FirebaseUser currentUser;
  FirebaseAuth _auth = FirebaseAuth.instance;
  int currentSize;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  QuerySnapshot querySnapshot;
  String caption;
  Firestore _db = Firestore.instance;
  StorageReference storageReference;
  String username;
  int count;
  File _image;
  final picker = ImagePicker();
  String uploadUrl;
  List<FlareControls> flareList = [];
  List<String> uploaderList = [];
  List<int> likeCount = [];
  List<String> docList = [];
  List<String> urlList = [];
  List<String> captionList = [];
  List<bool> likeList = [];
  DateTime lastRender;

  void _onRefresh() async {
    docList = [];
    uploaderList = [];
    urlList = [];
    captionList = [];
    likeList = [];
    likeCount = [];
    flareList = [];
    currentSize = 0;
    getPostList().then((results) {
      querySnapshot = results;
      for (DocumentSnapshot i in querySnapshot.documents) {
        docList.add(i.documentID);
        uploaderList.add(i.data["uploader"]);
        urlList.add(i.data["uploadUrl"]);
        captionList.add(i.data["caption"]);
        List<dynamic> likers = i.data["likedBy"];
        likeCount.add(likers.length);
        likeList.add(likers.contains(username));
        flareList.add(FlareControls());
        currentSize++;
        if (currentSize == 10) {
          break;
        }
      }
      setState(() {});
      _refreshController.refreshCompleted();
    });
  }

  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    int lastSize = currentSize;
    try {
      if (querySnapshot.documents[lastSize] != null) {
        for (int i = lastSize; i < (lastSize + 10); i++) {
          currentSize++;
          docList.add(querySnapshot.documents[i].documentID);
          uploaderList.add(querySnapshot.documents[i].data["uploader"]);
          urlList.add(querySnapshot.documents[i].data["uploadUrl"]);
          captionList.add(querySnapshot.documents[i].data["caption"]);
          List<dynamic> likers = querySnapshot.documents[i].data["likedBy"];
          likeCount.add(likers.length);
          likeList.add(likers.contains(username));
          flareList.add(FlareControls());
          if (currentSize == (lastSize + 10)) {
            break;
          }
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "You are caught up!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    setState(() {});
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Flippo"),
            actions: [
              IconButton(icon: Icon(Icons.exit_to_app), onPressed: () {
                _auth.signOut().whenComplete(() => Navigator.push(
            context, MaterialPageRoute(builder: (context) => MyHomePage())));
              })
            ],
          ),
          body: urlList.isNotEmpty
              ? SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: true,
                  header: WaterDropHeader(),
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: ListView.builder(
                    itemBuilder: (context, index) => GestureDetector(
                      onDoubleTap: () => like(index),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            width: MediaQuery.of(context).size.width,
                            child: RichText(
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                text: TextSpan(
                                    text: uploaderList[index],
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 20))),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          width: 1, color: Colors.black)),
                                  width: MediaQuery.of(context).size.width,
                                  child: Image.network(
                                    urlList[index],
                                    width: MediaQuery.of(context).size.width,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                                Center(
                                  child: SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: FlareActor(
                                      'assets/instagram_like.flr',
                                      controller: flareList[index],
                                      animation: 'idle',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.black, width: 2)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                      padding: EdgeInsets.all(10),
                                      width: 40,
                                      child: GestureDetector(
                                          onTap: () => like(index),
                                          child: Column(
                                            children: [
                                              likeList[index]
                                                  ? Icon(
                                                      Icons.favorite,
                                                      size: 30,
                                                      color: Colors.red,
                                                    )
                                                  : Icon(
                                                      Icons.favorite_border,
                                                      size: 30,
                                                      color: Colors.black,
                                                    ),
                                              Center(
                                                  child: Text(
                                                      "${likeCount[index]}"))
                                            ],
                                          ))),
                                  Container(
                                      padding: EdgeInsets.all(10),
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              40),
                                      child: RichText(
                                          overflow: TextOverflow.fade,
                                          maxLines: 3,
                                          text: TextSpan(
                                              text: captionList[index],
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 17.5)))),
                                ],
                              ))
                        ],
                      ),
                    ),
                    itemCount: urlList.length,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      new Icon(
                        Icons.mood_bad,
                        size: MediaQuery.of(context).size.width / 4,
                      ),
                      RichText(
                          overflow: TextOverflow.fade,
                          maxLines: 3,
                          text: TextSpan(
                              text: "No images found!",
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 30))),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _settingModalBottomSheet(context);
            },
            tooltip: 'Post Photos',
            child: Icon(Icons.add),
          ),
        ),
        onWillPop: _onWillPop);
  }

  like(int index) async {
    flareList[index].play("like");
    if (likeList[index]) {
      _db.collection("Posts").document(docList[index]).updateData({
        "likedBy": FieldValue.arrayRemove([username]),
      });

      setState(() {
        likeCount[index]--;
        likeList[index] = false;
      });
    } else {
      _db.collection("Posts").document(docList[index]).updateData({
        "likedBy": FieldValue.arrayUnion([username]),
      });

      File file = await urlToFile(urlList[index]);
      GallerySaver.saveImage(file.path).then((bool Success) {
        setState(() {
          print("Success");
        });
      });

      setState(() {
        likeCount[index]++;
        likeList[index] = true;
      });
    }
  }

  Future<File> urlToFile(String imageUrl) async {
    var rng = new Random();
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File file = new File('$tempPath' + (rng.nextInt(100)).toString() + '.jpg');
    http.Response response = await http.get(imageUrl);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  void sendData2() async {}

  getPostList() async {
    return await Firestore.instance
        .collection('Posts')
        .orderBy('timeStamp', descending: true)
        .getDocuments();
  }

  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = File(pickedFile.path);
      _cropImage();
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _image = File(pickedFile.path);
      _cropImage();
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Are you sure?'),
            content: new Text('You want to exit an App'),
            actions: <Widget>[
              new FlatButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: new Text('No'),
              ),
              new FlatButton(
                onPressed: () => exit(0),
                child: new Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: () {
                          getImageFromGallery();
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            new Icon(
                              Icons.image,
                              size: MediaQuery.of(context).size.width / 6,
                            ),
                            RichText(
                                overflow: TextOverflow.fade,
                                maxLines: 3,
                                text: TextSpan(
                                    text: "Gallery",
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 20))),
                          ],
                        ),
                      ),
                      width: MediaQuery.of(context).size.width / 2,
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: () {
                          getImageFromCamera();
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            new Icon(
                              Icons.camera_alt,
                              size: MediaQuery.of(context).size.width / 6,
                            ),
                            RichText(
                                overflow: TextOverflow.fade,
                                maxLines: 3,
                                text: TextSpan(
                                    text: "Camera",
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 20))),
                          ],
                        ),
                      ),
                      width: MediaQuery.of(context).size.width / 2,
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  Future<Null> _cropImage() async {
    File croppedFile = await ImageCropper.cropImage(
        sourcePath: _image.path,
        aspectRatioPresets: Platform.isAndroid
            ? [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio5x3,
                CropAspectRatioPreset.ratio5x4,
                CropAspectRatioPreset.ratio7x5,
                CropAspectRatioPreset.ratio16x9
              ],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        iosUiSettings: IOSUiSettings(
          title: 'Cropper',
        ));
    if (croppedFile != null) {
      _image = croppedFile;
      uploadPic();
      Fluttertoast.showToast(
          msg: "Your image is being uploaded!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  uploadPic() async {
    StorageUploadTask uploadTask =
        storageReference.child("images/$username($count)").putFile(_image);
    uploadUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    _showMyDialog(uploadUrl);
  }

  Future<void> _showMyDialog(String uploadUrl) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a Caption'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.file(_image, height: 300.0, width: 300.0),
                TextField(
                  onChanged: (text) {
                    caption = text;
                  },
                  obscureText: false,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(width: 10),
                    ),
                    fillColor: Colors.lightBlueAccent,
                    labelText: 'Caption',
                    prefixIcon: Icon(Icons.comment),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Add'),
              onPressed: () {
                count++;
                Post post = new Post(caption, uploadUrl, [],
                    new DateTime.now().millisecondsSinceEpoch, username);
                _db.collection("Posts").add(post.toJson());
                _db.collection("Users").document(currentUser.email).updateData({
                  "count": count,
                }).whenComplete(() => _onRefresh());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
