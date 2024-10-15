import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart'; // Dodano za geolokaciju
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportPollutionScreen extends StatefulWidget {
  @override
  _PollutionReportFormState createState() => _PollutionReportFormState();
}

class _PollutionReportFormState extends State<ReportPollutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _selectedWasteType = 0;
  bool _useMyLocation = false;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false; // Dodano za sprječavanje dvostrukog slanja
  List<File> _selectedImages = [];
  String userName = "";

  late Future<Map<String, String?>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = getUserInfo();
    _userInfoFuture.then((userInfo) {

      if (userInfo['email'] != null) {
        userName = userInfo['email']!;
      }
    });
  }

  final ImagePicker _picker = ImagePicker();

  Future<Map<String, String?>> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email'),
      'displayName': prefs.getString('displayName'),
      'imageUrl': prefs.getString('imageUrl'),
    };
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final image = img.decodeImage(imageFile.readAsBytesSync());
    final compressedImage = img.encodeJpg(image!, quality: 70); // Kompresija na 70% kvalitete
    final compressedFile = File(imageFile.path)..writeAsBytesSync(compressedImage);
    return compressedFile;
  }

  Future<void> _getLocation() async {

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      print('User denied permissions to access the device\'s location.');
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print('Location: ${position.latitude}, ${position.longitude}');
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      } catch (e) {
        print('Greška prilikom dohvaćanja lokacije: $e');
      }
      
    }
    
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return; // Sprječavanje duplog slanja
    setState(() {
      _isSubmitting = true;
    });

    // Provjeri treba li dohvatiti lokaciju
    if (_useMyLocation) {
      await _getLocation(); // Dohvati lokaciju korisnika
    }

    var request = http.MultipartRequest('POST', Uri.parse('https://blaslov.smart-solutions.hr/api/save_location.php'));
    request.fields['naziv'] = _nameController.text;
    request.fields['opis'] = _descriptionController.text;
    request.fields['vrsta'] = _selectedWasteType.toString();
    request.fields['ime_korisnika'] = userName;

    if (_latitude != null && _longitude != null) {
      request.fields['latitude'] = _latitude.toString();
      request.fields['longitude'] = _longitude.toString();
    }

    for (var image in _selectedImages) {
      final compressedImage = await _compressImage(image); // Kompresiraj sliku
      request.files.add(await http.MultipartFile.fromPath('slike[]', compressedImage.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      print('Prijava uspješna');
      Navigator.popUntil(context, (route) => route.isFirst); // Povratak na početni ekran
    } else {
      print('Greška prilikom slanja');
    }

    setState(() {
      _isSubmitting = false; // Omogućavanje ponovnog slanja nakon završetka
    });
  }

  Widget _buildThumbnails() {
    if (_selectedImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedImages.map((image) {
        return Image.file(
          image,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prijavi lokaciju'),
        backgroundColor: Color(0xFF151E48),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Ime', hintText: 'Naziv onečišćenja'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite naziv onečišćenja';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Opis', hintText: 'Opis onečišćenja'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unesite opis onečišćenja';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _selectedWasteType,
                items: [
                  DropdownMenuItem(value: 0, child: Text('Ostali otpad')),
                  DropdownMenuItem(value: 1, child: Text('Ribarske mreže')),
                  DropdownMenuItem(value: 2, child: Text('Plastika')),
                  DropdownMenuItem(value: 3, child: Text('Željezo')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWasteType = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Vrsta otpada'),
              ),
              CheckboxListTile(
                title: Text('Koristi moju lokaciju'),
                value: _useMyLocation,
                onChanged: (value) {
                  setState(() {
                    _useMyLocation = value!;
                  });
                  if (_useMyLocation) {
                    _getLocation(); // Odmah pokuša dohvatiti lokaciju
                  }
                },
              ),
              if (!_useMyLocation)
                Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _latitude = double.tryParse(value);
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _longitude = double.tryParse(value);
                      },
                    ),
                  ],
                ),
              ElevatedButton(
                onPressed: _pickImages,
                child: Text('Odaberi slike'),
              ),
              _buildThumbnails(), // Prikaz thumbnailsa odabranih slika
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Odustani'),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _submitReport();
                            }
                          },
                    child: Text('Pošalji'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
