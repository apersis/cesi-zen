import 'dart:async';

import 'package:flutter/material.dart';

class AppBarScreen extends StatefulWidget {
  const AppBarScreen({super.key, required this.pageName});

  final String pageName;

  @override
  _AppBarScreenState createState() => _AppBarScreenState();
}

class _AppBarScreenState extends State<AppBarScreen> {
  double _hue = 0.0; // Teinte de couleur (0° à 360°)
  late Timer _timer;
  late final pageName;

  @override
  void initState() {
    super.initState();
    // Démarrer le changement de couleur
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _hue = (_hue + 2) % 360; // Augmenter la teinte pour faire un cycle arc-en-ciel
      });
    });
    pageName = widget.pageName;
  }

  @override
  void dispose() {
    _timer.cancel(); // Arrêter le timer quand l'écran est fermé
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: Stack(
          children: [
              // Texte en blanc, légèrement plus gros pour l'effet de contour
              Text(
                pageName,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Colors.white, // Contour blanc
                ),
              ),
              // Texte noir, légèrement plus petit et au-dessus
              Text(
                pageName,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Texte noir
                ),
              ),
            ],
          ),
        backgroundColor: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
      );
  }
}