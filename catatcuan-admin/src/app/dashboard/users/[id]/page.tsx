import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  Boxes,
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
  sumNumericValues,
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
import { UserStatusActions } from '@/components/admin/user-status-actions';

interface UserRecord {
  id: string;
  phone_number: string;
  status: string;
  created_at: string;
  updated_at: string | null;
  last_login_at: string | null;
}

interface WarungRecord {
  id: string;
  nama_warung: string | null;
  nama_pemilik: string | null;
  phone: string | null;
  alamat: string | null;
  saldo_awal: number | string | null;
  created_at: string;
  updated_at: string | null;
}

interface RecentSale {
  id: string;
  warung_id: string;
  invoice_no: string | null;
  total_amount: number | string;
  payment_method: string;
  tanggal: string;
}

interface RecentExpense {
  id: string;
  warung_id: string;
  amount: number | string;
  keterangan: string | null;
  tanggal: string;
}

function EmptyState({ label }: { label: string }) {
  return (
    <div className="flex min-h-36 items-center justify-center rounded-xl border border-dashed border-border/70 bg-muted/20 px-6 text-center">
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  );
}

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();

  const userQuery = await supabase
    .from('USERS')
    .select('id, phone_number, status, created_at, updated_at, last_login_at')
    .eq('id', id)
    .maybeSingle();

  const user = userQuery.data as UserRecord | null;
  const userError = userQuery.error;

  if (userError) {
    throw new Error(userError.message);
  }

  if (!user) {
    notFound();
  }

  const warungsQuery = await supabase
    .from('WARUNG')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false });

  const warungs = warungsQuery.data;
  const warungsError = warungsQuery.error;

  if (warungsError) {
    throw new Error(warungsError.message);
  }

  const userWarungs = (warungs ?? []) as WarungRecord[];
  const warungIds = userWarungs.map((warung) => warung.id);
  const warungNameById = new Map(
    userWarungs.map((warung) => [warung.id, warung.nama_warung ?? 'Warung']),
  );

  const [
    productCount,
    customerCount,
    saleCount,
    expenseCount,
    activeDebtCount,
    recentSales,
    recentExpenses,
  ] = warungIds.length
    ? await Promise.all([
        supabase
          .from('PRODUK')
          .select('*', { count: 'exact', head: true })
          .in('warung_id', warungIds)
          .eq('is_active', true),
        supabase
          .from('PELANGGAN')
          .select('*', { count: 'exact', head: true })
          .in('warung_id', warungIds),
        supabase
          .from('PENJUALAN')
          .select('*', { count: 'exact', head: true })
          .in('warung_id', warungIds),
        supabase
          .from('PENGELUARAN')
          .select('*', { count: 'exact', head: true })
          .in('warung_id', warungIds),
        supabase
          .from('HUTANG')
          .select('*', { count: 'exact', head: true })
          .in('warung_id', warungIds)
          .in('status', ['belum_lunas', 'lewat_jatuh_tempo']),
        supabase
          .from('PENJUALAN')
          .select('id, warung_id, invoice_no, total_amount, payment_method, tanggal')
          .in('warung_id', warungIds)
          .order('tanggal', { ascending: false })
          .limit(5),
        supabase
          .from('PENGELUARAN')
          .select('id, warung_id, amount, keterangan, tanggal')
          .in('warung_id', warungIds)
          .order('tanggal', { ascending: false })
          .limit(5),
      ])
    : [
        { count: 0 },
        { count: 0 },
        { count: 0 },
        { count: 0 },
        { count: 0 },
        { data: [] },
        { data: [] },
      ];

  const displayName =
    userWarungs.find((warung) => warung.nama_pemilik)?.nama_pemilik ??
    `User ${user.phone_number}`;
  const totalSaldoAwal = sumNumericValues(
    userWarungs.map((warung) => warung.saldo_awal),
  );

  return (
    <div className="space-y-6">
      <DetailPageHeader
        backHref="/dashboard/users"
        backLabel="Kembali ke daftar"
        title="Detail User"
        description="Pantau status akun, warung terhubung, dan aktivitas terbaru dari pemilik warung."
      />

      {/* Row 1: Hero & Status Monitoring */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <DetailHeroCard
            icon={UserCircle2}
            title={displayName}
            subtitle={`No. HP ${user.phone_number}`}
            badges={
              <>
                <UserStatusBadge status={user.status} />
                <Badge variant="outline">
                  {userWarungs.length > 0
                    ? `${formatNumber(userWarungs.length)} warung`
                    : 'Belum punya warung'}
                </Badge>
              </>
            }
            metadata={
              <div className="flex flex-wrap gap-x-6 gap-y-2">
                <span className="flex items-center gap-1.5"><Badge variant="secondary" className="font-mono text-[10px] uppercase tracking-wider">ID</Badge> {formatShortId(user.id)}</span>
                <span>Terdaftar {formatDate(user.created_at)}</span>
                <span>Terakhir masuk {formatDateTime(user.last_login_at)}</span>
              </div>
            }
          />
        </div>
        <div className="lg:col-span-1">
          <DetailSection
            title="Kontrol Akun"
            description="Status operasional user"
            className="h-full"
          >
            <div className="space-y-4">
              <UserStatusActions userId={user.id} currentStatus={user.status} />
              <div className="rounded-xl bg-muted/50 p-3 text-xs text-muted-foreground">
                <p>Status `aktif` mengizinkan login aplikasi mobile.</p>
              </div>
            </div>
          </DetailSection>
        </div>
      </div>

      {/* Row 2: Main Stats Grid (Bento Style) */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <DetailStatCard
          label="Total Warung"
          value={formatNumber(userWarungs.length)}
          description="Warung terhubung"
          icon={Store}
        />
        <DetailStatCard
          label="Produk Aktif"
          value={formatNumber(productCount.count ?? 0)}
          description="Seluruh warung"
          icon={Boxes}
          accentClassName="border-blue-500/20 bg-blue-500/10 text-blue-500"
        />
        <DetailStatCard
          label="Pelanggan"
          value={formatNumber(customerCount.count ?? 0)}
          description="Tersimpan"
          icon={Users}
          accentClassName="border-violet-500/20 bg-violet-500/10 text-violet-500"
        />
        <DetailStatCard
          label="Transaksi"
          value={formatNumber(saleCount.count ?? 0)}
          description="Penjualan tercatat"
          icon={ShoppingCart}
          accentClassName="border-amber-500/20 bg-amber-500/10 text-amber-500"
        />
        <DetailStatCard
          label="Pengeluaran"
          value={formatNumber(expenseCount.count ?? 0)}
          description="Dibukukan"
          icon={Receipt}
          accentClassName="border-rose-500/20 bg-rose-500/10 text-rose-500"
        />
        <DetailStatCard
          label="Saldo Awal"
          value={formatCurrency(totalSaldoAwal)}
          description="Akumulasi modal"
          icon={Wallet}
          accentClassName="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
        />
      </div>

      {/* Row 3: Profile & Warung List */}
      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-1">
          <DetailSection
            title="Profil Akun"
            description="Informasi identitas user"
            className="h-full"
          >
            <DetailInfoGrid
              items={[
                {
                  label: 'Nama Pemilik',
                  value: displayName,
                },
                {
                  label: 'No. Telepon',
                  value: user.phone_number,
                },
                {
                  label: 'Hutang Aktif',
                  value: (
                    <span className="text-rose-500 font-bold">
                      {formatNumber(activeDebtCount.count ?? 0)}
                    </span>
                  ),
                },
                {
                  label: 'Login Terakhir',
                  value: formatDateTime(user.last_login_at),
                },
              ]}
            />
            {userWarungs.length > 0 && (
              <Button variant="outline" size="sm" className="mt-6 w-full" asChild>
                <Link href={`/dashboard/warungs/${userWarungs[0].id}`}>
                  <Store className="h-4 w-4" />
                  Buka Warung Terbaru
                </Link>
              </Button>
            )}
          </DetailSection>
        </div>

        <div className="lg:col-span-2">
          <DetailSection
            title="Warung Terhubung"
            description="Daftar warung yang dimiliki user ini"
            className="h-full"
          >
            {userWarungs.length === 0 ? (
              <EmptyState label="User ini belum menyelesaikan setup warung." />
            ) : (
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nama Warung</TableHead>
                      <TableHead>No. Telepon</TableHead>
                      <TableHead>Saldo Awal</TableHead>
                      <TableHead className="text-right">Aksi</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {userWarungs.map((warung) => (
                      <TableRow key={warung.id}>
                        <TableCell className="font-medium">
                          {warung.nama_warung ?? '-'}
                        </TableCell>
                        <TableCell className="font-mono text-sm">
                          {warung.phone ?? user.phone_number}
                        </TableCell>
                        <TableCell>{formatCurrency(warung.saldo_awal)}</TableCell>
                        <TableCell className="text-right">
                          <Button variant="ghost" size="sm" asChild>
                            <Link href={`/dashboard/warungs/${warung.id}`}>
                              Detail
                            </Link>
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </DetailSection>
        </div>
      </div>

      {/* Row 4: Activities */}
      <div className="grid gap-6 lg:grid-cols-2">
        <DetailSection
          title="Penjualan Terbaru"
          description="Ringkasan transaksi terakhir"
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
          description="Pantau pengeluaran terakhir"
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
    </div>
  );
}
