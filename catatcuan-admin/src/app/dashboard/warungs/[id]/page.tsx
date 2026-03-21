import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  BookOpenText,
  Boxes,
  History,
  MapPin,
  Phone,
  Receipt,
  ShoppingCart,
  Store,
  UserCircle2,
  Users,
  Wallet,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/server';
import {
  formatCurrency,
  formatDate,
  formatDateTime,
  formatNumber,
  formatShortId,
} from '@/lib/admin-format';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DetailHeroCard,
  DetailInfoGrid,
  DetailPageHeader,
  DetailSection,
  DetailStatCard,
} from '@/components/admin/entity-detail';
import { UserStatusBadge } from '@/components/admin/status-badge';

interface WarungRecord {
  id: string;
  user_id: string;
  nama_warung: string;
  nama_pemilik: string | null;
  phone: string | null;
  alamat: string | null;
  saldo_awal: number | string | null;
  created_at: string;
  updated_at: string | null;
  uang_kas?: number | string | null;
  uang_kas_operasional?: number | string | null;
}

interface UserRecord {
  id: string;
  phone_number: string;
  status: string;
  created_at: string;
  last_login_at: string | null;
}

interface RecentSale {
  id: string;
  invoice_no: string | null;
  total_amount: number | string;
  payment_method: string;
  tanggal: string;
}

interface RecentExpense {
  id: string;
  amount: number | string;
  keterangan: string | null;
  tanggal: string;
}

interface CashbookEntry {
  id: string;
  tanggal: string;
  tipe: string;
  sumber: string;
  amount: number | string;
  saldo_setelah: number | string;
}

function EmptyState({ label }: { label: string }) {
  return (
    <div className="flex min-h-36 items-center justify-center rounded-xl border border-dashed border-border/70 bg-muted/20 px-6 text-center">
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  );
}

