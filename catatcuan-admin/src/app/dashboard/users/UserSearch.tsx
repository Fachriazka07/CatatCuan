'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { Input } from '@/components/ui/input';
import {
  Card,
  CardContent,
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { 
  Users, 
  Store, 
  Search, 
  Filter, 
  UserCheck, 
  UserX,
  RefreshCw
} from 'lucide-react';
import { UserStatusBadge } from '@/components/admin/status-badge';
import { motion, AnimatePresence } from 'framer-motion';
import { StatCard } from '@/components/admin/dashboard/dashboard-stats';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel, 
  DropdownMenuSeparator,
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu';
import { cn } from '@/lib/utils';

interface User {
  id: string;
  phone_number: string;
  status: string;
  created_at: string;
  last_login_at: string | null;
  WARUNG: { nama_pemilik: string | null }[];
}

interface Warung {
  id: string;
  user_id: string;
  nama_warung: string;
  nama_pemilik: string | null;
  phone: string | null;
  alamat: string | null;
  created_at: string;
  USERS: { phone_number: string } | null;
}

interface UserSearchProps {
  users: User[];
  warungs: Warung[];
}

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
    }
  }
};

const item = {
  hidden: { opacity: 0, x: -10 },
  show: { opacity: 1, x: 0 }
};

