import 'package:Flippo/User.dart';
import 'package:Flippo/timeline.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MySignUpPage extends StatefulWidget {
  @override
  _MySignUpPageState createState() => _MySignUpPageState();
}

class _MySignUpPageState extends State<MySignUpPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 17.5);

  String username;
  String name;
  String bio;
  String email;
  String password;
  bool isAgreed = false;

  final databaseReference = Firestore.instance;
  AuthResult result;
  List<String> usernameList = [];

  @override
  void initState() {
    super.initState();
    databaseReference
        .collection("Users")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) => usernameList.add(f.data["username"]));
    });
  }

  Widget build(BuildContext context) {
    final Firestore _db = Firestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final usernameField = Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: TextField(
        onChanged: (text) {
          username = text;
        },
        obscureText: false,
        style: style,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(width: 10),
          ),
          fillColor: Colors.lightBlueAccent,
          labelText: 'Username',
          prefixIcon: Icon(Icons.account_circle),
        ),
      ),
    );

    final emailField = Container(
        margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: TextField(
          onChanged: (text) {
            email = text;
          },
          obscureText: false,
          style: style,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(width: 10),
            ),
            fillColor: Colors.lightBlueAccent,
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ));
    final passwordField = Container(
      margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: TextField(
        onChanged: (text) {
          password = text;
        },
        obscureText: true,
        style: style,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(width: 10),
          ),
          fillColor: Colors.lightBlueAccent,
          labelText: 'Password',
          prefixIcon: Icon(Icons.lock),
        ),
      ),
    );

    final checkIfAdmin = Container(
        margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.lightBlueAccent,
        ),
        alignment: Alignment.center,
        child: CheckboxListTile(
          title: Text("Terms and Conditions"),
          onChanged: (bool value) {
            setState(() {
              isAgreed = value;
            });
          },
          value: isAgreed,
          activeColor: Colors.lightBlueAccent,
        ));

    return Scaffold(
        appBar: AppBar(
          title: Text("Sign Up Page"),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(5, 50, 5, 0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  usernameField,
                  emailField,
                  passwordField,
                  checkIfAdmin,
                  new RaisedButton(
                    shape: StadiumBorder(),
                    color: Colors.lightBlueAccent,
                    child: Text("Sign Up"),
                    onPressed: () async {
                      if (isAgreed) {
                        if (validateUsername(username) &&
                            (!usernameList.contains(username))) {
                          if (validateEmail(email)) {
                            try {
                              result =
                                  await _auth.createUserWithEmailAndPassword(
                                      email: email, password: password);
                              if (result.user != null) {
                            User user = new User(
                                username,
                                0);
                            _db
                                .collection("Users")
                                .document(email)
                                .setData(user.toJson());
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => MyTimeLinePage()));
                              }
                            } catch (e) {
                              Fluttertoast.showToast(
                                  msg: e.toString(),
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please enter a valid email',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                        } else if (!validateUsername(username)) {
                          Fluttertoast.showToast(
                              msg: 'Username is invalid',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                          return;
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Username is already taken',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                          return;
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: 'Please agree to the terms and conditions',
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                    },
                  ),
                ]),
          ),
        ));
  }

  bool validateUsername(String userName) {
    final validCharacters = RegExp(r'^[a-zA-Z0-9_\-=@,\.;]+$');
    return validCharacters.hasMatch(userName);
  }

  bool validateEmail(String emailValid) {
    final validCharacters = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return validCharacters.hasMatch(emailValid);
  }
}
