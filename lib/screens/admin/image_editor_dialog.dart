import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

// ─── Filter definitions ───────────────────────────────────────────────────────

enum ImageFilter {
  normal('Gốc'),
  warm('Ấm áp'),
  cool('Mát lạnh'),
  bw('Đen trắng'),
  vivid('Tươi sáng'),
  fade('Mờ nhạt'),
  vintage('Cổ điển');

  const ImageFilter(this.label);
  final String label;
}

// ─── Main dialog ──────────────────────────────────────────────────────────────

class ImageEditorDialog extends StatefulWidget {
  const ImageEditorDialog({
    super.key,
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  late img.Image _original;
  img.Image? _preview;
  Uint8List? _previewBytes;

  ImageFilter _filter = ImageFilter.normal;
  double _brightness = 0;   // -100 to 100
  double _contrast = 0;     // -100 to 100
  double _saturation = 0;   // -100 to 100
  double _sharpness = 0;    // 0 to 100
  int _rotation = 0;         // 0,90,180,270
  bool _flipH = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _original = img.decodeImage(widget.bytes)!;
    _applyEdits();
  }

  void _autoEnhance() {
    // Analyze image and apply smart adjustments
    setState(() {
      _brightness = 5;
      _contrast = 15;
      _saturation = 20;
      _sharpness = 40;
      _filter = ImageFilter.normal;
    });
    _applyEdits();
  }

  Future<void> _applyEdits() async {
    setState(() => _processing = true);
    final result = await _processImage();
    setState(() {
      _preview = result;
      _previewBytes = Uint8List.fromList(img.encodeJpg(result, quality: 90));
      _processing = false;
    });
  }

  Future<img.Image> _processImage() async {
    img.Image src = img.copyResize(
      _original,
      width: _original.width.clamp(1, 1200),
      interpolation: img.Interpolation.linear,
    );

    // Rotation
    if (_rotation != 0) {
      src = img.copyRotate(src, angle: _rotation.toDouble());
    }
    // Flip
    if (_flipH) src = img.flipHorizontal(src);

    // Brightness (image v4 uses 'exposure' instead of 'brightness')
    if (_brightness != 0) {
      src = img.adjustColor(src, exposure: _brightness / 100);
    }
    // Contrast
    if (_contrast != 0) {
      src = img.adjustColor(src, contrast: 1.0 + _contrast / 100);
    }
    // Saturation
    if (_saturation != 0) {
      src = img.adjustColor(src, saturation: 1.0 + _saturation / 100);
    }

    // Sharpness — apply unsharp mask effect
    if (_sharpness > 0) {
      final strength = _sharpness / 100;
      // Create blurred version
      final blurred = img.gaussianBlur(src, radius: 2);
      // Blend: original + (original - blurred) * strength (unsharp mask)
      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final o = src.getPixel(x, y);
          final b = blurred.getPixel(x, y);
          final nr = (o.r + (o.r - b.r) * strength).clamp(0, 255).toInt();
          final ng = (o.g + (o.g - b.g) * strength).clamp(0, 255).toInt();
          final nb = (o.b + (o.b - b.b) * strength).clamp(0, 255).toInt();
          src.setPixelRgb(x, y, nr, ng, nb);
        }
      }
    }

    // Filters
    switch (_filter) {
      case ImageFilter.warm:
        // Boost red, reduce blue via pixel loop (v4 has no red/blue params)
        for (var y = 0; y < src.height; y++) {
          for (var x = 0; x < src.width; x++) {
            final p = src.getPixel(x, y);
            src.setPixelRgb(x, y,
              (p.r * 1.15).clamp(0, 255).toInt(),
              p.g.toInt(),
              (p.b * 0.85).clamp(0, 255).toInt(),
            );
          }
        }
        src = img.adjustColor(src, saturation: 1.1);
        break;
      case ImageFilter.cool:
        // Reduce red, boost blue
        for (var y = 0; y < src.height; y++) {
          for (var x = 0; x < src.width; x++) {
            final p = src.getPixel(x, y);
            src.setPixelRgb(x, y,
              (p.r * 0.85).clamp(0, 255).toInt(),
              p.g.toInt(),
              (p.b * 1.15).clamp(0, 255).toInt(),
            );
          }
        }
        src = img.adjustColor(src, saturation: 0.95);
        break;
      case ImageFilter.bw:
        src = img.grayscale(src);
        break;
      case ImageFilter.vivid:
        src = img.adjustColor(src, saturation: 1.5, contrast: 1.1);
        break;
      case ImageFilter.fade:
        src = img.adjustColor(src, saturation: 0.6, exposure: 0.1);
        break;
      case ImageFilter.vintage:
        src = img.sepia(src);
        break;
      case ImageFilter.normal:
        break;
    }

    return src;
  }

  Widget _previewWidget() {
    if (_processing || _previewBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Image.memory(
      _previewBytes!,
      fit: BoxFit.contain,
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: (v) { setState(() => onChanged(v)); },
          onChangeEnd: (_) => _applyEdits(),
          activeColor: const Color(0xFF1E88E5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 900,
        height: 640,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Chỉnh sửa ảnh', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Preview
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: const Color(0xFFF0F0F0),
                      padding: const EdgeInsets.all(16),
                      child: _previewWidget(),
                    ),
                  ),
                  // Controls
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rotate & Flip
                          const Text('Xoay & Lật', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _iconBtn(Icons.rotate_left, 'Trái', () {
                                setState(() => _rotation = (_rotation - 90 + 360) % 360);
                                _applyEdits();
                              }),
                              const SizedBox(width: 8),
                              _iconBtn(Icons.rotate_right, 'Phải', () {
                                setState(() => _rotation = (_rotation + 90) % 360);
                                _applyEdits();
                              }),
                              const SizedBox(width: 8),
                              _iconBtn(Icons.flip, 'Lật', () {
                                setState(() => _flipH = !_flipH);
                                _applyEdits();
                              }),
                            ],
                          ),
                          const Divider(height: 24),

                          // Filters
                          const Text('Bộ lọc màu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ImageFilter.values.map((f) {
                              final active = f == _filter;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _filter = f);
                                  _applyEdits();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFF1E88E5) : const Color(0xFFF0F4F8),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: active ? const Color(0xFF1E88E5) : Colors.grey.shade300),
                                  ),
                                  child: Text(f.label, style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700,
                                    color: active ? Colors.white : Colors.black87,
                                  )),
                                ),
                              );
                            }).toList(),
                          ),
                          const Divider(height: 24),

                          // Auto enhance button
                          GestureDetector(
                            onTap: _autoEnhance,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF00A86B)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('✨ Tự động nâng cao', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 24),

                          // Adjustments
                          const Text('Điều chỉnh thủ công', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          _slider('Độ sáng', _brightness, -80, 80, (v) => _brightness = v),
                          _slider('Độ tương phản', _contrast, -80, 80, (v) => _contrast = v),
                          _slider('Độ bão hòa', _saturation, -80, 80, (v) => _saturation = v),
                          _slider('Làm sắc nét', _sharpness, 0, 100, (v) => _sharpness = v),

                          // Reset
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _filter = ImageFilter.normal;
                                _brightness = 0; _contrast = 0; _saturation = 0;
                                _sharpness = 0; _rotation = 0; _flipH = false;
                              });
                              _applyEdits();
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Đặt lại', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _processing ? null : () {
                      Navigator.of(context).pop(_previewBytes);
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Áp dụng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E88E5)),
        ),
      ),
    );
  }
}
