import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xrinet/core/resources/color_manager.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/selected_byte.dart';
import 'package:xrinet/presentation/pages/profile/create_post_page.dart';
import 'package:xrinet/presentation/pages/story/create_story.dart';

class CreateGalleryPage extends StatefulWidget {
  const CreateGalleryPage({super.key});

  @override
  State<CreateGalleryPage> createState() => _CreateGalleryPageState();
}

class _CreateGalleryPageState extends State<CreateGalleryPage> {
  static const String _modePreferenceKey = 'lastCreateMode';

  final ImagePicker _picker = ImagePicker();

  final List<AssetEntity> _assets = [];
  final List<AssetEntity> _selectedAssets = [];
  final List<SelectedByte> _cameraFiles = [];

  AssetEntity? _previewAsset;
  SelectedByte? _previewCameraFile;

  bool _loading = true;
  bool _hasPermission = false;
  bool _multiple = false;

  int _selectedMode = 0;

  final List<String> _modes = [
    'Post',
    'Story',
    'Reels',
    'Live',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
    _loadGallery();
  }

  // Load previously selected creation mode.
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getInt(_modePreferenceKey) ?? 0;

      if (!mounted) return;

      setState(() {
        _selectedMode = savedMode >= 0 && savedMode < _modes.length
            ? savedMode
            : 0;
      });
    } catch (e) {
      debugPrint('MODE LOAD ERROR: $e');
    }
  }

  // Save selected creation mode.
  Future<void> _saveSelectedMode(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_modePreferenceKey, index);
    } catch (e) {
      debugPrint('MODE SAVE ERROR: $e');
    }
  }

  // Load gallery assets.
  Future<void> _loadGallery() async {
    try {
      final permission =
          await PhotoManager.requestPermissionExtend();

      if (!mounted) return;

      if (!permission.hasAccess) {
        setState(() {
          _hasPermission = false;
          _loading = false;
        });
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.common,
      );

      if (paths.isEmpty) {
        if (!mounted) return;

        setState(() {
          _hasPermission = true;
          _loading = false;
        });
        return;
      }

      final assets = await paths.first.getAssetListPaged(
        page: 0,
        size: 100,
      );

      if (!mounted) return;

      setState(() {
        _assets.addAll(assets);
        _hasPermission = true;
        _loading = false;

        if (assets.isNotEmpty) {
          _previewAsset = assets.first;
          _selectedAssets.add(assets.first);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Gallery load failed: $e');
    }
  }

  // Open device camera.
  Future<void> _openCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();

      final selected = SelectedByte(
        isThatImage: true,
        selectedByte: bytes,
        selectedFile: file,
      );

      if (!mounted) return;

      if (!_multiple) {
        _selectedAssets.clear();
        _cameraFiles.clear();
      }

      if (_selectedAssets.length + _cameraFiles.length >= 10) {
        _showMessage('Maximum 10 items allowed');
        return;
      }

      setState(() {
        _cameraFiles.add(selected);
        _previewCameraFile = selected;
        _previewAsset = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Camera error: $e');
    }
  }

  // Select an asset from gallery.
  void _selectAsset(AssetEntity asset) {
    setState(() {
      _previewAsset = asset;
      _previewCameraFile = null;

      final index = _selectedAssets.indexWhere(
        (item) => item.id == asset.id,
      );

      if (_multiple) {
        if (index != -1) {
          _selectedAssets.removeAt(index);
        } else if (_selectedAssets.length + _cameraFiles.length < 10) {
          _selectedAssets.add(asset);
        } else {
          _showMessage('Maximum 10 items allowed');
        }
      } else {
        _selectedAssets
          ..clear()
          ..add(asset);

        _cameraFiles.clear();
      }
    });
  }

  // Toggle multiple selection.
  void _toggleMultiple() {
    setState(() {
      _multiple = !_multiple;

      if (!_multiple) {
        if (_previewAsset != null) {
          _selectedAssets
            ..clear()
            ..add(_previewAsset!);

          _cameraFiles.clear();
        } else if (_previewCameraFile != null) {
          _cameraFiles
            ..clear()
            ..add(_previewCameraFile!);

          _selectedAssets.clear();
        }
      }
    });
  }

  // Convert selected gallery assets into SelectedByte.
  Future<List<SelectedByte>> _getSelectedFiles() async {
    final List<SelectedByte> result = [];

    for (final asset in _selectedAssets) {
      final file = await asset.file;

      if (file == null) continue;

      final bytes = await file.readAsBytes();

      result.add(
        SelectedByte(
          isThatImage: asset.type == AssetType.image,
          selectedByte: bytes,
          selectedFile: file,
        ),
      );
    }

    result.addAll(_cameraFiles);

    return result;
  }

  // Continue to selected creation mode.
  Future<void> _continue() async {
    if (_selectedAssets.isEmpty && _cameraFiles.isEmpty) {
      _showMessage('Please select media first');
      return;
    }

    if (_selectedMode == 3) {
      _showMessage('Live is coming soon');
      return;
    }

    // Capture Navigator before async operations.
    final navigator = Navigator.of(context);

    try {
      final files = await _getSelectedFiles();

      if (!mounted || files.isEmpty) return;

      // Reels requires exactly one video.
      if (_selectedMode == 2) {
        if (files.length != 1 || files.first.isThatImage) {
          _showMessage('Select one video for Reels');
          return;
        }
      }

      double aspectRatio = 1;

      if (_selectedAssets.isNotEmpty) {
        final asset = _selectedAssets.first;

        if (asset.height > 0) {
          aspectRatio = asset.width / asset.height;
        }
      } else if (_cameraFiles.isNotEmpty) {
        final file = _cameraFiles.first.selectedFile;

        if (!await file.exists()) return;
        if (!mounted) return;
      }

      final details = SelectedImagesDetails(
        selectedFiles: files,
        aspectRatio: aspectRatio,
        multiSelectionMode: files.length > 1,
      );

      if (!mounted) return;

      if (_selectedMode == 0 || _selectedMode == 2) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => CreatePostPage(
              selectedFilesDetails: details,
            ),
          ),
        );
      } else if (_selectedMode == 1) {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => CreateStoryPage(
              storiesDetails: details,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not open creation page: $e');
    }
  }

  // Show message.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).focusColor,
        title: Text(
          'New ${_modes[_selectedMode]}',
          style: TextStyle(
            color: Theme.of(context).focusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _continue,
            child: const Text(
              'Next',
              style: TextStyle(
                color: ColorManager.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPreview(),
                ),
                _buildGalleryHeader(),
                Expanded(
                  flex: 4,
                  child: _buildGalleryGrid(),
                ),
              ],
            ),
          ),
          _buildModeSelector(),
        ],
      ),
    );
  }

  // Selected media preview.
  Widget _buildPreview() {
    if (_previewCameraFile != null) {
      return SizedBox(
        width: double.infinity,
        child: Image.file(
          _previewCameraFile!.selectedFile,
          fit: BoxFit.contain,
        ),
      );
    }

    if (_previewAsset != null) {
      return _assetPreview(_previewAsset!);
    }

    return Center(
      child: Icon(
        Icons.photo_library_outlined,
        size: 60,
        color: Theme.of(context).focusColor,
      ),
    );
  }

  // Gallery asset preview.
  Widget _assetPreview(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(1000, 1000),
      ),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
            ),
            if (asset.type == AssetType.video)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 55,
                ),
              ),
          ],
        );
      },
    );
  }

  // Gallery header.
  Widget _buildGalleryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          Text(
            'Recent',
            style: TextStyle(
              color: Theme.of(context).focusColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _toggleMultiple,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).focusColor.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _multiple
                        ? Icons.check_box
                        : Icons.library_add_check_outlined,
                    size: 17,
                    color: Theme.of(context).focusColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Select Multiple',
                    style: TextStyle(
                      color: Theme.of(context).focusColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gallery grid.
  Widget _buildGalleryGrid() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gallery permission is required',
              style: TextStyle(
                color: Theme.of(context).focusColor,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await PhotoManager.openSetting();

                if (!mounted) return;

                setState(() {
                  _loading = true;
                });

                _loadGallery();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: _assets.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: _openCamera,
            child: Container(
              color: Theme.of(context).focusColor.withValues(
                alpha: 0.08,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 30,
                    color: Theme.of(context).focusColor,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Camera',
                    style: TextStyle(
                      color: Theme.of(context).focusColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final asset = _assets[index - 1];

        final selectedIndex = _selectedAssets.indexWhere(
          (item) => item.id == asset.id,
        );

        final isSelected = selectedIndex != -1;

        return GestureDetector(
          onTap: () => _selectAsset(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _assetThumbnail(asset),
              if (asset.type == AssetType.video)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (isSelected)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              if (isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: ColorManager.blue,
                    child: Text(
                      '${selectedIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Gallery thumbnail.
  Widget _assetThumbnail(AssetEntity asset) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      ),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return Container(
            color: Theme.of(context).focusColor.withValues(
              alpha: 0.08,
            ),
          );
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // Post, Story, Reels and Live selector.
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).focusColor.withValues(
              alpha: 0.15,
            ),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          _modes.length,
          (index) {
            final selected = _selectedMode == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMode = index;
                });

                _saveSelectedMode(index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _modes[index],
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).focusColor
                            : Theme.of(context).focusColor.withValues(
                                alpha: 0.55,
                              ),
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (selected)
                      Container(
                        height: 3,
                        width: 25,
                        decoration: BoxDecoration(
                          color: ColorManager.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
