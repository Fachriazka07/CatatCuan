'use client';

import { useEffect, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import {
  Users,
  Store,
  DollarSign,
  TrendingUp,
} from 'lucide-react';
import { StatCard } from '@/components/admin/dashboard/dashboard-stats';
import { GrowthChart } from '@/components/admin/dashboard/growth-chart';
import { ActivityLog } from '@/components/admin/dashboard/activity-log';
import { MasterDataChart } from '@/components/admin/dashboard/master-data-chart';
import { UserStatusChart } from '@/components/admin/dashboard/user-status-chart';
import { format, subDays, startOfDay } from 'date-fns';
import { motion } from 'framer-motion';

async function getDashboardData() {
  const supabase = createClient();

  // Basic stats & counts
  const [usersRes, warungRes, masterKategoriRes, masterSatuanRes, logsRes, salesRes] = await Promise.all([
    supabase.from('USERS').select('created_at, status', { count: 'exact' }),
    supabase.from('WARUNG').select('created_at', { count: 'exact' }),
    supabase.from('MASTER_KATEGORI_PRODUK').select('id', { count: 'exact' }),
    supabase.from('MASTER_SATUAN').select('id', { count: 'exact' }),
    supabase.from('SYSTEM_LOGS').select('*').order('created_at', { ascending: false }).limit(6),
    supabase.from('PENJUALAN').select('total_amount'),
  ]);

  const totalUsers = usersRes.count ?? 0;
  const totalWarung = warungRes.count ?? 0;
  const totalMasterKategori = masterKategoriRes.count ?? 0;
  const totalMasterSatuan = masterSatuanRes.count ?? 0;
  const recentLogs = logsRes.data ?? [];
  const totalSalesVolume = salesRes.data?.reduce((acc, curr) => acc + Number(curr.total_amount), 0) ?? 0;

  // Process User Status Distribution
  const statusCounts = {
    active: 0,
    inactive: 0,
    suspended: 0,
  };
  usersRes.data?.forEach((u) => {
    const status = (u.status as keyof typeof statusCounts) || 'active';
    statusCounts[status]++;
  });

  const userStatusData = [
    { status: 'Aktif', count: statusCounts.active, color: '#13b158' },
    { status: 'Inaktif', count: statusCounts.inactive, color: '#9ca3af' },
    { status: 'Suspended', count: statusCounts.suspended, color: '#dc2626' },
  ];

  // Process growth data (Last 7 days)
  const last7Days = Array.from({ length: 7 }, (_, i) => {
    const date = subDays(new Date(), i);
    return {
      date: format(date, 'dd/MM'),
      fullDate: startOfDay(date),
      users: 0,
      warung: 0,
    };
  }).reverse();

  usersRes.data?.forEach((u) => {
    const uDate = startOfDay(new Date(u.created_at));
    const dayData = last7Days.find((d) => d.fullDate.getTime() === uDate.getTime());
    if (dayData) dayData.users++;
  });

  warungRes.data?.forEach((w) => {
    const wDate = startOfDay(new Date(w.created_at));
    const dayData = last7Days.find((d) => d.fullDate.getTime() === wDate.getTime());
    if (dayData) dayData.warung++;
  });

  return {
    stats: {
      totalUsers,
      totalWarung,
      totalSalesVolume,
      usersGrowth: { value: 12, isPositive: true },
      warungGrowth: { value: 8, isPositive: true },
    },
    recentLogs,
    growthData: last7Days,
    userStatusData,
    masterData: [
      { name: 'Kategori', count: totalMasterKategori, color: '#13b158' },
      { name: 'Satuan', count: totalMasterSatuan, color: '#f8bd00' },
    ],
  };
}

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.3
    }
  }
};

const item = {
  hidden: { opacity: 0, y: 20 },
  show: { opacity: 1, y: 0 }
};

interface DashboardData {
  stats: {
    totalUsers: number;
    totalWarung: number;
    totalSalesVolume: number;
    usersGrowth: { value: number; isPositive: boolean };
    warungGrowth: { value: number; isPositive: boolean };
  };
  recentLogs: { id: string; action: string; created_at: string; details?: Record<string, unknown> }[];
  growthData: { date: string; fullDate: Date; users: number; warung: number }[];
  userStatusData: { status: string; count: number; color: string }[];
  masterData: { name: string; count: number; color: string }[];
}

export default function DashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);

  useEffect(() => {
    getDashboardData().then(setData);
  }, []);

  if (!data) return (
    <div className="flex h-[80vh] items-center justify-center">
      <motion.div 
        animate={{ rotate: 360 }}
        transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
        className="h-10 w-10 border-4 border-brand border-t-transparent rounded-full"
      />
    </div>
  );

  return (
    <motion.div 
      variants={container}
      initial="hidden"
      animate="show"
      className="flex flex-col gap-6 pb-10"
    >
      <motion.div variants={item} className="flex flex-col gap-1">
        <h1 className="text-3xl font-black tracking-tight bg-gradient-to-r from-foreground via-foreground/80 to-foreground/40 bg-clip-text text-transparent">
          Dashboard Insights
        </h1>
        <p className="text-sm font-medium text-muted-foreground/60">
          Metrik pertumbuhan dan status operasional platform CatatCuan.
        </p>
      </motion.div>

      {/* Bento Grid */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-12">
        {/* KPI Cards */}
        <StatCard
          title="Total Pengguna"
          value={data.stats.totalUsers}
          description="Akun terdaftar"
          icon={Users}
          trend={data.stats.usersGrowth}
          className="lg:col-span-3"
          colorClass="bg-blue-500/10 text-blue-500"
        />
        <StatCard
          title="Total Warung"
          value={data.stats.totalWarung}
          description="Unit bisnis aktif"
          icon={Store}
          trend={data.stats.warungGrowth}
          className="lg:col-span-3"
          colorClass="bg-brand/10 text-brand"
        />
        <StatCard
          title="Volume Transaksi"
          value={data.stats.totalSalesVolume}
          description="Total penjualan global"
          icon={DollarSign}
          className="lg:col-span-3"
          colorClass="bg-brand-secondary/10 text-brand-secondary"
        />
        <StatCard
          title="Status Sistem"
          value="Stabil"
          description="Semua layanan operasional"
          icon={TrendingUp}
          className="lg:col-span-3"
          colorClass="bg-muted text-muted-foreground"
        />

        {/* Growth Chart */}
        <GrowthChart
          data={data.growthData}
          title="Trend Pertumbuhan"
          description="Pendaftaran 7 hari terakhir"
          className="lg:col-span-8"
        />
        
        {/* Activity Log */}
        <ActivityLog logs={data.recentLogs} className="lg:col-span-4" />

        {/* Master Data Donut Chart */}
        <MasterDataChart
          data={data.masterData}
          title="Distribusi Master Data"
          description="Sebaran kategori dan satuan global"
          className="lg:col-span-6"
        />

        {/* User Status Bar Chart */}
        <UserStatusChart 
          data={data.userStatusData} 
          className="lg:col-span-6" 
        />
      </div>
    </motion.div>
  );
}
