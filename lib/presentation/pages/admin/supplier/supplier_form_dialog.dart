import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
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

  bool get _isEdit => widget.supplier != null;

  // Google Maps
  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);
  LatLng _pinPosition = _defaultCenter;
  bool _mapReady = false;

  // Places Autocomplete
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSuggestionLoading = false;
  bool _showSuggestions = false;
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();

  // Reverse geocoding
  bool _isReverseGeocoding = false;
  Timer? _moveDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _addressController = TextEditingController(text: widget.supplier?.address ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');

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
    _debounce?.cancel();
    _moveDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────

  void _onAddressChanged(String value) {
    _debounce?.cancel();
    if (value.length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(value);
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    setState(() => _isSuggestionLoading = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&sessiontoken=$_sessionToken'
        '&components=country:id'
        '&language=id',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List? ?? [];
        setState(() {
          _suggestions = predictions
              .map((p) => {
                    'place_id': p['place_id'],
                    'description': p['description'],
                  })
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
          _isSuggestionLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSuggestionLoading = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'] as String;
    final description = suggestion['description'] as String;
    setState(() {
      _addressController.text = description;
      _suggestions = [];
      _showSuggestions = false;
    });
    _sessionToken = const Uuid().v4();
    await _fetchPlaceDetail(placeId);
  }

  Future<void> _fetchPlaceDetail(String placeId) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry'
        '&key=${AppConstants.googleMapsApiKey}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final location = data['result']?['geometry']?['location'];
        if (location != null) {
          final pos = LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
          setState(() => _pinPosition = pos);
          _moveMapTo(pos, zoom: 16);
        }
      }
    } catch (_) {}
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  Future<void> _forwardGeocode(String address) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&region=id',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          final pos = LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );
          setState(() => _pinPosition = pos);
          if (_mapReady) _moveMapTo(pos, zoom: 15);
        }
      }
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng position) async {
    if (!mounted) return;
    setState(() => _isReverseGeocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&language=id',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final address = results[0]['formatted_address'] as String? ?? '';
          if (address.isNotEmpty) {
            setState(() => _addressController.text = address);
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  void _moveMapTo(LatLng pos, {double zoom = 15}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: zoom)),
    );
  }

  void _onCameraMove(CameraPosition position) {
    setState(() => _pinPosition = position.target);
  }

  void _onCameraIdle() {
    _moveDebounce?.cancel();
    _moveDebounce = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(_pinPosition);
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();

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
        if (state is SupplierActionSuccess) Navigator.pop(context);
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
                          color: AppTheme.primary, size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEdit ? 'Edit Supplier' : 'Tambah Supplier',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Nama
                  const _FieldLabel(label: 'Nama Supplier', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(hint: 'cth. Sahabat Frozen Food', icon: Icons.store_outlined),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Alamat + Autocomplete
                  Row(
                    children: [
                      const _FieldLabel(label: 'Alamat Lengkap', required: true),
                      const SizedBox(width: 6),
                      if (_isReverseGeocoding)
                        const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    onChanged: _onAddressChanged,
                    maxLines: 2,
                    minLines: 1,
                    decoration: _inputDecoration(
                      hint: 'Ketik alamat atau geser peta...',
                      icon: Icons.location_on_outlined,
                      suffix: _isSuggestionLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Alamat wajib diisi' : null,
                  ),

                  // ── Suggestions
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.divider),
                        itemBuilder: (_, index) {
                          final s = _suggestions[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _selectSuggestion(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s['description'] as String,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ── Google Maps
                  const _FieldLabel(label: 'Lokasi di Peta'),
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
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _pinPosition,
                                zoom: _isEdit ? 15 : 5,
                              ),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                setState(() => _mapReady = true);
                                if (_isEdit) _moveMapTo(_pinPosition, zoom: 15);
                              },
                              onCameraMove: _onCameraMove,
                              onCameraIdle: _onCameraIdle,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: false,
                            ),
                            // Pin tengah
                            const Center(child: _MapPin()),
                            // Hint label
                            Positioned(
                              top: 10, left: 0, right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Geser peta untuk atur lokasi',
                                    style: TextStyle(color: Colors.white, fontSize: 11),
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
                    'Ketik alamat atau geser peta — alamat otomatis terisi.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // ── Telepon
                  const _FieldLabel(label: 'No. Telepon'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(hint: 'cth. 08123456789', icon: Icons.phone_outlined),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 18, width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEdit ? 'Simpan Perubahan' : 'Tambah Supplier',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
      suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(12), child: suffix) : null,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.error)),
    );
  }
}

// ─── Map Pin ──────────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.store, color: Colors.white, size: 18),
        ),
        ClipPath(
          clipper: _TriangleClipper(),
          child: Container(width: 14, height: 8, color: AppTheme.primary),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(size.width, 0)
    ..close();

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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        children: [
          TextSpan(text: label),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppTheme.error)),
        ],
      ),
    );
  }
}