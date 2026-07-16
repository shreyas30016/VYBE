import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/gemini_service.dart';
import '../../data/models/clothing_item.dart';
import '../../core/utils/analytics.dart';
import '../../core/router/app_router.dart';
import '../../providers/wardrobe_provider.dart';

enum ScanState {
  idle,
  cameraReady,
  garmentDetected,
  capturing,
  uploading,
  geminiAnalysis,
  parsing,
  saving,
  completed,
  rejected,
  error,
}

enum ScanMode { guide, manual }
enum FlashModeEnum { off, auto, on }

class MagicScanScreen extends ConsumerStatefulWidget {
  const MagicScanScreen({super.key});

  @override
  ConsumerState<MagicScanScreen> createState() => _MagicScanScreenState();
}

class _MagicScanScreenState extends ConsumerState<MagicScanScreen> with TickerProviderStateMixin {
  late AnimationController _laserController;
  late AnimationController _frameController;
  late AnimationController _morphController;
  
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isFrontCamera = false;
  
  ScanState _currentState = ScanState.idle;
  ScanMode _currentMode = ScanMode.manual;
  FlashModeEnum _flashMode = FlashModeEnum.off;
  String _errorMessage = '';
  
  Map<String, dynamic>? _scanResult;
  Uint8List? _imageBytes;
  Timer? _autoDetectTimer;
  
  // Smart Guide Quality Indicators
  bool _isLightingGood = false;
  bool _isCentered = false;
  bool _isDistanceGood = false;
  bool _isStable = false;
  
