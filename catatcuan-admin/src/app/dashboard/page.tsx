import { createClient } from '@/lib/supabase/server';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Users, Store, FolderTree, Activity } from 'lucide-react';

async function getStats() {
  const supabase = await createClient();

  const [usersRes, warungRes, kategoriRes, logsRes] = await Promise.all([
    supabase.from('USERS').select('*', { count: 'exact', head: true }),
    supabase.from('WARUNG').select('*', { count: 'exact', head: true }),
    supabase
      .from('MASTER_KATEGORI_PRODUK')
      .select('*', { count: 'exact', head: true }),
    supabase
      .from('SYSTEM_LOGS')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5),
  ]);

  return {
    totalUsers: usersRes.count ?? 0,
    totalWarung: warungRes.count ?? 0,
    totalKategori: kategoriRes.count ?? 0,
    recentLogs: logsRes.data ?? [],
  };
}

export default async function DashboardPage() {
  const stats = await getStats();

  const statCards = [
    {
      title: 'Total User',
      value: stats.totalUsers,
      description: 'User terdaftar',
      icon: Users,
      color: 'text-blue-500 bg-blue-500/10',
    },
    {
      title: 'Total Warung',
      value: stats.totalWarung,
      description: 'Warung aktif',
      icon: Store,
      color: 'text-brand bg-brand/10',
    },
    {
      title: 'Master Kategori',
      value: stats.totalKategori,
      description: 'Kategori produk',
      icon: FolderTree,
      color: 'text-brand-secondary bg-brand-secondary/10',
    },
    {
      title: 'Aktivitas Terbaru',
      value: stats.recentLogs.length,
      description: 'Log terakhir',
      icon: Activity,
      color: 'text-muted-foreground bg-muted',
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="mt-1 text-muted-foreground">
          Monitoring aktivitas platform CatatCuan
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {stat.title}
              </CardTitle>
              <div className={`rounded-lg p-2 ${stat.color}`}>
                <stat.icon className="h-4 w-4" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{stat.value}</div>
              <CardDescription className="mt-1 text-xs">
                {stat.description}
              </CardDescription>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle>Aktivitas Terbaru</CardTitle>
          <CardDescription>
            Log 5 aktivitas terakhir dari sistem
          </CardDescription>
        </CardHeader>
        <CardContent>
          {stats.recentLogs.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <Activity className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                Belum ada aktivitas tercatat
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {stats.recentLogs.map(
                (log: {
                  id: string;
                  action: string;
                  created_at: string;
                }) => (
                  <div
                    key={log.id}
                    className="flex items-center justify-between rounded-lg border p-3"
                  >
                    <span className="text-sm">{log.action}</span>
                    <span className="text-xs text-muted-foreground">
                      {new Date(log.created_at).toLocaleString('id-ID')}
                    </span>
                  </div>
                ),
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
