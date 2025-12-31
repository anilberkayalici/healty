import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../logic/posture_service.dart';

/// Gamified Duruş İzleme Ekranı (Duolingo Tarzı)
/// PostureService'ten gerçek sensör verisi alır, orbit animasyonu yapar
class PostureMonitorScreen extends StatefulWidget {
  const PostureMonitorScreen({super.key});

  @override
  State<PostureMonitorScreen> createState() => _PostureMonitorScreenState();
}

class _PostureMonitorScreenState extends State<PostureMonitorScreen> {
  // Servis katmanı
  final PostureService _postureService = PostureService();
  
  // Stream dinleyicisi
  StreamSubscription<PostureData>? _postureSubscription;
  
  // UI state
  double _currentAngle = 90.0; // Başlangıç: dik duruş
  double _smoothedAngle = 90.0; // Low-pass filtered açı (titreme engelleyici)
  PostureStatus _currentStatus = PostureStatus.safe;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  /// Sensör dinlemeye başla
  void _startListening() {
    _postureService.startMonitoring();
    
    _postureSubscription = _postureService.postureStream.listen(
      (PostureData data) {
        setState(() {
          _currentAngle = data.angle;
          _currentStatus = data.status;
          
          // LOW-PASS FILTER: Sensör titremelerini yumuşat
          // Yeni veri ağırlığı: %15, Eski veri ağırlığı: %85
          // Bu sayede ani değişiklikler absorbe edilir
          _smoothedAngle = (_currentAngle * 0.15) + (_smoothedAngle * 0.85);
        });
      },
    );
  }

  @override
  void dispose() {
    _postureSubscription?.cancel();
    super.dispose();
  }

  // Durum bazlı renk
  Color _getPrimaryColor() {
    switch (_currentStatus) {
      case PostureStatus.safe:
        return const Color(0xFF58CC02); // Yeşil
      case PostureStatus.warning:
        return const Color(0xFFFFC800); // Sarı
      case PostureStatus.danger:
        return const Color(0xFFFF4B4B); // Kırmızı
    }
  }

  // Durum bazlı mesaj (başlık)
  String _getMainMessage() {
    switch (_currentStatus) {
      case PostureStatus.safe:
        return "Harikasın!";
      case PostureStatus.warning:
        return "Dikkat!";
      case PostureStatus.danger:
        return "Eyvah!";
    }
  }

  // Durum bazlı alt mesaj
  String _getSubMessage() {
    switch (_currentStatus) {
      case PostureStatus.safe:
        return "Çelik gibi bir omurga!";
      case PostureStatus.warning:
        return "Koala'nın başı dönüyor...";
      case PostureStatus.danger:
        return "Düşüyorum, beni tut!";
    }
  }

  // NORMALİZASYON: Açıyı 10-85 derece aralığından 0.0-1.0 aralığına map et
  // KRİTİK: Smoothed (filtrelenmiş) açıyı kullan - titrek hareket yok!
  // pitchAngle <= 10° (Yatay/Kötü) -> 0.0 (En Sol)
  // pitchAngle >= 85° (Dik/İyi) -> 1.0 (En Sağ)
  // KRİTİK: .clamp() ile sınırlandırıldı - ASLA dışarı çıkmaz!
  double _getNormalizedPosition() {
    return ((_smoothedAngle - 10.0) / (85.0 - 10.0)).clamp(0.0, 1.0);
  }

  // Orbit rotasyon açısını hesapla (YARIM DAİRE - Radyan)
  // normalizedPos: 0.0 (Sol) -> 1.0 (Sağ)
  // Radyan: π (Sol/180°) -> 0 (Sağ/0°)
  double _getOrbitRotation() {
    double normalizedPos = _getNormalizedPosition();
    
    // 0.0 -> 180° (π radyan), 1.0 -> 0° (0 radyan)
    // Derece cinsinden: (1.0 - normalizedPos) * 180
    return (1.0 - normalizedPos) * 180.0;
  }
  
  // Orbit pozisyonuna göre dinamik renk döndür (Color Lerp)
  // Kırmızı -> Turuncu -> Yeşil geçişi
  Color _getAvatarColor() {
    double normalizedPos = _getNormalizedPosition();
    
    // Kırmızıdan Yeşile smooth geçiş
    return Color.lerp(
      const Color(0xFFFF4B4B), // Kırmızı (Sol - Kötü)
      const Color(0xFF58CC02), // Yeşil (Sağ - İyi)
      normalizedPos, // 0.0-1.0 arası smooth geçiş
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // XP Badge
            _buildXPBadge(),
            
            // Ana İçerik (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Orbit Animasyonu
                    _buildOrbitAnimation(),
                    
                    const SizedBox(height: 16),
                    
                    // Dinamik Mesajlar
                    _buildMessages(),
                    
                    const SizedBox(height: 40),
                    
                    // Ana Karakter (Koala)
                    _buildMainCharacter(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header (Geri butonu + Başlık)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Geri Butonu (Yuvarlak, Beyaz Arkaplan, Siyah İkon)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // Tam yuvarlak
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back, 
                size: 24,
                color: Colors.black87, // Koyu gri/siyah - net görünür
              ),
            ),
          ),
          
