import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/CustomBottomNavBar.dart';
import 'recommendation.dart';

class ResultsScreen extends StatefulWidget {
  final String hydrationResult;
  final String utiRisk;
  final String confidence;
  final File? imageFile;
  final List<Map<String, dynamic>>? detections;

  const ResultsScreen({
    super.key,
    required this.hydrationResult,
    required this.utiRisk,
    required this.confidence,
    this.imageFile,
    this.detections,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedIndex = 2;
  ui.Image? _image;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _addNotification();
    if (widget.imageFile != null) _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _image = frame.image;
          _loaded = true;
        });
        print('Image loaded: ${frame.image.width}x${frame.image.height}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _addNotification() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': uid,
        'title': 'New Analysis Result',
        'message':
            'UTI Risk: ${widget.utiRisk}, Hydration: ${widget.hydrationResult}',
        'createdAt': Timestamp.now(),
        'read': false,
      });
    } catch (e) {}
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/instructions');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetections =
        widget.detections != null && widget.detections!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Analysis Results',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ONLY IMAGE WITH POLYGON LINES
            if (widget.imageFile != null) ...[
              if (!_loaded)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: hasDetections && _image != null
                      ? AspectRatio(
                          aspectRatio: _image!.width / _image!.height,
                          child: CustomPaint(
                            painter: PolygonOnlyPainter(
                              image: _image!,
                              detections: widget.detections!,
                            ),
                          ),
                        )
                      : Image.file(widget.imageFile!, fit: BoxFit.contain),
                ),
            ],

            const SizedBox(height: 24),

            // Results cards
            Text(
              'Your Results:',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              'Analysis Result',
              widget.hydrationResult,
              '',
              Icons.water_drop,
              Colors.teal,
            ),
            const SizedBox(height: 16),
            _card(
              'UTI Risk',
              widget.utiRisk,
              widget.confidence,
              MdiIcons.alertCircleOutline,
              Colors.green,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationScreen(
                      utiRisk: widget.utiRisk,
                      hydrationResult: widget.hydrationResult,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'See Recommendations',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _card(
    String title,
    String status,
    String conf,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                if (conf.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Confidence: $conf%",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// ENHANCED DEBUG PAINTER - DRAWS POLYGON LINES
// ============================================
class PolygonOnlyPainter extends CustomPainter {
  final ui.Image image;
  final List<Map<String, dynamic>> detections;

  PolygonOnlyPainter({required this.image, required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    print('═══════════════════════════════════════════════════');
    print(' PAINT METHOD CALLED');
    print(' Canvas size: ${size.width}x${size.height}');
    print(' Image size: ${image.width}x${image.height}');
    print(' Detections count: ${detections.length}');

    // 1. Draw the image
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: BoxFit.contain,
    );

    // 2. Calculate scale
    final imgAspect = image.width / image.height;
    final canvasAspect = size.width / size.height;

    double scale, offsetX, offsetY;

    if (canvasAspect > imgAspect) {
      scale = size.height / image.height;
      offsetX = (size.width - image.width * scale) / 2;
      offsetY = 0;
    } else {
      scale = size.width / image.width;
      offsetX = 0;
      offsetY = (size.height - image.height * scale) / 2;
    }

    print('📐 Scale: $scale, Offset: ($offsetX, $offsetY)');

    // 3. Draw polygons with EXTENSIVE debugging
    for (int i = 0; i < detections.length; i++) {
      final det = detections[i];
      print('-------------------------------------------');
      print('🔹 Detection #$i:');
      print('   Class: ${det['class']}');
      print('   Confidence: ${det['confidence']}');
      print('   Has polygon key: ${det.containsKey('polygon')}');

      final polygon = det['polygon'];

      if (polygon == null) {
        print('Polygon is NULL');
        continue;
      }

      if (polygon is! List) {
        print('Polygon is not a List, it is: ${polygon.runtimeType}');
        continue;
      }

      if (polygon.isEmpty) {
        print('Polygon is EMPTY');
        continue;
      }

      print('Polygon has ${polygon.length} points');

      // Print first 3 points for debugging
      for (int j = 0; j < 3 && j < polygon.length; j++) {
        print('   Point $j: ${polygon[j]}');
      }

      // Choose color based on class
      final className = (det['class'] as String? ?? '').toLowerCase();
      Color lineColor;

      if (className.contains('normal')) {
        lineColor = Colors.green;
      } else if (className.contains('dehydrated')) {
        lineColor = Colors.orange;
      } else if (className.contains('uti')) {
        lineColor = Colors.red;
      } else {
        lineColor = Colors.blue;
      }

      print('Drawing with color: $lineColor');

      // Build path
      final path = Path();
      bool first = true;
      int validPoints = 0;

      for (var point in polygon) {
        // Handle different point formats
        double? x, y;

        if (point is Map) {
          x = (point['x'] as num?)?.toDouble();
          y = (point['y'] as num?)?.toDouble();
        }

        if (x == null || y == null) {
          print('Invalid point: $point');
          continue;
        }

        // Scale to canvas coordinates
        double canvasX = (x * scale) + offsetX;
        double canvasY = (y * scale) + offsetY;

        if (first) {
          path.moveTo(canvasX, canvasY);
          print('Start: ($canvasX, $canvasY)');
          first = false;
        } else {
          path.lineTo(canvasX, canvasY);
        }
        validPoints++;
      }

      path.close();

      print('Drew polygon with $validPoints valid points');

      // Draw the path with VERY thick line
      final paint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            8.0 // Extra thick
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, paint);

      // ALSO draw a semi-transparent fill to make it VERY visible
      final fillPaint = Paint()
        ..color = lineColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);

      print('Polygon drawn successfully!');
    }

    print('═══════════════════════════════════════════════════');
  }

  @override
  bool shouldRepaint(PolygonOnlyPainter old) {
    final shouldRepaint = old.image != image || old.detections != detections;
    print('shouldRepaint: $shouldRepaint');
    return shouldRepaint;
  }
}
