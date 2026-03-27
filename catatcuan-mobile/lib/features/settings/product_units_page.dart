import 'package:catatcuan_mobile/core/services/settings_master_data_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductUnitsPage extends StatefulWidget {
  const ProductUnitsPage({super.key});

  @override
  State<ProductUnitsPage> createState() => _ProductUnitsPageState();
}

class _ProductUnitsPageState extends State<ProductUnitsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final units = await SettingsMasterDataService.getProductUnits();
      if (!mounted) return;
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(context, 'Gagal memuat satuan produk: $e');
    }
  }

  Future<void> _showUnitForm({Map<String, dynamic>? unit}) async {
    final controller = TextEditingController(
      text: unit?['nama_satuan'] as String? ?? '',
    );
    final isEdit = unit != null;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Satuan Produk' : 'Tambah Satuan Produk',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Satuan akan dipakai saat menambah stok dan menjual produk.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: PCS',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        AppToast.showInfo(context, 'Nama satuan harus diisi');
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        if (isEdit) {
                          await SettingsMasterDataService.updateProductUnit(
                            unitId: unit['id'].toString(),
                            oldName: unit['nama_satuan'].toString(),
                            newName: name,
                          );
                        } else {
                          await SettingsMasterDataService.addProductUnit(name);
                        }

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadUnits();
                        AppToast.showSuccess(
                          context,
                          isEdit
                              ? 'Satuan produk berhasil diperbarui'
                              : 'Satuan produk berhasil ditambahkan',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setModalState(() => isSaving = false);
                        AppToast.showError(context, 'Gagal menyimpan satuan: $e');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEdit ? 'Simpan' : 'Tambah',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUnit(Map<String, dynamic> unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Satuan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Satuan "${unit['nama_satuan']}" akan dihapus. Lanjutkan?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SettingsMasterDataService.deleteProductUnit(
        unitId: unit['id'].toString(),
        unitName: unit['nama_satuan'].toString(),
      );
      if (!mounted) return;
      await _loadUnits();
      AppToast.showSuccess(context, 'Satuan produk berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menghapus satuan: $e');
    }
  }

  void _showActions(Map<String, dynamic> unit) {
    final isBuiltIn = unit['master_satuan_id'] != null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              unit['nama_satuan'] as String? ?? 'Satuan',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (isBuiltIn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                ),
                child: Text(
                  'Satuan bawaan tidak bisa dihapus dari halaman ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF166534),
                  ),
                ),
              )
            else ...[
              _buildActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Satuan',
                onTap: () {
                  Navigator.pop(ctx);
                  _showUnitForm(unit: unit);
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'Hapus Satuan',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteUnit(unit);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1EDD8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Satuan Produk',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => _showUnitForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Tambah Satuan Produk',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUnits,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Kelola satuan barang seperti PCS, KG, atau BOTOL agar input stok lebih konsisten.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_units.isEmpty)
                    _buildEmptyState(
                      title: 'Belum ada satuan produk',
                      subtitle: 'Tambahkan satuan pertama untuk memudahkan input produk.',
                    )
                  else
                    ..._units.map(_buildUnitCard),
                ],
              ),
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final isBuiltIn = unit['master_satuan_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.straighten_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit['nama_satuan'] as String? ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBuiltIn
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isBuiltIn ? 'Bawaan' : 'Custom',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isBuiltIn
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showActions(unit),
            icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
