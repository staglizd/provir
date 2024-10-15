import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRScanScreen extends StatefulWidget {
  @override
  _QRScanScreenState createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Postavlja pozadinsku boju na bijelu
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              // Naslov "Provirko" na vrhu
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Center(
                  child: Text(
                    'Provirko',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Postavlja boju teksta na crnu
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,  // Podesite veličinu skenera
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                  child: (result != null)
                      ? Text('Skenirano: ${result!.code}')
                      : Container(), // Prazan container ako nema rezultata
                ),
              ),
            ],
          ),
          // "Skeniraj QR kod" pri dnu ekrana
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Skenirajte QR kod',
                style: TextStyle(
                  fontSize: 16, // Smanjeni font
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Postavlja boju teksta na crnu
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });

      // Otvaranje URL-a u vanjskom pregledniku ako je QR kod URL
      if (Uri.tryParse(result!.code!)?.isAbsolute == true) {
        _launchURL(result!.code!);
      }
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