export default function UserSearch({ users, warungs }: UserSearchProps) {
  const router = useRouter();
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState('users');
  const [statusFilter, setStatusFilter] = useState<string | 'all'>('all');

  const query = search.trim().toLowerCase();

  // Stats calculation
  const stats = useMemo(() => {
    const active = users.filter(u => u.status === 'active').length;
    const inactive = users.filter(u => u.status === 'inactive').length;
    const suspended = users.filter(u => u.status === 'suspended').length;
    return { active, inactive, suspended };
  }, [users]);

  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const phoneMatch = u.phone_number.toLowerCase().includes(query);
      const nameMatch = u.WARUNG?.[0]?.nama_pemilik?.toLowerCase().includes(query);
      const statusMatch = statusFilter === 'all' || u.status === statusFilter;
      return (phoneMatch || nameMatch) && statusMatch;
    });
  }, [users, query, statusFilter]);

  const filteredWarungs = useMemo(() => {
    return warungs.filter(
      (w) =>
        w.phone?.toLowerCase().includes(query) ||
        w.USERS?.phone_number.toLowerCase().includes(query) ||
        w.nama_warung?.toLowerCase().includes(query) ||
        w.nama_pemilik?.toLowerCase().includes(query),
    );
  }, [warungs, query]);

  return (
    <motion.div 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6 pb-10"
    >
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight bg-gradient-to-r from-foreground via-foreground/80 to-foreground/40 bg-clip-text text-transparent">
            Monitoring Entitas
          </h1>
          <p className="text-sm font-medium text-muted-foreground/60">
            Pantau user dan warung yang aktif di aplikasi mobile CatatCuan.
          </p>
        </div>
        <div className="flex items-center gap-2">
           <Button variant="outline" size="icon" className="rounded-xl border-border/40 bg-card/40 backdrop-blur-md cursor-pointer active:rotate-180 transition-all duration-500" onClick={() => window.location.reload()}>
             <RefreshCw className="h-4 w-4" />
           </Button>
        </div>
      </div>

      {/* Stats Quick View */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard
          title="Total User"
          value={users.length}
          description="Seluruh platform"
          icon={Users}
          className="lg:col-span-1"
          colorClass="bg-blue-500/10 text-blue-500"
        />
        <StatCard
          title="User Aktif"
          value={stats.active}
          description="Akun tervalidasi"
          icon={UserCheck}
          className="lg:col-span-1"
          colorClass="bg-brand/10 text-brand"
        />
        <StatCard
          title="Suspended"
          value={stats.suspended}
          description="Butuh tindakan"
          icon={UserX}
          className="lg:col-span-1"
          colorClass="bg-destructive/10 text-destructive"
        />
        <StatCard
          title="Total Warung"
          value={warungs.length}
          description="Unit operasional"
          icon={Store}
          className="lg:col-span-1"
          colorClass="bg-brand-secondary/10 text-brand-secondary"
        />
      </div>

      <Tabs defaultValue="users" className="w-full" onValueChange={setActiveTab}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <TabsList className="h-11 rounded-2xl bg-muted/50 p-1 border border-border/40 backdrop-blur-md">
            <TabsTrigger value="users" className="rounded-xl px-6 font-bold data-[state=active]:bg-background data-[state=active]:shadow-sm">
              <Users className="mr-2 h-4 w-4" />
              User ({users.length})
            </TabsTrigger>
            <TabsTrigger value="warung" className="rounded-xl px-6 font-bold data-[state=active]:bg-background data-[state=active]:shadow-sm">
              <Store className="mr-2 h-4 w-4" />
              Warung ({warungs.length})
            </TabsTrigger>
          </TabsList>

          <div className="flex items-center gap-2">
            <div className="relative flex-1 sm:w-80">
              <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground/50" />
              <Input
                placeholder={activeTab === 'users' ? "Cari user atau no. hp..." : "Cari warung atau pemilik..."}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10 h-11 rounded-2xl border-border/40 bg-card/40 backdrop-blur-md focus:ring-brand/20 transition-all"
              />
            </div>
            {activeTab === 'users' && (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="icon" className="h-11 w-11 rounded-2xl border-border/40 bg-card/40 backdrop-blur-md">
                    <Filter className={cn("h-4 w-4", statusFilter !== 'all' && "text-brand")} />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-48 rounded-2xl p-2 border-border/40 bg-card/90 backdrop-blur-xl">
                  <DropdownMenuLabel className="text-[10px] font-black uppercase tracking-widest opacity-50 px-2 py-1.5">Filter Status</DropdownMenuLabel>
                  <DropdownMenuSeparator className="bg-border/40" />
                  <DropdownMenuItem onClick={() => setStatusFilter('all')} className="rounded-xl cursor-pointer">Semua Status</DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setStatusFilter('active')} className="rounded-xl cursor-pointer text-brand">Hanya Aktif</DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setStatusFilter('inactive')} className="rounded-xl cursor-pointer">Hanya Inaktif</DropdownMenuItem>
                  <DropdownMenuItem onClick={() => setStatusFilter('suspended')} className="rounded-xl cursor-pointer text-destructive">Hanya Suspended</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            )}
          </div>
        </div>

        <div className="mt-6">
          <TabsContent value="users" className="m-0 border-none outline-none">
            <Card className="overflow-hidden border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 rounded-3xl shadow-sm">
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-muted/30 border-b border-border/40 hover:bg-muted/30">
                      <TableHead className="py-4 pl-6 text-[10px] font-black uppercase tracking-widest">Pemilik</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">No. Telepon</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Status</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Terdaftar</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Aktivitas</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    <AnimatePresence mode="popLayout">
                      {filteredUsers.length === 0 ? (
                        <motion.tr
                          key="empty-users"
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          exit={{ opacity: 0 }}
                        >
                          <TableCell colSpan={5} className="py-20 text-center">
                            <div className="flex flex-col items-center gap-3">
                              <div className="rounded-full bg-muted p-4 ring-1 ring-border/40 shadow-inner">
                                <Users className="h-8 w-8 text-muted-foreground/20" />
                              </div>
                              <div className="space-y-1">
                                <p className="text-sm font-bold">Data tidak ditemukan</p>
                                <p className="text-xs text-muted-foreground/60">Coba ubah filter atau kata kunci pencarian Anda.</p>
                              </div>
                            </div>
                          </TableCell>
                        </motion.tr>
                      ) : (
                        <motion.div
                          key="user-list"
                          variants={container}
                          initial="hidden"
                          animate="show"
                          className="contents"
                          layout
                        >
                          {filteredUsers.map((user) => (
                            <motion.tr
                              key={user.id}
                              variants={item}
                              className="group cursor-pointer hover:bg-muted/20 border-b border-border/20 last:border-0 transition-colors"
                              onClick={() => router.push(`/dashboard/users/${user.id}`)}
                              onKeyDown={(event) => {
                                if (event.key === 'Enter' || event.key === ' ') {
                                  event.preventDefault();
                                  router.push(`/dashboard/users/${user.id}`);
                                }
                              }}
                              tabIndex={0}
                            >
                              <TableCell className="py-4 pl-6">
                                <div className="flex items-center gap-3">
                                  <div className="h-9 w-9 rounded-full bg-gradient-to-br from-blue-500/10 to-brand/10 border border-blue-500/20 flex items-center justify-center font-black text-[10px] text-blue-600 dark:text-blue-400">
                                    {user.WARUNG?.[0]?.nama_pemilik?.charAt(0) ?? 'U'}
                                  </div>
                                  <span className="text-sm font-bold tracking-tight">{user.WARUNG?.[0]?.nama_pemilik ?? '-'}</span>
                                </div>
                              </TableCell>

                              <TableCell className="py-4">
                                <span className="font-mono text-xs font-medium text-muted-foreground group-hover:text-foreground transition-colors">{user.phone_number}</span>
                              </TableCell>
                              <TableCell className="py-4">
                                <UserStatusBadge status={user.status} />
                              </TableCell>
                              <TableCell className="py-4">
                                <span className="text-xs font-medium text-muted-foreground/60">
                                  {new Date(user.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                                </span>
                              </TableCell>
                              <TableCell className="py-4">
                                <div className="flex flex-col gap-0.5">
                                  <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground/40">Terakhir Login</span>
                                  <span className="text-xs font-medium">
                                    {user.last_login_at
                                      ? new Date(user.last_login_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })
                                      : 'Belum pernah'}
                                  </span>
                                </div>
                              </TableCell>
                            </motion.tr>
                          ))}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="warung" className="m-0 border-none outline-none">
            <Card className="overflow-hidden border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 rounded-3xl shadow-sm">
              <CardContent className="p-0">
                <Table>
                  <TableHeader>
                    <TableRow className="bg-muted/30 border-b border-border/40 hover:bg-muted/30">
                      <TableHead className="py-4 pl-6 text-[10px] font-black uppercase tracking-widest">Warung</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Pemilik</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Kontak</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Alamat</TableHead>
                      <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Terdaftar</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    <AnimatePresence mode="popLayout">
                      {filteredWarungs.length === 0 ? (
                        <motion.tr
                          key="empty-warung"
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                        >
                          <TableCell colSpan={5} className="py-20 text-center">
                            <div className="flex flex-col items-center gap-3">
                              <div className="rounded-full bg-muted p-4 ring-1 ring-border/40 shadow-inner">
                                <Store className="h-8 w-8 text-muted-foreground/20" />
                              </div>
                              <p className="text-sm font-bold">Tidak ada warung ditemukan</p>
                            </div>
                          </TableCell>
                        </motion.tr>
                      ) : (
                        <motion.div
                          key="warung-list"
                          variants={container}
                          initial="hidden"
                          animate="show"
                          className="contents"
                          layout
                        >
                          {filteredWarungs.map((warung) => (
                            <motion.tr
                              key={warung.id}
                              variants={item}
                              className="group cursor-pointer hover:bg-muted/20 border-b border-border/20 last:border-0 transition-colors"
                              onClick={() => router.push(`/dashboard/warungs/${warung.id}`)}
                              onKeyDown={(event) => {
                                if (event.key === 'Enter' || event.key === ' ') {
                                  event.preventDefault();
                                  router.push(`/dashboard/warungs/${warung.id}`);
                                }
                              }}
                              tabIndex={0}
                            >
                              <TableCell className="py-4 pl-6">
                                <div className="flex items-center gap-3">
                                  <div className="h-9 w-9 rounded-xl bg-gradient-to-br from-brand/10 to-brand-secondary/10 border border-brand/20 flex items-center justify-center">
                                    <Store className="h-4 w-4 text-brand" />
                                  </div>
                                  <div className="flex flex-col">
                                    <span className="text-sm font-bold tracking-tight">{warung.nama_warung}</span>
                                    <span className="text-[10px] font-medium text-muted-foreground/60 truncate max-w-[140px] italic">ID: {warung.id.split('-')[0]}</span>
                                  </div>
                                </div>
                              </TableCell>
                              <TableCell className="py-4">
                                <span className="text-sm font-medium">{warung.nama_pemilik ?? '-'}</span>
                              </TableCell>
                              <TableCell className="py-4">
                                <span className="font-mono text-xs text-muted-foreground">{warung.phone ?? warung.USERS?.phone_number ?? '-'}</span>
                              </TableCell>
                              <TableCell className="py-4">
                                <span className="text-xs text-muted-foreground/70 truncate max-w-[200px] block" title={warung.alamat ?? '-'}>
                                  {warung.alamat ?? '-'}
                                </span>
                              </TableCell>
                              <TableCell className="py-4">
                                <span className="text-xs font-medium text-muted-foreground/60">
                                  {new Date(warung.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })}
                                </span>
                              </TableCell>
                            </motion.tr>
                          ))}
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          </TabsContent>
        </div>
      </Tabs>
    </motion.div>
  );
}
