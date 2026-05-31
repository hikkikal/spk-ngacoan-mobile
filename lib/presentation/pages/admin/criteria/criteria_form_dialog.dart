import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/criteria_model.dart';
import '../../../blocs/criteria/criteria_bloc.dart';
import '../../../blocs/criteria/criteria_event.dart';
import '../../../blocs/criteria/criteria_state.dart';

class CriteriaFormDialog extends StatefulWidget {
  final CriteriaModel? criteria;

  const CriteriaFormDialog({super.key, this.criteria});

  @override
  State<CriteriaFormDialog> createState() => _CriteriaFormDialogState();
}

class _CriteriaFormDialogState extends State<CriteriaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String _selectedType = 'benefit';
  int _selectedWeight = 1;

  bool get _isEdit => widget.criteria != null;

  final List<Map<String, String>> _typeOptions = [
    {'value': 'benefit', 'label': 'Benefit (Semakin besar nilai, semakin baik)'},
    {'value': 'cost', 'label': 'Cost (Semakin kecil nilai, semakin baik)'},
  ];

  final List<Map<String, String>> _weightOptions = [
    {'value': '1', 'label': '1 - Sangat Rendah'},
    {'value': '2', 'label': '2 - Rendah'},
    {'value': '3', 'label': '3 - Sedang'},
    {'value': '4', 'label': '4 - Tinggi'},
    {'value': '5', 'label': '5 - Sangat Tinggi'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.criteria?.name ?? '',
    );
    if (_isEdit) {
      _selectedType = widget.criteria!.type;
      _selectedWeight = widget.criteria!.weightInput.toInt();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_isEdit) {
        context.read<CriteriaBloc>().add(
              CriteriaUpdateRequested(
                id: widget.criteria!.id,
                name: _nameController.text.trim(),
                type: _selectedType,
                weightInput: _selectedWeight,
              ),
            );
      } else {
        context.read<CriteriaBloc>().add(
              CriteriaAddRequested(
                name: _nameController.text.trim(),
                type: _selectedType,
                weightInput: _selectedWeight,
              ),
            );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Kriteria' : 'Tambah Kriteria Baru',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem EDAS akan menyesuaikan bobot otomatis.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Kriteria
                  const Text(
                    'Nama Kriteria',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Harga Bahan Baku',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama kriteria tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tipe Kriteria
                  const Text(
                    'Tipe Kriteria',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: _typeOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'],
                            child: Text(
                              opt['label']!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prioritas / Bobot
                  const Text(
                    'Prioritas Kepentingan (Skala 1 - 5)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedWeight,
                        isExpanded: true,
                        items: _weightOptions.map((opt) {
                          return DropdownMenuItem(
                            value: int.parse(opt['value']!),
                            child: Text(
                              opt['label']!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedWeight = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  BlocBuilder<CriteriaBloc, CriteriaState>(
                    builder: (context, state) {
                      final isLoading = state is CriteriaActionLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Simpan Perubahan' : 'Simpan Parameter',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}