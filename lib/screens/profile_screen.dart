import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String?>> getUserInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return {
    'email': prefs.getString('email'),
    'displayName': prefs.getString('displayName'),
    'imageUrl': prefs.getString('imageUrl'),
  };
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _reports = [];
  late Future<Map<String, String?>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = getUserInfo();
    _userInfoFuture.then((userInfo) {
      if (userInfo['email'] != null) {
        _fetchReports(userInfo['email']!);
      }
    });
  }

  Future<void> _fetchReports(String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://blaslov.smart-solutions.hr/api/get_locations.php'),
        body: {'ime_korisnika': email}, // Email logiranog korisnika
      );

      if (response.statusCode == 200) {
        setState(() {
          _reports = json.decode(response.body);
        });
      } else {
        print('Greška prilikom dohvaćanja prijava');
      }
    } catch (error) {
      print('Greška: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, String?>>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Greška pri dohvaćanju korisničkih podataka'));
          } else if (!snapshot.hasData || snapshot.data!['email'] == null) {
            return Center(child: Text('Niste prijavljeni'));
          }

          var userInfo = snapshot.data!;
          return Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userInfo['imageUrl']!), // imageUrl
              ),
              SizedBox(height: 10),
              Text(
                userInfo['displayName'] ?? 'Korisnik', // displayName
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text("Vaše prijave", style: TextStyle(fontSize: 18)),
              Divider(),
              // Expanded is necessary to handle overflow in the ListView
              Expanded(
                child: ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    var report = _reports[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(report['recordUser']['photoUrl']),
                              radius: 20,
                            ),
                            SizedBox(width: 10),
                            Text(report['recordUser']['displayName']),
                          ],
                        ),
                        Text(
                          report['recordName'],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          report['recordDescription'],
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${_getStatusText(report['recordStatus'])} ${_formatTimestamp(report['recordCreated'])}',
                          style: TextStyle(fontSize: 12),
                        ),
                        Divider(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  String _getStatusText(int status) {
    if (status == 0) return "Stvoreno:";
    if (status == 1) return "Viđeno:";
    return "Riješeno:";
  }

  String _formatTimestamp(int timestamp) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}:${date.second}";
  }
}