          // Başlık
          const Expanded(
            child: Text(
              'POSTURE CHECK',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF374151),
              ),
            ),
          ),
          
          const SizedBox(width: 48), // Dengeleme için
        ],
      ),
    );
  }

  /// XP Badge
  Widget _buildXPBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFC800), size: 24),
          const SizedBox(width: 8),
          const Text(
            '0 XP',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Orbit Animasyonu (TRİGONOMETRİK POZİSYON)
  Widget _buildOrbitAnimation() {
    // Yörünge boyutları
    const double containerWidth = 300;
    const double containerHeight = 150;
    const double radius = 120; // Yörünge yarıçapı (containerWidth * 0.4)
    const double iconSize = 64; // Avatar boyutu
    
    // Merkez noktası (yayın alt merkezi)
    const double centerX = containerWidth / 2;
    const double centerY = containerHeight; // Alt kenarda
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800), // AĞır ve akici hareket
      curve: Curves.easeOutCubic, // Organik fren etkisi
      tween: Tween<double>(begin: 0, end: _getOrbitRotation()),
      builder: (context, rotationDegrees, child) {
        // Dereceyi radyana çevir
        // 180° -> π (sol), 0° -> 0 (sağ)
        double radian = (rotationDegrees * math.pi / 180.0).clamp(0.0, math.pi);
        
        // TRİGONOMETRİK POZİSYON HESAPLAMA
        // x = centerX + radius * cos(radian)
        // y = centerY - radius * sin(radian)
        double x = centerX + (radius * math.cos(radian)) - (iconSize / 2);
        double y = centerY - (radius * math.sin(radian)) - (iconSize / 2);
        
        return SizedBox(
          width: containerWidth,
          height: containerHeight,
          child: Stack(
            clipBehavior: Clip.none, // KRİTİK: Koala keskinliğini engelle
            children: [
              // Orbit Yayı (Yarım Daire) - Progress ile
              CustomPaint(
                size: const Size(containerWidth, containerHeight),
                painter: OrbitPainter(
                  progress: _getNormalizedPosition(), // Koala'nın pozisyonu
                ),
              ),
              
              // Avatar (Pozisyonlu - Sin/Cos ile sabitlenmiş)
              Positioned(
                left: x,
                top: y,
                child: _buildAvatar(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Avatar (Orbit üzerindeki karakter)
  Widget _buildAvatar() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 3),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Float animasyonu için offset
        double floatOffset = math.sin(value * 2 * math.pi) * 5;
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar Circle (Dinamik renkle)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _getAvatarColor().withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/happy_koala.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Badge
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPrimaryColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _currentStatus == PostureStatus.safe ? 'Nice!' : 
                  _currentStatus == PostureStatus.warning ? 'Careful!' : 'Ouch!',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dinamik Mesajlar
  Widget _buildMessages() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: Text(
                  _getMainMessage(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          _getSubMessage(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _getPrimaryColor(),
          ),
        ),
      ],
    );
  }

  /// Ana Karakter (Büyük Koala)
  Widget _buildMainCharacter() {
    return Column(
      children: [
        // Radial gradient background
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                _getPrimaryColor().withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 4),
            tween: Tween<double>(begin: 1, end: 1.05),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Image.asset(
                  'assets/happy_koala.png',
                  width: 180,
                  height: 180,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Durum metni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Text(
            '${_currentAngle.toStringAsFixed(1)}° - ${_currentStatus == PostureStatus.safe ? "Perfect!" : _currentStatus == PostureStatus.warning ? "Watch out!" : "Fix it!"}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Orbit Painter (Yarım Daire) - Dinamik Progress
class OrbitPainter extends CustomPainter {
  final double progress; // 0.0 (sol/kötü) - 1.0 (sağ/iyi)
  
  OrbitPainter({this.progress = 1.0});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 30;

    // 1. ARKAPLAN TRACK (Gri - Tam yarım daire)
    final bgPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Başlangıç: 180° (sol)
      math.pi, // Uzunluk: 180° (yarım daire)
      false,
      bgPaint,
    );

    // 2. AKTİF TRACK (Gradient - Sadece progress kadar)
    // Progress: 0.0 -> Hiç çizme, 1.0 -> Tam yarım daire
    if (progress > 0.0) {
      final gradient = LinearGradient(
        colors: [
          const Color(0xFFFF4B4B), // Kırmızı (sol)
          const Color(0xFFFFC800), // Sarı (orta)
          const Color(0xFF58CC02), // Yeşil (sağ)
        ],
      );

      final gradientPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      // Soldan başlayarak progress kadar çiz
      // StartAngle: π (sol), SweepAngle: progress * π (0-180°)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi, // Başlangıç: 180° (sol)
        progress * math.pi, // Uzunluk: progress * 180°
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress; // Progress değişirse yeniden çiz
  }
}
