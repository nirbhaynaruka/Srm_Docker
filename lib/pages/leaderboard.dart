import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:srm_notes/components/appbar.dart';
import 'package:srm_notes/constants.dart';
import 'package:srm_notes/components/models/loading.dart';

class Leaderboard extends StatefulWidget {
  @override
  _LeaderboardState createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard>
    with SingleTickerProviderStateMixin {
  bool _isAppbar = true;
  ScrollController _scrollController = new ScrollController();

  final _fireStore = Firestore.instance;
  final _auth = FirebaseAuth.instance;

  Widget cardWidget({name, regno, uploads, rank, profilepic}) {
    profilepic = profilepic.toString().replaceAll('~', '//');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Stack(
          children: <Widget>[
            Container(
              height: 90,
              decoration: rank == 1
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(width: 5.0, color: Colors.orange[900]),
                      gradient: LinearGradient(colors: [
                        Colors.orange[700],
                        Colors.amber[200],
                        //  Color.fromRGBO(189, 147, 122,0),
                        //  Color.fromRGBO(229, 214, 114,0),
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryLightColor, //items[index].endColor,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(_borderRadius),
                      gradient: LinearGradient(colors: [
                        // items[index].startColor,
                        // items[index].endColor
                        kPrimaryColor,
                        kPrimaryLightColor
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryLightColor, //items[index].endColor,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              top: 0,
              child: CustomPaint(
                  size: Size(100, 150),
                  painter: rank == 1
                      ? CustomCardShapePainter(
                          _borderRadius,
                          // items[index].startColor, items[index].endColor
                          Colors.amber[900],
                          Colors.amber[200])
                      : CustomCardShapePainter(
                          _borderRadius,
                          // items[index].startColor, items[index].endColor
                          kPrimaryColor,
                          kPrimaryLightColor)),
            ),
            Positioned.fill(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: 70,
                      height: 70,
                      child: Align(
                        alignment: Alignment.center,
                        heightFactor: 0.8,
                        widthFactor: 0.7,
                        child: ClipOval(
                            child: profilepic == "null"
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  )
                                : Image.network(
                                    profilepic,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.fill,
                                  )),
                      ),
                    ),
                    flex: 2,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Column(
                      // mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Avenir',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          regno,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Avenir',
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            // SizedBox(width: 20),
                            Container(
                              child: Text(
                                "Total Uploads : ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  // fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              child: Text(
                                '$uploads',
                                style: TextStyle(
                                  color: rank == 1
                                      ? Colors.amber[900]
                                      : kPrimaryColor,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Rank",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Avenir',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          rank.toString(),
                          style: TextStyle(
                            color:
                                rank == 1 ? Colors.amber[900] : kPrimaryColor,
                            fontFamily: 'Avenir',
                            fontSize: 35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        appBarStatus(false);
      }
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        appBarStatus(true);
      }
    });
  }

  void appBarStatus(bool status) {
    setState(() {
      _isAppbar = status;
    });
  }

  final double _borderRadius = 24;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AnimatedContainer(
          // height: _isAppbar ? 70.0 : 0.0,
          duration: Duration(milliseconds: 200),
          child: ConstAppbar(title: "Leaderboard"),
        ),
      ),
      body: Container(
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
            Container(
              child: Column(
                children: <Widget>[
                  StreamBuilder<QuerySnapshot>(
                    stream: _fireStore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.data == null) {
                        return Loading();
                      }

                      final usersdata = snapshot.data.documents.toList();
                      usersdata
                          .sort((a, b) => b['uploads'].compareTo(a['uploads']));
                      List<Widget> wid = [];
                      int rank = 0;
                      for (var user in usersdata) {
                        rank = rank + 1;
                        final name = user.data['name'];
                        final email = user.data['email'];
                        _fireStore
                            .collection('users')
                            .document(email)
                            .updateData({'rank': rank.toString()});
                        final regid = user.data['regno'];
                        var uploads = user.data['uploads'];
                        var profile = user.data['profilepic'];
                        final mw = cardWidget(
                            name: name,
                            regno: regid,
                            uploads: uploads,
                            rank: rank,
                            profilepic: profile);
                        wid.add(mw);
                      }
                      return Expanded(
                        child: ListView(
                          children: wid,
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shape cards with custom colors

class CustomCardShapePainter extends CustomPainter {
  final double radius;
  final Color startColor;
  final Color endColor;

  CustomCardShapePainter(this.radius, this.startColor, this.endColor);

  @override
  void paint(Canvas canvas, Size size) {
    var radius = 24.0;

    var paint = Paint();
    paint.shader = ui.Gradient.linear(
        Offset(0, 0), Offset(size.width, size.height), [
      HSLColor.fromColor(startColor).withLightness(0.8).toColor(),
      endColor
    ]);

    var path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(
          size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, radius)
      ..quadraticBezierTo(size.width, 0, size.width - radius, 0)
      ..lineTo(size.width - 1.5 * radius, 0)
      ..quadraticBezierTo(-radius, 2 * radius, 0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// User Details

class PlaceInfo {
  final String name;
  final String regno;
  final int uploadno;
  final int likeno;
  final int rank;
  final Color startColor;
  final Color endColor;

  PlaceInfo(this.name, this.startColor, this.endColor, this.rank, this.regno,
      this.uploadno, this.likeno);
}

//Rating stars

class RatingBar extends StatelessWidget {
  final double rating;

  const RatingBar({Key key, this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rating.floor(), (index) {
        return Icon(
          Icons.star,
          color: Colors.white,
          size: 16,
        );
      }),
    );
  }
}