export default async function WarungDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const warungQuery = await supabase
    .from('WARUNG')
    .select('*')
    .eq('id', id)
    .maybeSingle();

  const warung = warungQuery.data as WarungRecord | null;
  const warungError = warungQuery.error;

  if (warungError) {
    throw new Error(warungError.message);
  }

  if (!warung) {
    notFound();
  }

  const userQuery = await supabase
    .from('USERS')
    .select('id, phone_number, status, created_at, last_login_at')
    .eq('id', warung.user_id)
    .maybeSingle();

  const user = userQuery.data as UserRecord | null;
  const userError = userQuery.error;

  if (userError) {
    throw new Error(userError.message);
  }

  const [
    productCount,
    customerCount,
    saleCount,
    expenseCount,
    activeDebtCount,
    cashbookCount,
    recentSales,
    recentExpenses,
    recentCashbook,
  ] = await Promise.all([
    supabase
      .from('PRODUK')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id)
      .eq('is_active', true),
    supabase
      .from('PELANGGAN')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id),
    supabase
      .from('PENJUALAN')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id),
    supabase
      .from('PENGELUARAN')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id),
    supabase
      .from('HUTANG')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id)
      .in('status', ['belum_lunas', 'lewat_jatuh_tempo']),
    supabase
      .from('BUKU_KAS')
      .select('*', { count: 'exact', head: true })
      .eq('warung_id', warung.id),
    supabase
      .from('PENJUALAN')
      .select('id, invoice_no, total_amount, payment_method, tanggal')
      .eq('warung_id', warung.id)
      .order('tanggal', { ascending: false })
      .limit(5),
    supabase
      .from('PENGELUARAN')
      .select('id, amount, keterangan, tanggal')
      .eq('warung_id', warung.id)
      .order('tanggal', { ascending: false })
      .limit(5),
    supabase
      .from('BUKU_KAS')
      .select('id, tanggal, tipe, sumber, amount, saldo_setelah')
      .eq('warung_id', warung.id)
      .order('tanggal', { ascending: false })
      .limit(5),
  ]);

  return (
    <div className="space-y-6">
      <DetailPageHeader
        backHref="/dashboard/users"
        backLabel="Kembali ke daftar"
        title="Detail Warung"
        description="Lihat profil warung, kondisi akun pemilik, dan aktivitas operasional terbaru."
      />

      {/* Row 1: Hero & Account Info */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <DetailHeroCard
            icon={Store}
            title={warung.nama_warung}
            subtitle={`Pemilik ${warung.nama_pemilik ?? 'Belum diisi'}`}
            badges={
              <>
                {user ? <UserStatusBadge status={user.status} /> : null}
                <Badge variant="outline">
                  Terdaftar {formatDate(warung.created_at)}
                </Badge>
              </>
            }
            metadata={
              <div className="flex flex-wrap gap-x-6 gap-y-2">
                <span className="flex items-center gap-1.5">
                  <Badge variant="secondary" className="font-mono text-[10px] uppercase tracking-wider">ID</Badge> 
                  {formatShortId(warung.id)}
                </span>
                <span>Pemilik: {warung.nama_pemilik ?? '-'}</span>
                <span>Terakhir masuk: {formatDateTime(user?.last_login_at ?? null)}</span>
              </div>
            }
          />
        </div>
        <div className="lg:col-span-1">
          <DetailSection
            title="Status Akun"
            description="Informasi akses pemilik"
            className="h-full"
          >
            <div className="space-y-4">
              {user ? (
                <UserStatusBadge status={user.status} />
              ) : (
                <Badge variant="outline">Tidak ditemukan</Badge>
              )}
              <div className="text-xs text-muted-foreground">
                <p>No. HP: {user?.phone_number ?? '-'}</p>
                <p className="mt-1">ID Pemilik: <span className="font-mono">{formatShortId(user?.id)}</span></p>
              </div>
              {user && (
                <Button variant="outline" size="sm" className="w-full" asChild>
                  <Link href={`/dashboard/users/${user.id}`}>
                    <UserCircle2 className="h-4 w-4" />
                    Detail Pemilik
                  </Link>
                </Button>
              )}
            </div>
          </DetailSection>
        </div>
      </div>

      {/* Row 2: Main Stats Grid (Bento Style) */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <DetailStatCard
          label="Saldo Awal"
          value={formatCurrency(warung.saldo_awal)}
          description="Modal setup"
          icon={Wallet}
        />
        <DetailStatCard
          label="Produk Aktif"
          value={formatNumber(productCount.count ?? 0)}
          description="Aktif dijual"
          icon={Boxes}
          accentClassName="border-blue-500/20 bg-blue-500/10 text-blue-500"
        />
        <DetailStatCard
          label="Pelanggan"
          value={formatNumber(customerCount.count ?? 0)}
          description="Data tersimpan"
          icon={Users}
          accentClassName="border-violet-500/20 bg-violet-500/10 text-violet-500"
        />
        <DetailStatCard
          label="Transaksi"
          value={formatNumber(saleCount.count ?? 0)}
          description="Total penjualan"
          icon={ShoppingCart}
          accentClassName="border-amber-500/20 bg-amber-500/10 text-amber-500"
        />
        <DetailStatCard
          label="Pengeluaran"
          value={formatNumber(expenseCount.count ?? 0)}
          description="Total dicatat"
          icon={Receipt}
          accentClassName="border-rose-500/20 bg-rose-500/10 text-rose-500"
        />
        <DetailStatCard
          label="Buku Kas"
          value={formatNumber(cashbookCount.count ?? 0)}
          description="Entri arus kas"
          icon={BookOpenText}
          accentClassName="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
        />
      </div>

      {/* Row 3: Warung Profile & Finance Summary */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <DetailSection
            title="Profil Warung"
            description="Informasi operasional utama"
            className="h-full"
          >
            <DetailInfoGrid
              items={[
                {
                  label: 'Nama Warung',
                  value: warung.nama_warung,
                },
                {
                  label: 'Alamat',
                  value: (
                    <div className="flex items-start gap-2">
                      <MapPin className="mt-0.5 h-4 w-4 text-muted-foreground" />
                      <span className="line-clamp-2">{warung.alamat ?? '-'}</span>
                    </div>
                  ),
                },
                {
                  label: 'Uang Kas',
                  value: formatCurrency(warung.uang_kas),
                },
                {
                  label: 'Kas Operasional',
                  value: formatCurrency(warung.uang_kas_operasional),
                },
              ]}
            />
          </DetailSection>
        </div>

        <div className="lg:col-span-1">
          <DetailSection
            title="Ringkasan Hutang"
            description="Kewajiban tertunda"
            className="h-full"
          >
            <div className="flex flex-col items-center justify-center py-4">
              <p className="text-4xl font-bold tracking-tight text-rose-500">
                {formatNumber(activeDebtCount.count ?? 0)}
              </p>
              <p className="mt-2 text-center text-sm text-muted-foreground">
                Hutang belum lunas atau lewat jatuh tempo
              </p>
              <div className="mt-6 flex w-full items-center gap-2 rounded-xl bg-muted/50 p-3 text-xs text-muted-foreground">
                <History className="h-4 w-4" />
                <span>Monitoring berkala disarankan</span>
              </div>
            </div>
          </DetailSection>
        </div>
      </div>

      {/* Row 4: Recent Activities */}
      <div className="grid gap-6 lg:grid-cols-2">
        <DetailSection
          title="Penjualan Terbaru"
          description="Transaksi terakhir warung"
        >
          {(recentSales.data as RecentSale[] | null)?.length ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Invoice</TableHead>
                    <TableHead>Metode</TableHead>
                    <TableHead>Total</TableHead>
                    <TableHead>Tanggal</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(recentSales.data as RecentSale[]).map((sale) => (
                    <TableRow key={sale.id}>
                      <TableCell className="font-medium text-xs">
                        {sale.invoice_no ?? formatShortId(sale.id)}
                      </TableCell>
                      <TableCell className="capitalize text-xs">
                        {sale.payment_method}
                      </TableCell>
                      <TableCell className="text-xs font-semibold">{formatCurrency(sale.total_amount)}</TableCell>
                      <TableCell className="text-xs text-muted-foreground">{formatDateTime(sale.tanggal)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <EmptyState label="Belum ada transaksi penjualan." />
          )}
        </DetailSection>

        <DetailSection
          title="Pengeluaran Terbaru"
          description="Biaya operasional terakhir"
        >
          {(recentExpenses.data as RecentExpense[] | null)?.length ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Keterangan</TableHead>
                    <TableHead>Nominal</TableHead>
                    <TableHead>Tanggal</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {(recentExpenses.data as RecentExpense[]).map((expense) => (
                    <TableRow key={expense.id}>
                      <TableCell className="max-w-[150px] truncate text-xs font-medium">
                        {expense.keterangan ?? '-'}
                      </TableCell>
                      <TableCell className="text-xs font-semibold">{formatCurrency(expense.amount)}</TableCell>
                      <TableCell className="text-xs text-muted-foreground">{formatDateTime(expense.tanggal)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          ) : (
            <EmptyState label="Belum ada pengeluaran." />
          )}
        </DetailSection>
      </div>

      {/* Row 5: Cashbook Entries */}
      <DetailSection
        title="Buku Kas Terbaru"
        description="Snapshot arus kas terbaru"
      >
        {(recentCashbook.data as CashbookEntry[] | null)?.length ? (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Tanggal</TableHead>
                  <TableHead>Tipe</TableHead>
                  <TableHead>Sumber</TableHead>
                  <TableHead>Nominal</TableHead>
                  <TableHead>Saldo Setelah</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {(recentCashbook.data as CashbookEntry[]).map((entry) => (
                  <TableRow key={entry.id}>
                    <TableCell className="text-xs">{formatDateTime(entry.tanggal)}</TableCell>
                    <TableCell className="capitalize text-xs font-medium">{entry.tipe}</TableCell>
                    <TableCell className="capitalize text-xs">{entry.sumber}</TableCell>
                    <TableCell className="text-xs font-semibold">{formatCurrency(entry.amount)}</TableCell>
                    <TableCell className="text-xs font-semibold text-brand">{formatCurrency(entry.saldo_setelah)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        ) : (
          <EmptyState label="Belum ada entri buku kas." />
        )}
      </DetailSection>
    </div>
  );
}
