import 'package:catatcuan_mobile/core/services/data_cache_service.dart';
import 'package:catatcuan_mobile/core/services/settings_master_data_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseCategoriesPage extends StatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage> {
  final _cache = DataCacheService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _loadCategories();
  }

  void _loadFromCache() {
    final cached = List<Map<String, dynamic>>.from(_cache.expenseCategories)
      ..removeWhere(
        (category) => (category['tipe'] as String? ?? 'business') != 'business',
      )
      ..sort((a, b) {
        final orderA = (a['sort_order'] as num?)?.toInt() ?? 0;
        final orderB = (b['sort_order'] as num?)?.toInt() ?? 0;
        if (orderA != orderB) return orderA.compareTo(orderB);
        return (a['nama_kategori'] as String? ?? '')
            .compareTo(b['nama_kategori'] as String? ?? '');
      });

    if (cached.isEmpty) return;

    setState(() {
      _categories = cached;
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    if (_categories.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final categories = await SettingsMasterDataService.getExpenseCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.showError(context, 'Gagal memuat kategori pengeluaran: $e');
    }
  }

  Future<void> _showCategoryForm({Map<String, dynamic>? category}) async {
    final controller = TextEditingController(
      text: category?['nama_kategori'] as String? ?? '',
    );
    final isEdit = category != null;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit Kategori Pengeluaran' : 'Tambah Kategori Pengeluaran',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur kategori pengeluaran agar pencatatan biaya warung lebih rapi.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Listrik',
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
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1EDD8)),
                ),
                child: Text(
                  'Kategori ini khusus untuk pengeluaran warung.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
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
                        AppToast.showInfo(context, 'Nama kategori harus diisi');
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        if (isEdit) {
                          await SettingsMasterDataService.updateExpenseCategory(
                            categoryId: category['id'].toString(),
                            name: name,
                            type: 'business',
                          );
                        } else {
                          await SettingsMasterDataService.addExpenseCategory(
                            name: name,
                            type: 'business',
                          );
                        }

                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadCategories();
                        AppToast.showSuccess(
                          context,
                          isEdit
                              ? 'Kategori pengeluaran berhasil diperbarui'
                              : 'Kategori pengeluaran berhasil ditambahkan',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setModalState(() => isSaving = false);
                        AppToast.showError(context, 'Gagal menyimpan kategori: $e');
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

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Kategori',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Kategori "${category['nama_kategori']}" akan dihapus. Lanjutkan?',
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
      await SettingsMasterDataService.deleteExpenseCategory(
        category['id'].toString(),
      );
      if (!mounted) return;
      await _loadCategories();
      AppToast.showSuccess(context, 'Kategori pengeluaran berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menghapus kategori: $e');
    }
  }

  void _showActions(Map<String, dynamic> category) {
    final isBuiltIn = category['master_kategori_id'] != null;

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
              category['nama_kategori'] as String? ?? 'Kategori',
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
                  'Kategori bawaan tidak bisa dihapus dari halaman ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF166534),
                  ),
                ),
              )
            else ...[
              _buildActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Kategori',
                onTap: () {
                  Navigator.pop(ctx);
                  _showCategoryForm(category: category);
                },
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'Hapus Kategori',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteCategory(category);
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

  String _typeLabel(String? type) => type == 'personal' ? 'Pribadi' : 'Warung';

  Color _typeColor(String? type) =>
      type == 'personal' ? const Color(0xFFD97706) : const Color(0xFF166534);

  Color _typeBackground(String? type) =>
      type == 'personal' ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Kategori Pengeluaran',
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
            onPressed: () => _showCategoryForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Tambah Kategori Pengeluaran',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Kelola kategori pengeluaran agar catatan biaya warung dan pribadi tetap tertata.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_categories.isEmpty)
                    _buildEmptyState(
                      title: 'Belum ada kategori pengeluaran',
                      subtitle: 'Tambahkan kategori agar pencatatan pengeluaran lebih mudah.',
                    )
                  else
                    ..._categories.map(_buildCategoryCard),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isBuiltIn = category['master_kategori_id'] != null;
    final type = category['tipe'] as String?;

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
              color: _typeBackground(type),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              type == 'personal'
                  ? Icons.person_outline
                  : Icons.receipt_long_outlined,
              color: _typeColor(type),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['nama_kategori'] as String? ?? '-',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _typeBackground(type),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _typeColor(type),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showActions(category),
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
          const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF9CA3AF)),
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
