import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/services/session_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> _customers = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  int _currentLimit = 8;
  bool _hasMore = false;
  String? _warungId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
      // We could add a debounce here if querying from DB, 
      // but since we might fetch max 8, we can filter locally or re-fetch.
      // Let's implement local filter on fetched data and re-fetch if needed.
      // Actually, standard server-side search needs debounce.
      // For simplicity, let's fetch based on search query on submit, or local filter.
      // User says "search bar samain", so real-time filter might be nice.
      _fetchCustomers(reset: true);
    });
    _fetchCustomers(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({bool reset = false}) async {
    if (reset) {
      _currentLimit = 8;
      _customers.clear();
      _hasMore = false;
    }
    
    setState(() => _isLoading = true);
    try {
      if (_warungId == null) {
        final userId = await SessionService.getUserId();
        if (userId != null) {
          final warung = await _supabase
              .from('WARUNG')
              .select('id')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          _warungId = warung?['id']?.toString();
        }
      }

      if (_warungId == null) return;

      var query = _supabase
          .from('PELANGGAN')
          .select()
          .eq('warung_id', _warungId!);

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('nama', '%$_searchQuery%');
      }

      // Fetch one extra to determine if there's more
      final response = await query.order('nama', ascending: true).limit(_currentLimit + 1);
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      setState(() {
        if (data.length > _currentLimit) {
          _hasMore = true;
          _customers = data.sublist(0, _currentLimit);
        } else {
          _hasMore = false;
          _customers = data;
        }
      });
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMore() {
    if (!_hasMore) return;
    setState(() {
      _currentLimit += 8;
    });
    _fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading && _customers.isEmpty && _searchQuery.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? _buildEmptyState()
                      : _buildCustomerList(),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await context.push('/pelanggan/add');
            if (result == true) {
              _fetchCustomers(reset: true);
            }
          },
          backgroundColor: AppTheme.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 30, height: 6, color: Colors.white),
              Container(width: 6, height: 30, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pelanggan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ketik Nama Pelanggan...',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFD1EDD8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF13B158), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_list, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Belum ada pelanggan' : 'Pelanggan tidak ditemukan',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    final List<Widget> listWidgets = [];
    final List<Widget> cardItems = [];

    for (int i = 0; i < _customers.length; i++) {
      cardItems.add(_buildCustomerCardContent(_customers[i]));
      if (i < _customers.length - 1) {
        cardItems.add(const Divider(height: 1, thickness: 1, color: Color(0xFFD1EDD8)));
      }
    }

    listWidgets.add(
      Container(
        margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
        ),
        child: Column(
          children: cardItems,
        ),
      ),
    );

    if (_hasMore) {
      listWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
          child: InkWell(
            onTap: _loadMore,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                  'Load More',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
            ),
          ),
        ),
      );
    } else {
      listWidgets.add(const SizedBox(height: 100));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: listWidgets,
    );
  }

  Widget _buildCustomerCardContent(Map<String, dynamic> customer) {
    final String nama = customer['nama']?.toString().toUpperCase() ?? 'TANPA NAMA';
    final String alamatRaw = customer['alamat']?.toString() ?? '';
    final String phoneRaw = customer['phone']?.toString() ?? '';

    final String alamat = alamatRaw.isNotEmpty ? alamatRaw : '-';
    final String phone = phoneRaw.isNotEmpty ? phoneRaw : '-';

    return InkWell(
      onTap: () async {
        final result = await context.push('/pelanggan/detail', extra: customer);
        if (result == true) {
          _fetchCustomers(reset: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon - 48x48
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1EDD8)),
              ),
              child: Image.asset(
                'assets/icon/User.png', 
                width: 36, 
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500, // medium
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2), // Empty gap
                  Text(
                    '$alamat • $phone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // medium
                      color: const Color(0xFF6B7280).withValues(alpha: 0.8), // 80%
                      fontFamily: 'Poppins',
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
}
