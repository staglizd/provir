import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:provir_search/screens/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> saveUserInfo(String email, String displayName, String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('displayName', displayName);
    await prefs.setString('imageUrl', imageUrl);
  }


  Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    print("Google prijava započela...");
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    print("Google korisnik: $googleUser");

    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    print("Google autentikacija: $googleAuth");

    if (googleAuth != null) {
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("Firebase kredencijali kreirani, prijavljujem korisnika...");

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("Prijava na Firebase uspješna!");

      // Dobivanje korisničkih podataka
      User? user = userCredential.user;
      AdditionalUserInfo? additionalInfo = userCredential.additionalUserInfo;

      print("Korisnički podaci: ${user?.email}, ${user?.displayName}, ${user?.photoURL}");
      print("Dodatne informacije: ${additionalInfo?.isNewUser}");

      // Slanje podataka na API nakon uspješne prijave
      if (googleUser != null) {
        await sendUserDataToApi(googleUser);
        await saveUserInfo(googleUser.email, googleUser.displayName!, googleUser.photoUrl!);
      }

      // Prijava uspješna, navigirajte na MapScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MapScreen()),
      );
    } else {
      print("Google autentikacija je null");
    }
  } catch (error) {
    print("Greška prilikom prijave: $error");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Greška prilikom prijave. Pokušajte ponovo.'),
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo aplikacije
            Image.asset(
              'assets/provir_app.webp', // Putanja do vašeg loga
              height: 150, // Visina loga
            ),
            SizedBox(height: 20), // Razmak između loga i gumba

            // Gumb za prijavu s Google računom
            SignInButton(
              Buttons.google,
              text: "Google prijava",
              onPressed: () => _signInWithGoogle(context),
            ),
            SizedBox(height: 10), // Razmak između gumba

            // Gumb za nastavak bez prijave
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              },
              child: Text('Nastavi bez prijave'),
            ),

            SizedBox(height: 20), // Razmak između gumba i teksta

            // Tekst za pravila privatnosti
            GestureDetector(
              onTap: () async {
                const url = 'https://blaslov.smart-solutions.hr/privacy-policy.html'; // Zamijenite sa stvarnim URL-om
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
              child: Text(
                'Pravila privatnosti',
                style: TextStyle(
                  color: Colors.blue, // Boja teksta
                  decoration: TextDecoration.underline, // Podcrtano
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendUserDataToApi(GoogleSignInAccount account) async {
    final url = Uri.parse('https://blaslov.smart-solutions.hr/api/login_user.php');
    
    try {
      print("Šaljem podatke na API: ${account.email}, ${account.displayName}, ${account.photoUrl}");
      
      await http.post(
        url,
        body: {
          'email': account.email,
          'displayName': account.displayName ?? 'Anonymous',
          'imageurl': account.photoUrl ?? '', // Postavljamo link slike, ako postoji
          'device': 'iphone',
        },
      );

      print("Podaci uspješno poslani na API");
    } catch (error) {
      print("Greška prilikom slanja podataka na API: $error");
    }
  }
}
