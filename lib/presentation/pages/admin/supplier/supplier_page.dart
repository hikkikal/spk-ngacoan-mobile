import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/supplier_model.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/supplier/supplier_bloc.dart';
import '../../../blocs/supplier/supplier_event.dart';
import '../../../blocs/supplier/supplier_state.dart';
import 'supplier_form_dialog.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(const SupplierLoadRequested());
  }

  List<SupplierModel> _getSuppliers(SupplierState state) {
    if (state is SupplierLoaded) return state.suppliers;
    if (state is SupplierActionLoading) return state.suppliers;
    if (state is SupplierActionSuccess) return state.suppliers;
    if (state is SupplierActionError) return state.suppliers;
    return [];
  }

  bool get _isOwner {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.role == 'owner';
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SupplierBloc>(),
        child: const SupplierFormDialog(),
      ),
    );
  }

  void _openEditDialog(SupplierModel supplier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SupplierBloc>(),
        child: SupplierFormDialog(supplier: supplier),
      ),
    );
  }

  void _confirmDelete(SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Supplier',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Hapus supplier '),
              TextSpan(
                text: supplier.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const TextSpan(text: '? Tindakan ini tidak dapat dibatalkan.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SupplierBloc>().add(SupplierDeleteRequested(id: supplier.id));
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isOwner;

    return BlocListener<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: const Color(0xFF2DD4BF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
        if (state is SupplierActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      },
      child: SafeArea(
        child: Column(
          children: [
            _SupplierHeader(onAdd: isOwner ? _openAddDialog : null),
            Expanded(
              child: BlocBuilder<SupplierBloc, SupplierState>(
                builder: (context, state) {
                  if (state is SupplierLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is SupplierError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<SupplierBloc>().add(const SupplierLoadRequested()),
                    );
                  }

                  final suppliers = _getSuppliers(state);
                  final isActionLoading = state is SupplierActionLoading;

                  if (suppliers.isEmpty) {
                    return _EmptyView(isOwner: isOwner, onAdd: _openAddDialog);
                  }

                  return Stack(
                    children: [
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final supplier = suppliers[index];
                          return _SupplierCard(
                            supplier: supplier,
                            index: index,
                            isOwner: isOwner,
                            onEdit: () => _openEditDialog(supplier),
                            onDelete: () => _confirmDelete(supplier),
                          );
                        },
                      ),
                      if (isActionLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SupplierHeader extends StatelessWidget {
  final VoidCallback? onAdd;
  const _SupplierHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Supplier',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mitra Pemasok',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Kelola daftar supplier yang akan dievaluasi.',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              if (onAdd != null)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Tambah',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Supplier Card dengan Mini Map ────────────────────────────────────────────

class _SupplierCard extends StatefulWidget {
  final SupplierModel supplier;
  final int index;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.index,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends State<_SupplierCard> {
  LatLng? _coords;
  bool _geocoding = false;
  bool _geocoded = false;
  GoogleMapController? _mapController;
  bool _mapInteractive = false;

  @override
  void initState() {
    super.initState();
    _geocodeAddress();
  }

  Future<void> _geocodeAddress() async {
    if (widget.supplier.address.isEmpty) return;
    setState(() => _geocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(widget.supplier.address)}'
        '&key=${AppConstants.googleMapsApiKey}'
        '&region=id',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final loc = results[0]['geometry']['location'];
          setState(() {
            _coords = LatLng(
              (loc['lat'] as num).toDouble(),
              (loc['lng'] as num).toDouble(),
            );
            _geocoded = true;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kode = 'A${widget.index + 1}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info supplier
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kode badge
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(kode,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.supplier.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.supplier.address,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.supplier.phone != null && widget.supplier.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(widget.supplier.phone!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        const Text('Tidak ada nomor telepon',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
                if (widget.isOwner)
                  Column(
                    children: [
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFF2DD4BF),
                        onTap: widget.onEdit,
                      ),
                      const SizedBox(height: 6),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        color: AppTheme.error,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Mini Map
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 160,
              child: _geocoding
                  ? Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(height: 8),
                            Text('Memuat peta...',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  : _geocoded && _coords != null
                      ? Stack(
                          children: [
                            // Peta — gesture dikendalikan _mapInteractive
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _coords!,
                                zoom: 15,
                              ),
                              onMapCreated: (c) => _mapController = c,
                              markers: {
                                Marker(
                                  markerId: MarkerId('supplier_${widget.supplier.id}'),
                                  position: _coords!,
                                  infoWindow: InfoWindow(title: widget.supplier.name),
                                ),
                              },
                              zoomControlsEnabled: _mapInteractive,
                              myLocationButtonEnabled: false,
                              mapToolbarEnabled: false,
                              scrollGesturesEnabled: _mapInteractive,
                              zoomGesturesEnabled: _mapInteractive,
                              rotateGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                            ),

                            // Overlay saat belum aktif — tap untuk aktifkan
                            if (!_mapInteractive)
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () => setState(() => _mapInteractive = true),
                                  child: Container(
                                    color: Colors.transparent,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.touch_app_outlined,
                                                color: Colors.white, size: 13),
                                            SizedBox(width: 4),
                                            Text('Tap untuk geser peta',
                                                style: TextStyle(
                                                    color: Colors.white, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Tombol keluar mode interaktif
                            if (_mapInteractive)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _mapInteractive = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Selesai',
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 28,
                                    color: AppTheme.textSecondary),
                                SizedBox(height: 6),
                                Text('Lokasi tidak ditemukan',
                                    style: TextStyle(
                                        fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── Empty View ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onAdd;
  const _EmptyView({required this.isOwner, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.store_outlined, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada supplier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Tambahkan supplier pertama untuk mulai evaluasi.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            if (isOwner) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Tambah Supplier',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 12),
            const Text('Gagal memuat data',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('Periksa koneksi internet Anda.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Coba Lagi',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}