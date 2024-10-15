import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provir_search/screens/report_pollution_screen.dart';
import 'package:provir_search/screens/qr_scan_screen.dart';
import 'package:provir_search/screens/info_screen.dart';
import 'package:provir_search/screens/about_us_screen.dart';
import 'package:provir_search/screens/profile_screen.dart';
import 'package:provir_search/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoogleSignIn _googleSignIn = GoogleSignIn();

void signOut(BuildContext context) async {
  await _googleSignIn.signOut();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}

Future<bool> isUserLoggedIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? email = prefs.getString('email');
  return email != null;  // Ako je email spremljen, korisnik je prijavljen
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 0;
  bool _isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Provjerava status prijave i postavlja _isUserLoggedIn
  void _checkLoginStatus() async {
    bool loggedIn = await isUserLoggedIn();
    setState(() {
      _isUserLoggedIn = loggedIn;
    });
  }

  List<Widget> _screens = [
    MapScreenContent(), // Your map content here
    ProfileScreen(), // Show only if the user is logged in
    InfoScreen(),
    AboutUsScreen(),
  ];

  List<BottomNavigationBarItem> _buildBottomNavigationItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Karta',
      ),
      if (_isUserLoggedIn)  // Prikazujemo "Profil" samo ako je korisnik prijavljen
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      BottomNavigationBarItem(
        icon: Icon(Icons.info),
        label: 'Informacije',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.more_vert),
        label: 'O nama',
      ),
    ];
    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Karta';
      case 1:
        return 'Profil';
      case 2:
        return 'Informacije';
      case 3:
        return 'O nama';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex), style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF151E48),
        actions: [
          if (_isUserLoggedIn && _selectedIndex == 1) // Prikazuj logout button samo na "Profil" ekranu
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white,),
              onPressed: () => signOut(context),
            ),
        ],
      ),
      /*
      appBar: AppBar(
        title: Text('Provir SEA.R.C.H'),
        actions: [
          if (_isUserLoggedIn && _selectedIndex == 1) // Prikazuj logout button samo na "Profil" ekranu
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => signOut(context),
            ),
        ],
      ),
      */
      body: _screens[_selectedIndex],

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Color(0xFF151E48), // Postavljanje pozadine
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          items: _buildBottomNavigationItems(),
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (!_isUserLoggedIn && index == 1) return;
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),

      /*
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF151E48),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Use transparent as Container has the color
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          items: _buildBottomNavigationItems(),
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (!_isUserLoggedIn && index == 1) return;
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      */

      /*
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF151E48), // Postavljanje pozadine
        selectedItemColor: Colors.white,    // Bijela boja za odabrani element
        unselectedItemColor: Colors.grey,   // Siva boja za neodabrane elemente
        items: _buildBottomNavigationItems(),
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Ako korisnik nije prijavljen, nemoj dozvoliti odabir 2. elementa (Profil)
          if (!_isUserLoggedIn && index == 1) return;
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      */

      floatingActionButton: _selectedIndex == 0 ?
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ReportPollutionScreen()),
              );
            },
            child: Icon(Icons.report),
            tooltip: 'Prijavi onečišćenje',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => QRScanScreen()),
              );
            },
            child: Icon(Icons.qr_code_scanner),
            tooltip: 'Skeniraj QR kod',
          ),
        ],
      ): null, // Sakrij gumb na drugim ekranima
    );
  }
}

class MapScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(45.815399, 15.966568),
          initialZoom: 12,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(-90, -180),
              const LatLng(90, 180),
            ),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
        ],
      );
  }
}

/*
class MapScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provir SEA.R.C.H'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(45.815399, 15.966568),
          initialZoom: 12,
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(-90, -180),
              const LatLng(90, 180),
            ),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ReportPollutionScreen()),
              );
            },
            child: Icon(Icons.report),
            tooltip: 'Prijavi onečišćenje',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => QRScanScreen()),
              );
            },
            child: Icon(Icons.qr_code_scanner),
            tooltip: 'Skeniraj QR kod',
          ),
        ],
      ),
    );
  }
}
*/
