import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/supplier_model.dart';
import '../../../blocs/supplier/supplier_bloc.dart';
import '../../../blocs/supplier/supplier_event.dart';
import '../../../blocs/supplier/supplier_state.dart';

class SupplierFormDialog extends StatefulWidget {
  final SupplierModel? supplier;

  const SupplierFormDialog({super.key, this.supplier});

  @override
  State<SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  final MapController _mapController = MapController();

  bool get _isEdit => widget.supplier != null;

  // Default center: Indonesia
  static const LatLng _defaultCenter = LatLng(-2.5489, 118.0149);

  LatLng _pinPosition = _defaultCenter;
  bool _isReverseGeocoding = false;
  bool _mapReady = false;
  Timer? _moveDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');

    // Kalau edit, geocode alamat untuk dapat koordinat awal
    if (_isEdit && widget.supplier!.address.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forwardGeocode(widget.supplier!.address);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _moveDebounce?.cancel();
    super.dispose();
  }

  // Forward geocode untuk mode edit (alamat → koordinat) — hanya sekali saat init
  Future<void> _forwardGeocode(String address) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(address)}'
        '&format=json&limit=1&countrycodes=id',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'SPKNgacoan/1.0 (contact@ngacoan.com)',
        'Accept-Language': 'id',
      });
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final pos = LatLng(lat, lon);
          setState(() => _pinPosition = pos);
          if (_mapReady) {
            _mapController.move(pos, 15);
          }
        }
      }
    } catch (_) {}
  }

  // Reverse geocode: koordinat → alamat (dipanggil saat peta berhenti bergerak)
  Future<void> _reverseGeocode(LatLng position) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&format=json'
        '&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'SPKNgacoan/1.0 (contact@ngacoan.com)',
        'Accept-Language': 'id',
      });
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        if (displayName.isNotEmpty) {
          setState(() {
            _addressController.text = displayName;
          });
        }
      }
    } catch (_) {
      // Gagal reverse geocode — biarkan user isi manual
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // Dipanggil saat peta selesai digeser
  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;

    // Update posisi pin ke tengah peta
    setState(() => _pinPosition = camera.center);

    // Debounce reverse geocode — tunggu user berhenti geser
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(camera.center);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();

    if (_isEdit) {
      context.read<SupplierBloc>().add(SupplierUpdateRequested(
            id: widget.supplier!.id,
            name: name,
            address: address,
            phone: phone,
          ));
    } else {
      context.read<SupplierBloc>().add(SupplierAddRequested(
            name: name,
            address: address,
            phone: phone,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierActionSuccess) {
          Navigator.pop(context);
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isEdit ? Icons.edit_outlined : Icons.store_outlined,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEdit ? 'Edit Supplier' : 'Tambah Supplier',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Nama
                  _FieldLabel(label: 'Nama Supplier', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      hint: 'cth. Sahabat Frozen Food',
                      icon: Icons.store_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Map pilih lokasi
                  _FieldLabel(label: 'Pilih Lokasi di Peta', required: true),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            // Peta
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _pinPosition,
                                initialZoom: _isEdit ? 15 : 5,
                                onMapReady: () => setState(() => _mapReady = true),
                                onPositionChanged: _onMapMoved,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom |
                                      InteractiveFlag.drag |
                                      InteractiveFlag.doubleTapZoom,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.ngacoan.spk',
                                ),
                              ],
                            ),

                            // Pin di tengah peta (tidak ikut bergerak)
                            const Center(
                              child: _MapPin(),
                            ),

                            // Label geser peta
                            Positioned(
                              top: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Geser peta untuk pilih lokasi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Koordinat di sudut kanan bawah
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_pinPosition.latitude.toStringAsFixed(5)}, '
                                  '${_pinPosition.longitude.toStringAsFixed(5)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Zoom in untuk presisi lebih tinggi',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // ── Alamat (auto-filled dari reverse geocode, bisa edit manual)
                  Row(
                    children: [
                      _FieldLabel(label: 'Alamat Lengkap', required: true),
                      const SizedBox(width: 6),
                      if (_isReverseGeocoding)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    minLines: 1,
                    decoration: _inputDecoration(
                      hint: 'Otomatis terisi dari peta, atau ketik manual',
                      icon: Icons.location_on_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Telepon
                  const _FieldLabel(label: 'No. Telepon'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                      hint: 'cth. 08123456789',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit Button
                  BlocBuilder<SupplierBloc, SupplierState>(
                    builder: (context, state) {
                      final isLoading = state is SupplierActionLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Simpan Perubahan' : 'Tambah Supplier',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondary,
      ),
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.error),
      ),
    );
  }
}

// ─── Map Pin Widget ───────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 18),
        ),
        // Ganti CustomPaint dengan Triangle biasa
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(
            width: 14,
            height: 8,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    return ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_) => false;
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppTheme.error),
            ),
        ],
      ),
    );
  }
}