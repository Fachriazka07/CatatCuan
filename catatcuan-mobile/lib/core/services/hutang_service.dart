import 'package:supabase_flutter/supabase_flutter.dart';

class HutangService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all hutang/piutang for a warung
  Future<List<Map<String, dynamic>>> getHutangList(String warungId) async {
    final response = await _supabase
        .from('HUTANG')
        .select('''
          *,
          PELANGGAN!pelanggan_id(nama)
        ''')
        .eq('warung_id', warungId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Add new hutang/piutang
  Future<Map<String, dynamic>> addHutang(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('HUTANG')
        .insert(data)
        .select()
        .single();
    return response;
  }

  // Update existing hutang (non-payment details like name/total amount)
  Future<void> updateHutang(String hutangId, Map<String, dynamic> data) async {
    await _supabase.from('HUTANG').update(data).eq('id', hutangId);
  }

  // Delete hutang entirely (cascade: remove payments first)
  Future<void> deleteHutang(String hutangId) async {
    // 1. Delete all related payment records first
    await _supabase.from('PEMBAYARAN_HUTANG').delete().eq('hutang_id', hutangId);
    // 2. Then delete the hutang record
    await _supabase.from('HUTANG').delete().eq('id', hutangId);
  }

  // Fetch payment history for a specific debt
  Future<List<Map<String, dynamic>>> getPayments(String hutangId) async {
    final response = await _supabase
        .from('PEMBAYARAN_HUTANG')
        .select()
        .eq('hutang_id', hutangId)
        .order('tanggal', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Add a payment record and update the HUTANG balances
  Future<void> payHutang(String hutangId, Map<String, dynamic> paymentData) async {
    final amountPaid = paymentData['amount'] as num;

    // 1. Insert payment record
    await _supabase.from('PEMBAYARAN_HUTANG').insert(paymentData);
    
    // 2. Fetch current hutang to calculate new balances
    final currentHutang = await _supabase.from('HUTANG').select().eq('id', hutangId).single();
    
    final currentTerbayar = (currentHutang['amount_terbayar'] as num?)?.toDouble() ?? 0;
    final amountAwal = (currentHutang['amount_awal'] as num?)?.toDouble() ?? 0;
    
    final newTerbayar = currentTerbayar + amountPaid;
    final newSisa = amountAwal - newTerbayar;
    final status = newSisa <= 0 ? 'lunas' : 'belum_lunas';

    // 3. Update HUTANG table
    await _supabase.from('HUTANG').update({
      'amount_terbayar': newTerbayar,
      'amount_sisa': newSisa > 0 ? newSisa : 0,
      'status': status,
    }).eq('id', hutangId);
  }
}
