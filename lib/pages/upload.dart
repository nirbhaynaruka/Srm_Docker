import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_radio_grouped_button/custom_radio_grouped_button.dart';
import 'package:dropdown_banner/dropdown_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';
import 'package:srm_notes/components/appbar.dart';
import 'package:srm_notes/components/models/loading.dart';
import '../constants.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

FirebaseUser loggedInUser;

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final navigatorKey = GlobalKey<NavigatorState>();

  final _fireStore = Firestore.instance;
  final store = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final GlobalKey dropdownKey = GlobalKey();

  ///
  File _imagefile;
  bool cameraimage = false;
  var total;
  var rem = 1;

  ///
  String _fileName;
  File _path;
  List<File> multifile;
  Map<String, String> _paths;
  String _extension;
  bool _loadingPath = false;
  bool _multiPick = true;
  FileType _pickingType = FileType.custom;
  TextEditingController _controller = new TextEditingController();
  Color color = kPrimaryLightColor;
  File image;
  bool notes = true;
  bool asTabs = false;
  String selectedSub;
  String selectedSubCode;
  String selectedSubyear;
  String selectedSubbranch;
  String selectedSubdept;

  String preSelectedDoc = "Notes";
  bool uploading = false;
  // List<String> _items = ['Machine Learning', 'Maths'];
  Map<String, Widget> widgets;
  String url;
  List<dynamic> data = []; //edited line
  ///
  Future<void> _pickImage() async {
    File selected = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 85);
    setState(() {
      _imagefile = selected;
      if (selected != null) {
        cameraimage = true;
      }
    });
  }

  bool isLoading = false;

  ///
  Future<String> getSWData() async {
    //Get Latest version info from firebase config
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    try {
      // Using default duration to force fetching from remote server.
      await remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await remoteConfig.activateFetched();
      url = remoteConfig.getString('subject_list');
      var res = await http
          .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});
      var resBody = json.decode(res.body);
      setState(() {
        data = resBody;
      });
    } on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      //    navigatorKey:
      // navigatorKey;
      DropdownBanner.showBanner(
        text: 'Poor Internet Connection, Unable to fetch subjects',
        color: Colors.red,
        textStyle: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      );
      print('Unable to fetch remote config. Cached or default values will be '
          'used');
    }

    return "Sucess";
  }

  @override
  void initState() {
    getCurrentUser();
    getSWData();
    _controller.addListener(() => _extension = _controller.text);
    super.initState();
  }

  void _openFileExplorer() async {
    setState(() => _loadingPath = true);
    try {
      if (_multiPick) {
        // _path = await FilePicker.getMultiFilePath(allowedExtensions: ['pdf']),
        _paths = null;
        multifile = await FilePicker.getMultiFile(
            type: _pickingType,
            allowedExtensions: [
              'jpg',
              'pdf',
              'doc',
              'docx',
              'xlsx',
              'png',
              'txt',
              'ppt',
              'pptx'
            ]);

        for (File _file in multifile) print(_file.path.toString());
        // (_extension?.isNotEmpty ?? false) ? _extension?.replaceAll(' ', '')?.split('OOOO') : null);
      } else {
        _paths = null;
        _path = await FilePicker.getFile(
            type: _pickingType,
            allowedExtensions: [
              'jpg',
              'pdf',
              'doc',
              'docx',
              'xlsx',
              'png',
              'txt',
              'ppt',
              'pptx'
            ]);
        print(_fileName);
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;
    setState(() {
      _loadingPath = false;
    });
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  Future makefolder() async {
    var response = await Firestore.instance
        .collection("Subjects")
        .document(selectedSub)
        .setData({
      'name': selectedSub,
      'code': selectedSubCode,
      'year': selectedSubyear,
      'branch': selectedSubbranch,
      'dept': selectedSubdept
    });
  }

  Future savedoc(File file, String name) async {
    print(file.path);
    _fileName = name.toString().replaceAll("'", "");
    final StorageReference firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child(
            "Subjects/" + selectedSub + "/" + preSelectedDoc + "/" + _fileName);
    final StorageUploadTask task = firebaseStorageRef.putFile(file);
    //  firebaseStorageRef.putData(file);
    StorageTaskSnapshot taskSnapshot = await task.onComplete;
    print("upload complete");
    await setState(() {
      rem = rem + 1;
    });
    String url = await taskSnapshot.ref.getDownloadURL();
    url = url.replaceAll('//', '~');
    print(url);
    var response = await Firestore.instance
        .collection(selectedSub)
        .document("${DateTime.now()}")
        .setData({
      'name': _fileName,
      'sender': loggedInUser.email,
      'url': url,
      'time': DateTime.now().toString().split('at')[0],
      'doc': preSelectedDoc,
    });
    var uploads;
    await _fireStore
        .collection('users')
        .document(loggedInUser.email)
        .get()
        .then((value) {
      uploads = value.data['uploads'];
    });
    uploads = uploads + 1;
    await _fireStore
        .collection('users')
        .document(loggedInUser.email)
        .updateData({'uploads': uploads});
    return url;
  }

  void openDropdown() {
    GestureDetector detector;
    void searchForGestureDetector(BuildContext element) {
      element.visitChildElements((element) {
        if (element.widget != null && element.widget is GestureDetector) {
          detector = element.widget;
          return false;
        } else {
          searchForGestureDetector(element);
        }
        return true;
      });
    }

    searchForGestureDetector(dropdownKey.currentContext);
    assert(detector != null);
    detector.onTap();
  }

  double i = 0;

  void _clearCachedFiles() {
    setState(() => {_loadingPath = true, cameraimage = false, rem = 1});
    FilePicker.clearTemporaryFiles().then((result) {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Select new files',
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return DropdownBanner(
      child: Scaffold(
        key: _scaffoldKey,
        // extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          child: ConstAppbar(title: "Upload"),
          preferredSize: Size.fromHeight(50.0),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            child: Icon(Icons.camera),
            elevation: 0,
            backgroundColor: kPrimaryColor,
            onPressed: () {
              _pickImage();
              // cameraimage = true;
            },
          ),
        ),
        body:
            //  uploading
            //     ? Loading()
            //     :
            Container(
          height: size.height,
          width: double.infinity,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  "assets/images/signup_top.png",
                  width: size.width * 0.35,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Image.asset(
                  "assets/images/main_bottom.png",
                  width: size.width * 0.25,
                ),
              ),
              // notes ? notespage() : questionpage(),
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    // SizedBox(height: size.height * 0.02),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 2.0, color: color),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SearchableDropdown(
                          key: dropdownKey,
                          //ese SearchableDropdown.single for suffix icon
                          underline: SizedBox(width: 20),
                          iconEnabledColor: kPrimaryColor,
                          iconDisabledColor: Colors.black,
                          items: data.map((item) {
                            return new DropdownMenuItem(
                              child: new Text(item['Course Title']),
                              value: item['Course Title'].toString(),
                            );
                          }).toList(),
                          // _items.map((item) {
                          //   return DropdownMenuItem(
                          //     child: new Text(item),
                          //     value: item,
                          //   );
                          // }).toList(),
                          value: selectedSub,
                          hint: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text("Select Course"),
                          ),
                          searchHint: Text("Select one"),
                          onChanged: (value) {
                            setState(() {
                              selectedSub = value;

                              for (dynamic items in data) {
                                if (items['Course Title'] == value) {
                                  selectedSubCode = items['Course Code'];
                                  selectedSubyear = items['Year'].toString();
                                  selectedSubbranch = items['Branch'];
                                  selectedSubdept = items['Dept'];
                                }
                              }
                              color = kPrimaryColor;

                              // width_dropd = 2.0;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),

                      ///change radiobutton and use [preSelectedDoc] as the changed [value]
                      child: CustomRadioButton(
                        autoWidth: false,
                        width: 150,
                        enableShape: true,
                        elevation: 5.0,
                        buttonColor: Theme.of(context).canvasColor,
                        buttonLables: [
                          "Notes",
                          "Question Paper",
                        ],
                        buttonValues: [
                          "Notes",
                          "Question_Paper",
                        ],
                        radioButtonValue: (value) => {
                          setState(() {
                            preSelectedDoc = value;
                          }),
                        },
                        selectedColor: kPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: cameraimage
                              ? null
                              : Text("Tap on Image to select File❓"),
                        ),
                        Container(
                          child: cameraimage
                              ? Container(
                                  height: size.height * 0.30,
                                  child: new Builder(
                                    builder: (BuildContext context) =>
                                        GestureDetector(
                                            child: Container(
                                      child: Image.file(_imagefile),
                                    )),
                                  ))
                              : Container(
                                  height: size.height * 0.30,
                                  child: new Builder(
                                    builder: (BuildContext context) =>
                                        GestureDetector(
                                      onTap: () {
                                        _openFileExplorer();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/images/uploaddone.png",
                                            ),
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        child: _loadingPath
                                            ? GestureDetector(
                                                onTap: () {
                                                  _openFileExplorer();
                                                },
                                                // child: Container(
                                                //   decoration: BoxDecoration(
                                                //     image: DecorationImage(
                                                //       image: AssetImage(
                                                //         "assets/images/uploaddone.png",
                                                //       ),
                                                //       fit: BoxFit.contain,
                                                //     ),
                                                //   ),
                                                // ),
                                              )
                                            : multifile != null ||
                                                    _paths != null
                                                ? new Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10.0),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.50,
                                                    child: new Scrollbar(
                                                      child:
                                                          new ListView.builder(
                                                        itemCount: multifile !=
                                                                    null &&
                                                                multifile
                                                                    .isNotEmpty
                                                            ? multifile.length
                                                            : 1,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int index) {
                                                          final String name =
                                                              'File $index: ' +
                                                                  multifile[
                                                                          index]
                                                                      .toString()
                                                                      .split(
                                                                          '/')
                                                                      .last;
                                                          total = index + 1;
                                                          // rem = total;
                                                          return Container(
                                                            margin: EdgeInsets
                                                                .fromLTRB(
                                                                    8.0,
                                                                    8.0,
                                                                    8.0,
                                                                    0.0),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  kPrimaryLightColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                            ),
                                                            child: new ListTile(
                                                              leading:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                child: Icon(
                                                                  Icons
                                                                      .attachment,
                                                                  color: Colors
                                                                      .green,
                                                                ),
                                                              ),
                                                              trailing: Icon(
                                                                Icons.check,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                              title: new Text(
                                                                  name),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                : new Container(
                                                    // child: Image.asset(
                                                    //   "assets/images/upload.png",
                                                    //   width: size.width * 0.70,
                                                    // ),
                                                    ),
                                      ),
                                    ),
                                  )),
                        ),
                        SizedBox(height: size.height * 0.03),
                        new Column(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                _clearCachedFiles();
                              },
                              child: Text(
                                "Clear present files",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            cameraimage
                                ? GestureDetector(
                                    onTap: () {
                                      // setState(() {
                                      setState(() async {
                                        // get file name
                                        _fileName = _imagefile
                                            .toString()
                                            .split('/')
                                            .last;

                                        if (_imagefile != null &&
                                            selectedSub != null) {
                                          // uploading = true;

                                          //call uploading function
                                          await makefolder();
                                          await savedoc(_imagefile, _fileName);
                                        } else {
                                          setState(() {
                                            openDropdown();
                                          });
                                        }
                                      });
                                      _clearCachedFiles();
                                    },
                                    child: Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 10),
                                      width: size.width * 0.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(29),
                                        child: isLoading
                                            ? Container(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Center(
                                                      child: Image.asset(
                                                        "assets/images/load.gif",
                                                        color: kPrimaryColor,
                                                        width: size.width * 0.3,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Uploading...",
                                                      style: TextStyle(
                                                        color: kPrimaryColor,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                color: kPrimaryColor,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 15,
                                                    horizontal: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "Upload Image",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20.0),
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            size.width * 0.02),
                                                    Icon(
                                                      Icons.file_upload,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () async {
                                      // setState(() {
                                      i = 0;
                                      for (File file in multifile) {
                                        setState(() {
                                          isLoading = true;
                                          i = i + 1;
                                        });
                                        // get file name
                                        _fileName =
                                            file.toString().split('/').last;

                                        if (file != null &&
                                            selectedSub != null) {
                                          // uploading = true;

                                          //call uploading function
                                          await makefolder();
                                          await savedoc(file, _fileName);
                                          setState(() {
                                            isLoading = false;
                                          });
                                        } else {
                                          setState(() {
                                            isLoading = false;
                                            openDropdown();
                                          });
                                        }
                                      }
                                      _clearCachedFiles();
                                    },
                                    child: Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 10),
                                      width: size.width * 0.5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(29),
                                        child: isLoading
                                            ? Container(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Center(
                                                      child: Image.asset(
                                                        "assets/images/load.gif",
                                                        color: kPrimaryColor,
                                                        width: size.width * 0.3,
                                                      ),
                                                    ),
                                                    rem == 2
                                                        ? Text(
                                                            'ALL DONE 👍',
                                                          )
                                                        : Text(
                                                            '$rem / $total Uploading...',
                                                            
                                                          ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                color: kPrimaryColor,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 15,
                                                    horizontal: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "Upload",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20.0),
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            size.width * 0.02),
                                                    Icon(
                                                      Icons.file_upload,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                            SizedBox(height: size.height * 0.02),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
