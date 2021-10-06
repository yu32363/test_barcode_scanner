import 'dart:developer';
import 'package:barcode_scanner/main.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class BarCodeReader extends StatefulWidget {
  const BarCodeReader({Key? key}) : super(key: key);

  @override
  _BarCodeReaderState createState() => _BarCodeReaderState();
}

class _BarCodeReaderState extends State<BarCodeReader> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final assetsAudioPlayer = AssetsAudioPlayer();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _sendDataBack(BuildContext context) {
    String qrResult = result!.code;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(
          codeResult: qrResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(flex: 2, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                    onPressed: () async {
                      await controller?.toggleFlash();
                      setState(() {});
                    },
                    // ignore: unrelated_type_equality_checks
                    icon: FutureBuilder(
                      future: controller?.getFlashStatus(),
                      builder: (context, snapshot) {
                        return Icon(
                          snapshot.data == true
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: snapshot.data == true
                              ? Colors.amber
                              : Colors.black54,
                          size: 40,
                        );
                      },
                    )),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    result == null
                        ? const Text(
                            'สแกนโค้ดรูปแบบที่ต้องการ\n(Datamatrix, PDF417, 1D, QRcode)',
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            'โค้ดที่อ่านได้: ${result?.code}',
                          ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    _sendDataBack(context);
                  },
                  child: const Text('ยืนยัน'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'ย้อนกลับ',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = MediaQuery.of(context).size.width;
    // < 400 ||
    //     MediaQuery.of(context).size.height < 400)
    // ? 300.0
    // : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      assetsAudioPlayer.open(
        Audio('audios/notification.wav'),
        autoStart: true,
      );
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
