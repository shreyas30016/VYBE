import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
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
  final ScanMode _currentMode = ScanMode.manual;
  FlashModeEnum _flashMode = FlashModeEnum.off;
  String _errorMessage = '';
  
  double _currentZoomLevel = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _baseZoomLevel = 1.0;
  
  Uint8List? _imageBytes;
  Timer? _autoDetectTimer;
  
  bool _isBatchMode = false;
  List<XFile> _batchFiles = [];
  List<Map<String, dynamic>> _batchResults = [];
  int _batchProcessedCount = 0;
  
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
    
    try {
      _minAvailableZoom = await _cameraController!.getMinZoomLevel();
      _maxAvailableZoom = await _cameraController!.getMaxZoomLevel();
      _currentZoomLevel = _minAvailableZoom;
      await _cameraController!.setZoomLevel(_currentZoomLevel);
    } catch (e) {
      debugPrint('Zoom not supported: $e');
    }
    
    await _applyFlashMode();
    
    if (mounted) {
      setState(() {
        _currentState = ScanState.cameraReady;
      });
      _startAutoDetectSimulation();
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoomLevel = _currentZoomLevel;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    _currentZoomLevel = (_baseZoomLevel * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    
    try {
      await _cameraController!.setZoomLevel(_currentZoomLevel);
    } catch (e) {
      debugPrint('Error setting zoom: $e');
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

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    
    final currentIndex = _cameras.indexWhere((c) => c.lensDirection == _cameraController!.description.lensDirection);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    
    setState(() => _currentState = ScanState.idle);
    await _cameraController?.dispose();
    await _setupCamera(_cameras[nextIndex]);
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
        _errorMessage = '';
        _imageBytes = null;
        _isBatchMode = false;
        _batchFiles.clear();
        _batchResults.clear();
        _batchProcessedCount = 0;
      });
      
      if (source == ImageSource.gallery) {
        final List<XFile> images = await ImagePicker().pickMultiImage(limit: 10);
        if (images.isEmpty) {
          setState(() => _currentState = ScanState.cameraReady);
          _startAutoDetectSimulation();
          return;
        }
        
        setState(() {
          _isBatchMode = true;
          _batchFiles = images;
          _currentState = ScanState.uploading;
        });
        
        Analytics.logEvent('Batch Scan Started', parameters: {'count': images.length});
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        
        setState(() => _currentState = ScanState.geminiAnalysis);
        
        final geminiService = ref.read(geminiServiceProvider);
        final results = await geminiService.analyzeClothingImagesBatch(images).timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw TimeoutException('AI batch analysis timed out'),
        );
        
        if (!mounted) return;
        
        if (results == null || results.isEmpty) {
          throw Exception('Batch analysis returned null');
        }
        
        setState(() {
          _currentState = ScanState.saving;
          _batchResults = results;
        });
        
        for (int i = 0; i < images.length; i++) {
          if (i >= results.length) break;
          final result = results[i];
          final category = result['category'];
          final confidence = result['confidence']?.toDouble() ?? 0.0;
          if (category != null && confidence >= 0.85) {
            await _saveToWardrobe(images[i], result);
            setState(() {
              _batchProcessedCount++;
            });
          }
        }
        
        if (mounted) {
          setState(() => _currentState = ScanState.completed);
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $_batchProcessedCount items to wardrobe!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1500),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) context.pop();
        }
        return;
      }
      
      setState(() {
        _currentState = ScanState.capturing;
      });
      
      XFile? imageFile;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        imageFile = await _cameraController!.takePicture();
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
        _isBatchMode = true;
        _batchFiles = [imageFile!];
        _batchProcessedCount = 0;
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
          _isBatchMode = false;
          _currentState = ScanState.rejected;
        });
        HapticFeedback.heavyImpact();
        return;
      }
      
      // Simulate parsing delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        _currentState = ScanState.saving;
      });
      
      // Save to wardrobe
      await _saveToWardrobe(imageFile, result);
      
      if (!mounted) return;
      
      setState(() {
        _batchProcessedCount = 1;
        _currentState = ScanState.completed;
      });
      HapticFeedback.lightImpact();
      Analytics.logEvent('Scan Completed', parameters: {'category': category});
      
      _startDataDrivenReveal(result ?? {});
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBatchMode = false;
        _currentState = ScanState.error;
        if (e is RateLimitException || e.toString().contains('RateLimitException')) {
          _errorMessage = 'API Rate Limit Exceeded. Please try again in 30 seconds.';
        } else {
          _errorMessage = e is TimeoutException 
              ? 'Analysis failed. Timeout.' 
              : 'Error: $e';
        }
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
                child: GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  child: _buildCameraBackground(),
                ),
              ),
              
              if (_isBatchMode && _currentState != ScanState.rejected && _currentState != ScanState.error && _currentState.index >= ScanState.uploading.index)
                Positioned.fill(
                  child: _buildBatchLoadingScreen(),
                ),
              
              if (!_isBatchMode)
                Positioned.fill(child: _buildScanFrame()),
              
              // Guide Overlays
            if (!_isBatchMode && _currentMode == ScanMode.guide && _currentState == ScanState.cameraReady)
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
                      Row(
                        children: [
                          if (_cameras.length > 1)
                            GestureDetector(
                              onTap: _flipCamera,
                              child: Container(
                                width: 48,
                                height: 48,
                                margin: EdgeInsets.only(right: _isFrontCamera ? 0 : 12),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
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
            


            // Bottom Controls
            if (!_isBatchMode || _currentState == ScanState.idle || _currentState == ScanState.cameraReady)
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

  Widget _buildBatchLoadingScreen() {
    return Stack(
      children: [
        // Blur Background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        // Cards and Loading text
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading Text Top
                const Text(
                  'SCANNING FITS...',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
                const SizedBox(height: 8),
                const Text(
                  "Hang tight, your closet's getting an upgrade ✨",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                
                // 3 Cards Stack
                SizedBox(
                  height: 320,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Left Card
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.1,
                        child: Transform.rotate(
                          angle: -0.2, // ~ -11 degrees
                          child: _buildBatchCard(0, scale: 0.85),
                        ),
                      ),
                      // Right Card
                      Positioned(
                        right: MediaQuery.of(context).size.width * 0.1,
                        child: Transform.rotate(
                          angle: 0.2, // ~ 11 degrees
                          child: _buildBatchCard(2, scale: 0.85),
                        ),
                      ),
                      // Center Card
                      Positioned(
                        child: _buildBatchCard(1, scale: 1.0, isCenter: true),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                // Gen-Z loading phrases
                const Text(
                  'outfit gods',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'fetching images 😎',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'good fits loading... stay stylish 💚',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 24),
                
                // Progress Bar
                if (_currentState == ScanState.saving || _currentState == ScanState.completed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _batchFiles.isEmpty ? 0 : _batchProcessedCount / _batchFiles.length,
                          backgroundColor: Colors.white12,
                          color: AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_batchProcessedCount / math.max(1, _batchFiles.length) * 100).toInt()}%',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(int index, {double scale = 1.0, bool isCenter = false}) {
    String? imagePath;
    if (_batchFiles.isNotEmpty) {
      imagePath = _batchFiles[index % _batchFiles.length].path;
    }
    
    final bool isApproved = _currentState == ScanState.saving || _currentState == ScanState.completed;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 180,
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCenter ? AppColors.primary : Colors.white24,
            width: isCenter ? 2 : 1,
          ),
          boxShadow: [
            if (isCenter) BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null)
                _buildItemThumbnail(imagePath),
              if (imagePath == null)
                const Center(child: Icon(LucideIcons.image, color: Colors.white24, size: 40)),
                
              // Overlay gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              
              // Approved Badge
              if (isApproved)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check, color: Colors.black, size: 12),
                      ),
                      const SizedBox(width: 6),
                      const Text('APPROVED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
              // Scanned & Approved Bottom Text
              if (isApproved)
                const Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 14),
                        SizedBox(width: 4),
                        Text('SCANNED & APPROVED', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
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
            width: _cameraController!.value.previewSize?.width ?? 1,
            height: _cameraController!.value.previewSize?.height ?? 1,
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
