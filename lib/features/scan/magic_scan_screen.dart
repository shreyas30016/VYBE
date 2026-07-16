import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/gemini_service.dart';
import '../../data/models/clothing_item.dart';
import '../../core/utils/analytics.dart';
import '../../providers/wardrobe_provider.dart';
import '../../core/components/glass_container.dart';

enum ScanState {
  idle,
  cameraReady,
  capturing,
  geminiParsing,
  saving,
  completed,
  error,
}

class MagicScanScreen extends ConsumerStatefulWidget {
  const MagicScanScreen({super.key});

  @override
  ConsumerState<MagicScanScreen> createState() => _MagicScanScreenState();
}

class _MagicScanScreenState extends ConsumerState<MagicScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  CameraController? _cameraController;
  
  ScanState _currentState = ScanState.idle;
  String _errorMessage = '';
  
  Map<String, dynamic>? _scanResult;
  XFile? _imageFile;
  
  // For the data-driven progressive reveal
  final List<String> _revealedKeys = [];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _currentState = ScanState.cameraReady;
          });
        }
      } else {
        setState(() => _currentState = ScanState.idle);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() => _currentState = ScanState.idle);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<void> _startDataDrivenReveal(Map<String, dynamic> data) async {
    final keysToReveal = [
      'category', 
      'color', 
      'material', 
      'subtype', 
      'season', 
      'confidence'
    ];
    
    for (final key in keysToReveal) {
      if (data.containsKey(key) && data[key] != null && data[key].toString().isNotEmpty) {
        // Wait 400ms before revealing the next parsed attribute
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted || _currentState != ScanState.completed) return;
        setState(() {
          _revealedKeys.add(key);
        });
      }
    }
  }

  Future<void> _startScan(ImageSource source) async {
    try {
      XFile? imageFile;
      
      setState(() {
        _currentState = ScanState.capturing;
        _errorMessage = '';
        _scanResult = null;
        _revealedKeys.clear();
        _imageFile = null;
      });
      
      // Use CameraController if initialized
      if (source == ImageSource.camera && _cameraController != null && _cameraController!.value.isInitialized) {
        imageFile = await _cameraController!.takePicture();
      } else {
        // Fallback to ImagePicker (works perfectly on Web and Native)
        imageFile = await ImagePicker().pickImage(source: source);
      }
      
      if (imageFile != null) {
        Analytics.logEvent('Scan Started');
        setState(() {
          _imageFile = imageFile;
          _currentState = ScanState.geminiParsing;
        });
        
        final geminiService = ref.read(geminiServiceProvider);
        
        // Apply timeout to avoid indefinite hanging
        final result = await geminiService.analyzeClothingImage(imageFile).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('AI analysis timed out'),
        );
        
        if (mounted) {
          setState(() {
            _scanResult = result;
            _currentState = ScanState.completed;
          });
          
          Analytics.logEvent('Scan Completed', parameters: {'category': result?['category'] ?? 'unknown'});
          
          // Trigger the sequential reveal driven by the actual parsed data
          _startDataDrivenReveal(result ?? {});
        }
      } else {
        // User cancelled picker
        setState(() {
          _currentState = (_cameraController?.value.isInitialized == true) 
              ? ScanState.cameraReady 
              : ScanState.idle;
        });
      }
    } catch (e) {
      setState(() {
        _currentState = ScanState.error;
        _errorMessage = e is TimeoutException 
            ? 'AI analysis took too long. Please try again.' 
            : 'Failed to process image: $e';
      });
    }
  }
  
  Future<void> _saveToWardrobe() async {
    if (_scanResult == null || _imageFile == null) return;
    
    setState(() {
      _currentState = ScanState.saving;
    });
    
    try {
      final newItem = ClothingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'local_user', 
        imageUrl: _imageFile!.path,
        category: _scanResult!['category'] ?? 'Unknown',
        subtype: _scanResult!['subtype'] ?? '',
        color: _scanResult!['color'] ?? '',
        material: _scanResult!['material'] ?? '',
        pattern: _scanResult!['pattern'] ?? '',
        season: _scanResult!['season'] ?? '',
        confidence: _scanResult!['confidence']?.toDouble() ?? 1.0,
        wearCount: 0,
        dateAdded: DateTime.now(),
        isFavorite: false,
      );
      
      // Repository handles stream emission, naturally propagating to the UI.
      await ref.read(wardrobeRepositoryProvider).addItem(newItem);
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _currentState = ScanState.error;
        _errorMessage = 'Failed to save to wardrobe: $e';
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startScan(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startScan(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBackground() {
    if (_imageFile != null) {
      if (kIsWeb) {
        return Image.network(_imageFile!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
      }
    }
    
    if (_currentState == ScanState.cameraReady && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    
    return Container(
      color: const Color(0xFF111111),
    );
  }
  
  String get _statusText {
    switch (_currentState) {
      case ScanState.idle:
      case ScanState.cameraReady:
        return 'Ready to Scan';
      case ScanState.capturing:
        return 'Capturing Image...';
      case ScanState.geminiParsing:
        return 'AI Analyzing...';
      case ScanState.saving:
        return 'Saving to Wardrobe...';
      case ScanState.completed:
        return 'Analysis Complete';
      case ScanState.error:
        return 'Scan Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = _currentState == ScanState.capturing || 
                         _currentState == ScanState.geminiParsing || 
                         _currentState == ScanState.saving;
                         
    final showLaser = _currentState == ScanState.geminiParsing;
    
    return Scaffold(
      backgroundColor: Colors.black, // Dark background mimicking camera
      body: Stack(
        children: [
          // Simulated Camera Background
          Positioned.fill(
            child: GestureDetector(
              onTap: isProcessing ? null : () {
                if (_currentState == ScanState.cameraReady) {
                  _startScan(ImageSource.camera);
                } else {
                  _showImageSourceOptions();
                }
              },
              child: _buildCameraBackground(),
            ),
          ),
          
          // Grid Overlay
          if (_imageFile == null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),
            
          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                    ),
                  ),
                  GestureDetector(
                    onTap: isProcessing ? null : _showImageSourceOptions,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isProcessing ? Colors.black26 : Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: isProcessing 
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.camera, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Targeting Brackets
          Center(
            child: SizedBox(
              width: 280,
              height: 380,
              child: Stack(
                children: [
                  _buildBracket(Alignment.topLeft),
                  _buildBracket(Alignment.topRight),
                  _buildBracket(Alignment.bottomLeft),
                  _buildBracket(Alignment.bottomRight),
                  

                  
                  // Scanning Laser
                  if (showLaser)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return Positioned(
                          top: _laserController.value * 380,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          
          // Shutter Button
          if (_currentState == ScanState.idle || _currentState == ScanState.cameraReady)
            Positioned(
              bottom: 180, // Positioned above the bottom sheet
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentState == ScanState.cameraReady) {
                      _startScan(ImageSource.camera);
                    } else {
                      _showImageSourceOptions();
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Bottom Sheet (Scanning progress)
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              child: GlassContainer(
                borderRadius: AppSpacing.radiusCard,
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 32,
                  bottom: 48,
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusText,
                    style: AppTypography.headingLarge.copyWith(
                      color: _currentState == ScanState.error ? AppColors.error : AppColors.textPrimary
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_currentState == ScanState.idle || _currentState == ScanState.cameraReady)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'Point your camera at a clothing item to analyze its properties automatically.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    
                  if (_currentState == ScanState.error) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        _errorMessage,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _showImageSourceOptions,
                            child: const Text('Try Gallery'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (_currentState == ScanState.error && _cameraController?.value.isInitialized == true) {
                                _startScan(ImageSource.camera);
                              } else {
                                _showImageSourceOptions();
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                    
                  if (_currentState == ScanState.geminiParsing || _currentState == ScanState.completed || _currentState == ScanState.saving) ...[
                    // Only build rows for keys that actually exist in the result
                    if (_scanResult != null)
                      ...['category', 'color', 'material', 'subtype', 'season']
                          .where((key) => _scanResult!.containsKey(key))
                          .map((key) {
                        String label = key[0].toUpperCase() + key.substring(1);
                        return _buildDataDrivenRow(label, _scanResult![key], key);
                      }),
                      
                    // Show a generic analyzing spinner while waiting for gemini
                    if (_currentState == ScanState.geminiParsing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: SizedBox(
                                width: 16, 
                                height: 16, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              'Extracting data...',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                  ],
                  
                  if (_currentState == ScanState.completed || _currentState == ScanState.saving) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _currentState == ScanState.saving ? null : _saveToWardrobe,
                        child: _currentState == ScanState.saving 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                            )
                          : const Text('ADD TO WARDROBE'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracket(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 32,
        height: 32,
        child: CustomPaint(
          painter: _BracketPainter(alignment: alignment, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDataDrivenRow(String label, dynamic value, String key) {
    final isRevealed = _revealedKeys.contains(key);
    final displayValue = value?.toString() ?? '';
    
    // Only render if it's been revealed by the sequential timer
    if (!isRevealed) return const SizedBox.shrink();
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    border: Border.all(
                      color: AppColors.success,
                      width: 2,
                    ),
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.black, size: 16),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  displayValue.toUpperCase(),
                  style: AppTypography.captionBold.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;

  _BracketPainter({required this.alignment, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (alignment == Alignment.topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