  final List<String> _revealedKeys = [];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);
    
    _frameController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCamera(_cameras.first);
      } else {
        setState(() => _currentState = ScanState.idle);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() {
        _currentState = ScanState.error;
        _errorMessage = 'Camera access required.';
      });
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
    if (_isFrontCamera) _flashMode = FlashModeEnum.off;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    await _cameraController!.initialize();
    await _applyFlashMode();
    
    if (mounted) {
      setState(() {
        _currentState = ScanState.cameraReady;
      });
      _startAutoDetectSimulation();
    }
  }

  Future<void> _applyFlashMode() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      if (_isFrontCamera) {
        await _cameraController!.setFlashMode(FlashMode.off);
        return;
      }
      
      switch (_flashMode) {
        case FlashModeEnum.off:
          await _cameraController!.setFlashMode(FlashMode.off);
          break;
        case FlashModeEnum.auto:
          await _cameraController!.setFlashMode(FlashMode.auto);
          break;
        case FlashModeEnum.on:
          await _cameraController!.setFlashMode(FlashMode.always);
          break;
      }
    } catch (e) {
      debugPrint('Flash mode not supported on this platform: $e');
    }
  }

  void _cycleFlashMode() {
    if (_isFrontCamera) return;
    setState(() {
      if (_flashMode == FlashModeEnum.off) {
        _flashMode = FlashModeEnum.auto;
      } else if (_flashMode == FlashModeEnum.auto) {
        _flashMode = FlashModeEnum.on;
      } else {
        _flashMode = FlashModeEnum.off;
      }
    });
    _applyFlashMode();
  }

  void _startAutoDetectSimulation() {
    _autoDetectTimer?.cancel();
    if (_currentMode != ScanMode.guide || _currentState != ScanState.cameraReady) return;
    
    setState(() {
      _isLightingGood = false;
      _isCentered = false;
      _isDistanceGood = false;
      _isStable = false;
    });
    
    _autoDetectTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted || _currentState != ScanState.cameraReady || _currentMode != ScanMode.guide) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (!_isLightingGood) {
          _isLightingGood = true;
        } else if (!_isCentered) {
          _isCentered = true;
        } else if (!_isDistanceGood) {
          _isDistanceGood = true;
        } else if (!_isStable) {
          _isStable = true;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _currentState == ScanState.cameraReady && _currentMode == ScanMode.guide) {
              setState(() => _currentState = ScanState.garmentDetected);
              HapticFeedback.lightImpact();
              
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted && _currentState == ScanState.garmentDetected && _currentMode == ScanMode.guide) {
                  _startScanPipeline(ImageSource.camera);
                }
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _autoDetectTimer?.cancel();
    _laserController.dispose();
    _morphController.dispose();
    _frameController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
  
  Future<bool> _onWillPop() async {
    if (_currentState.index > ScanState.cameraReady.index && _currentState.index < ScanState.completed.index) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Discard current scan?', style: TextStyle(color: Colors.white)),
          content: const Text('Your scan is still processing. Do you want to cancel it?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }

  Future<void> _resetToCameraReady() async {
    setState(() {
      _imageBytes = null;
    });
    
    try {
      if (_cameraController?.value.isInitialized == true) {
        if (kIsWeb) {
          final description = _cameraController!.description;
          setState(() => _currentState = ScanState.idle);
          await _cameraController!.dispose();
          await _setupCamera(description);
          return;
        } else {
          _cameraController?.resumePreview();
        }
      }
    } catch (e) {
      debugPrint('Failed to resume preview: $e');
    }
    
    if (mounted) {
      setState(() => _currentState = ScanState.cameraReady);
      _startAutoDetectSimulation();
    }
  }

  Future<void> _startScanPipeline(ImageSource source) async {
    try {
      _autoDetectTimer?.cancel();
      HapticFeedback.mediumImpact();
      
      setState(() {
        _currentState = ScanState.capturing;
        _errorMessage = '';
        _scanResult = null;
        _revealedKeys.clear();
        _imageBytes = null;
      });
      
      XFile? imageFile;
      if (source == ImageSource.camera && _cameraController != null && _cameraController!.value.isInitialized) {
        imageFile = await _cameraController!.takePicture();
      } else {
        imageFile = await ImagePicker().pickImage(source: source);
      }
      
      if (imageFile == null) {
        setState(() => _currentState = ScanState.cameraReady);
        _startAutoDetectSimulation();
        return;
      }
      
      final bytes = await imageFile.readAsBytes();

      Analytics.logEvent('Scan Started');
      
      setState(() {
        _imageBytes = bytes;
        _currentState = ScanState.uploading;
      });
      
      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      
      setState(() => _currentState = ScanState.geminiAnalysis);
      
      final geminiService = ref.read(geminiServiceProvider);
      
      final result = await geminiService.analyzeClothingImage(imageFile).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('AI analysis timed out'),
      );
      
      if (!mounted) return;
      setState(() => _currentState = ScanState.parsing);
      
      // Validation Logic
      final category = result?['category'];
      final confidence = result?['confidence']?.toDouble() ?? 0.0;
      
      if (category == null || confidence < 0.85) {
        setState(() {
          _currentState = ScanState.rejected;
        });
        HapticFeedback.heavyImpact();
        return;
      }
      
      // Simulate parsing delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        _scanResult = result;
        _currentState = ScanState.saving;
      });
      
      // Save to wardrobe
      await _saveToWardrobe(imageFile, result);
      
      if (!mounted) return;
      
      setState(() => _currentState = ScanState.completed);
      HapticFeedback.lightImpact();
      Analytics.logEvent('Scan Completed', parameters: {'category': category});
      
      _startDataDrivenReveal(result ?? {});
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentState = ScanState.error;
        _errorMessage = e is TimeoutException 
            ? 'Analysis failed. Timeout.' 
            : 'No clothing found. $e';
      });
    }
  }
  
  Future<void> _saveToWardrobe(XFile imageFile, Map<String, dynamic>? result) async {
    String finalImageUrl = imageFile.path;
    
    // On Web, blob: URLs expire on refresh. Convert to Base64 for permanent local storage.
    if (kIsWeb) {
      try {
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        finalImageUrl = 'data:image/jpeg;base64,$base64String';
      } catch (e) {
        debugPrint('Failed to convert image to base64: $e');
      }
    }

    final newItem = ClothingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local_user', 
      imageUrl: finalImageUrl,
      category: result?['category'] ?? 'Unknown',
      subtype: result?['subtype'] ?? '',
      color: result?['color'] ?? '',
      material: result?['material'] ?? '',
      pattern: result?['pattern'] ?? '',
      season: result?['season'] ?? '',
      confidence: result?['confidence']?.toDouble() ?? 1.0,
      wearCount: 0,
      dateAdded: DateTime.now(),
      isFavorite: false,
    );
    
    await ref.read(wardrobeRepositoryProvider).addItem(newItem);
  }

  Future<void> _startDataDrivenReveal(Map<String, dynamic> data) async {
    final keysToReveal = ['category', 'color', 'material', 'pattern', 'brand', 'season', 'confidence'];
    
    for (final key in keysToReveal) {
      if (data.containsKey(key) && data[key] != null && data[key].toString().isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted || _currentState != ScanState.completed) return;
        setState(() {
          _revealedKeys.add(key);
        });
      }
    }
    
    // Auto close toast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to your wardrobe'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.black,
            onPressed: () {
              if (mounted) {
                context.go('/closet');
              } else {
                rootNavigatorKey.currentContext?.go('/closet');
              }
            },
          ),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted && _currentState == ScanState.completed) {
        context.pop();
      }
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final itemsAsync = ref.watch(wardrobeItemsProvider);
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Scans', style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: itemsAsync.when(
                          data: (items) {
                            if (items.isEmpty) return const Center(child: Text('No history yet.', style: TextStyle(color: Colors.white70)));
                            final recent = items.reversed.take(20).toList();
                            return ListView.builder(
                              controller: scrollController,
                              itemCount: recent.length,
                              itemBuilder: (context, index) {
                                final item = recent[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 48, height: 48,
                                        child: _buildItemThumbnail(item.imageUrl),
                                      ),
                                    ),
                                    title: Text('${item.color} ${item.category}', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                                    subtitle: Text('Confidence: ${(item.confidence * 100).toInt()}%', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                    trailing: IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        ref.read(wardrobeRepositoryProvider).deleteItem(item.id);
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildItemThumbnail(String url) {
    if (url.startsWith('blob:')) return Image.network(url, fit: BoxFit.cover);
    if (url.startsWith('http')) return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    return Image.file(File(url), fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image, color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera Background
              SizedBox.expand(
                child: _buildCameraBackground(),
              ),
            
            // Frame Overlay
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  child: _buildScanFrame(),
                ),
              ),
            ),
            
            // Guide Overlays
            if (_currentMode == ScanMode.guide && _currentState == ScanState.cameraReady)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Center the clothing item within the frame',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.margin),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (await _onWillPop()) {
                            if (context.mounted) context.pop();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24),
                        ),
                      ),
                      if (!_isFrontCamera)
                        GestureDetector(
                          onTap: _cycleFlashMode,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _flashMode == FlashModeEnum.on ? LucideIcons.zap : 
                              _flashMode == FlashModeEnum.auto ? LucideIcons.zap : LucideIcons.zapOff,
                              color: _flashMode != FlashModeEnum.off ? AppColors.primary : Colors.white, 
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Error overlay
            if (_currentState == ScanState.error)
              Positioned(
                top: 140,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _resetToCameraReady,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
              ),
              
            // Live Quality Indicators
            if (_currentMode == ScanMode.guide && _currentState == ScanState.cameraReady)
              Positioned(
                bottom: 140 + MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: _buildQualityIndicators(),
              ),
            
            // Status Card
            if (_currentState.index >= ScanState.capturing.index || _currentState == ScanState.completed)
              Positioned(
                bottom: 120 + MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: _buildProgressCard().animate().slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutCubic, duration: 400.ms),
              ),

            // Bottom Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCameraBackground() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    
    if (_currentState != ScanState.idle && _cameraController != null && _cameraController!.value.isInitialized) {
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
    
    return Container(color: const Color(0xFF111111));
  }

  Widget _buildScanFrame() {
    final isProcessing = _currentState.index >= ScanState.capturing.index;
    final isDetected = _currentState == ScanState.garmentDetected || isProcessing;
    final isComplete = _currentState == ScanState.completed;
    final isRejected = _currentState == ScanState.rejected;
    
    Color frameColor = Colors.white.withValues(alpha: 0.5);
    if (isDetected && !isRejected) frameColor = AppColors.success;
    
    if (isComplete || isRejected) return const SizedBox.shrink();
    
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _morphController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _DynamicGarmentPainter(
                color: frameColor,
                isDetected: isDetected,
                morphValue: _morphController.value,
              ),
            );
          },
        ),
        if (_currentState == ScanState.uploading || _currentState == ScanState.geminiAnalysis)
          AnimatedBuilder(
            animation: _laserController,
            builder: (context, child) {
              return Positioned(
                top: _laserController.value * (MediaQuery.of(context).size.height * 0.5),
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 4)
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    final isProcessing = _currentState.index >= ScanState.capturing.index && _currentState != ScanState.completed;
    final showProgress = isProcessing || _currentState == ScanState.completed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8), Colors.black],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: showProgress ? null : () => _startScanPipeline(ImageSource.gallery),
            child: Opacity(
              opacity: showProgress ? 0.3 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.image, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text('Gallery', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
          
          // Central Button
          if (_currentMode == ScanMode.manual)
            GestureDetector(
              onTap: (isProcessing || _currentState == ScanState.completed) ? null : () => _startScanPipeline(ImageSource.camera),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isProcessing ? 64 : 80,
                height: isProcessing ? 64 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  color: _currentState == ScanState.completed ? AppColors.success : (isProcessing ? Colors.transparent : AppColors.primary.withValues(alpha: 0.8)),
                ),
                child: Center(
                  child: _currentState == ScanState.completed
                      ? const Icon(LucideIcons.check, color: Colors.black, size: 32).animate().scale(delay: 200.ms)
                      : isProcessing
                          ? const CircularProgressIndicator(color: AppColors.primary)
                          : const Icon(LucideIcons.sparkles, color: Colors.black, size: 32),
                ),
              ),
            )
          else
            const SizedBox(width: 80, height: 80),
          
          GestureDetector(
            onTap: showProgress ? null : _showHistorySheet,
            child: Opacity(
              opacity: showProgress ? 0.3 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.history, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text('History', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQualityIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildQualityPip('Lighting', _isLightingGood),
        _buildQualityPip('Centered', _isCentered),
        _buildQualityPip('Distance', _isDistanceGood),
        _buildQualityPip('Steady', _isStable),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildQualityPip(String label, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGood ? AppColors.success : Colors.black54,
              border: Border.all(color: isGood ? AppColors.success : Colors.white24, width: 2),
            ),
            child: isGood ? const Icon(LucideIcons.check, color: Colors.black, size: 14) : const SizedBox(),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: isGood ? Colors.white : Colors.white54, fontSize: 10, fontWeight: isGood ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    String statusText = '';
    int progressSteps = 0;
    
    switch (_currentState) {
      case ScanState.capturing:
      case ScanState.uploading:
        statusText = 'Uploading image...'; progressSteps = 1; break;
      case ScanState.geminiAnalysis:
        statusText = 'Analyzing garment...'; progressSteps = 2; break;
      case ScanState.parsing:
        statusText = 'Extracting attributes...'; progressSteps = 3; break;
      case ScanState.saving:
        statusText = 'Saving wardrobe...'; progressSteps = 4; break;
      case ScanState.completed:
        statusText = 'Scan complete!'; progressSteps = 5; break;
      case ScanState.rejected:
        statusText = 'No clothing detected'; progressSteps = 0; break;
      default: break;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (_currentState == ScanState.completed && _scanResult != null)
                Text(
                  '${((_scanResult!['confidence'] ?? 1.0) * 100).toInt()}%',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ).animate().fadeIn(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final active = index < progressSteps;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          if (_currentState == ScanState.completed) ...[
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                spacing: 24,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _buildAttributeNode('Category', _scanResult?['category'], LucideIcons.shirt, 'category'),
                  _buildAttributeNode('Color', _scanResult?['color'], LucideIcons.palette, 'color'),
                  _buildAttributeNode('Fabric', _scanResult?['material'], LucideIcons.layers, 'material'),
                  _buildAttributeNode('Pattern', _scanResult?['pattern'], LucideIcons.grid, 'pattern'),
                  _buildAttributeNode('Brand', _scanResult?['brand'], LucideIcons.tag, 'brand'),
                ],
              ),
            ),
          ],
          if (_currentState == ScanState.rejected) ...[
            const SizedBox(height: 16),
            const Text(
              'Point the camera at a clothing item.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetToCameraReady,
                icon: const Icon(LucideIcons.refreshCcw),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributeNode(String label, dynamic value, IconData icon, String key) {
    final isRevealed = _revealedKeys.contains(key);
    if (!isRevealed) return const SizedBox.shrink();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value?.toString() ?? 'N/A', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    ).animate().slideY(begin: 0.2, end: 0, curve: Curves.easeOut).fadeIn(duration: 400.ms);
  }
}

class _DynamicGarmentPainter extends CustomPainter {
  final Color color;
  final bool isDetected;
  final double morphValue;

  _DynamicGarmentPainter({required this.color, required this.isDetected, required this.morphValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isDetected ? 4 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isDetected) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    }

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    if (!isDetected) {
      // Idle state: subtle breathing rectangle with rounded corners
      final breath = math.sin(morphValue * math.pi * 2) * 10;
      final rect = Rect.fromLTRB(20 - breath, 20 - breath, w - 20 + breath, h - 20 + breath);
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32)));
      canvas.drawPath(path, paint);
      return;
    }
    
    // Detected state: Morphing organic shape simulating a garment (e.g. a shirt)
    final o1 = math.sin(morphValue * math.pi * 2) * 15;
    final o2 = math.cos(morphValue * math.pi * 2) * 15;
    
    path.moveTo(w * 0.35 + o1, h * 0.15 + o2);
    path.quadraticBezierTo(w * 0.5, h * 0.2 + o1, w * 0.65 - o1, h * 0.15 + o2);
    path.quadraticBezierTo(w * 0.85 + o2, h * 0.18 - o1, w * 0.9 - o2, h * 0.3 + o1);
    path.lineTo(w * 0.95 + o1, h * 0.45 + o2);
    path.lineTo(w * 0.8 + o2, h * 0.5 - o1);
    path.quadraticBezierTo(w * 0.75 - o1, h * 0.7 + o2, w * 0.75 + o2, h * 0.85 - o1);
    path.quadraticBezierTo(w * 0.5, h * 0.88 + o1, w * 0.25 - o2, h * 0.85 - o1);
    path.quadraticBezierTo(w * 0.25 + o1, h * 0.7 + o2, w * 0.2 - o2, h * 0.5 - o1);
    path.lineTo(w * 0.05 - o1, h * 0.45 + o2);
    path.lineTo(w * 0.1 + o2, h * 0.3 + o1);
    path.quadraticBezierTo(w * 0.15 - o1, h * 0.18 - o1, w * 0.35 + o1, h * 0.15 + o2);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DynamicGarmentPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isDetected != isDetected || oldDelegate.morphValue != morphValue;
  }
}
