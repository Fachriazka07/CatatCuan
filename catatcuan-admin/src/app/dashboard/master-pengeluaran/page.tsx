'use client';

import { useState, useEffect } from 'react';
import { createClient } from '@/lib/supabase/client';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { 
  Wallet, 
  Plus, 
  Pencil, 
  Trash2, 
  RefreshCw, 
  Layers, 
  CheckCircle2,
  AlertCircle,
  ImageIcon,
  Tag
} from 'lucide-react';
import { toast } from 'sonner';
import { logAdminActivity } from '@/lib/admin-activity';
import { motion, AnimatePresence } from 'framer-motion';
import { cn } from '@/lib/utils';

interface MasterKategoriPengeluaran {
  id: string;
  nama_kategori: string;
  tipe: 'business' | 'personal';
  icon: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

const AVAILABLE_ICONS = [
  'Kesehatan.png',
  'LainnyaPribadi.png',
  'MakanDapur.png',
  'Pakaian.png',
  'Pendidikan.png',
  'Sedekah.png',
];

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
  hidden: { opacity: 0, y: 10 },
  show: { opacity: 1, y: 0 }
};

export default function MasterPengeluaranPage() {
  const [kategoris, setKategoris] = useState<MasterKategoriPengeluaran[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingKategori, setEditingKategori] = useState<MasterKategoriPengeluaran | null>(null);
  const [formData, setFormData] = useState({
    nama_kategori: '',
    tipe: 'business' as 'business' | 'personal',
    icon: 'LainnyaPribadi.png',
  });

  const supabase = createClient();

  async function fetchKategoris() {
    setLoading(true);
    const { data, error } = await supabase
      .from('MASTER_KATEGORI_PENGELUARAN')
      .select('*')
      .order('tipe', { ascending: false })
      .order('sort_order', { ascending: true });

    if (error) {
      toast.error('Gagal memuat data: ' + error.message);
    } else {
      setKategoris(data ?? []);
    }
    setLoading(false);
  }

  useEffect(() => {
    fetchKategoris();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function openCreateDialog() {
    setEditingKategori(null);
    setFormData({ nama_kategori: '', tipe: 'business', icon: 'LainnyaPribadi.png' });
    setDialogOpen(true);
  }

  function openEditDialog(kategori: MasterKategoriPengeluaran) {
    setEditingKategori(kategori);
    setFormData({
      nama_kategori: kategori.nama_kategori,
      tipe: kategori.tipe,
      icon: kategori.icon ?? 'LainnyaPribadi.png',
    });
    setDialogOpen(true);
  }

  async function handleSubmit() {
    if (!formData.nama_kategori.trim()) {
      toast.error('Nama kategori wajib diisi');
      return;
    }

    try {
      if (editingKategori) {
        const { error } = await supabase
          .from('MASTER_KATEGORI_PENGELUARAN')
          .update({
            nama_kategori: formData.nama_kategori.trim(),
            tipe: formData.tipe,
            icon: formData.icon.trim() || null,
          })
          .eq('id', editingKategori.id);

        if (error) throw error;
        
        await logAdminActivity(supabase, 'Memperbarui master kategori pengeluaran', {
          kategori_id: editingKategori.id,
          nama_kategori: formData.nama_kategori.trim(),
        });
        toast.success('Kategori pengeluaran diperbarui');
      } else {
        const { error } = await supabase.from('MASTER_KATEGORI_PENGELUARAN').insert({
          nama_kategori: formData.nama_kategori.trim(),
          tipe: formData.tipe,
          icon: formData.icon.trim() || null,
          sort_order: kategoris.length,
        });

        if (error) throw error;
        
        await logAdminActivity(supabase, 'Menambahkan master kategori pengeluaran', {
          nama_kategori: formData.nama_kategori.trim(),
        });
        toast.success('Kategori pengeluaran ditambahkan');
      }

      setDialogOpen(false);
      fetchKategoris();
    } catch (error: any) {
      toast.error('Terjadi kesalahan: ' + error.message);
    }
  }

  async function handleDelete(id: string) {
    const { error } = await supabase
      .from('MASTER_KATEGORI_PENGELUARAN')
      .update({ is_active: false })
      .eq('id', id);

    if (error) {
      toast.error('Gagal menonaktifkan: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Menonaktifkan master kategori pengeluaran', {
      kategori_id: id,
    });
    toast.success('Kategori dinonaktifkan');
    fetchKategoris();
  }

  async function toggleActive(kategori: MasterKategoriPengeluaran) {
    const { error } = await supabase
      .from('MASTER_KATEGORI_PENGELUARAN')
      .update({ is_active: !kategori.is_active })
      .eq('id', kategori.id);

    if (error) {
      toast.error('Gagal update status: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Mengubah status master kategori pengeluaran', {
      kategori_id: kategori.id,
      is_active: !kategori.is_active,
    });
    fetchKategoris();
  }

  return (
    <motion.div 
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6 pb-10"
    >
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-black tracking-tight bg-gradient-to-r from-foreground via-foreground/80 to-foreground/40 bg-clip-text text-transparent italic">
            Master Pengeluaran
          </h1>
          <p className="text-sm font-medium text-muted-foreground/60">
            Kelola kategori pengeluaran default untuk unit bisnis dan personal.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openCreateDialog} className="bg-brand hover:bg-brand-dark text-white font-bold rounded-xl shadow-lg shadow-brand/20 cursor-pointer active:scale-95 transition-all">
                <Plus className="mr-2 h-4 w-4" />
                Tambah Kategori
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl border-border/40 bg-card/90 backdrop-blur-xl max-w-md">
              <DialogHeader>
                <DialogTitle className="text-xl font-black italic">
                  {editingKategori ? 'Update Pengeluaran' : 'Kategori Baru'}
                </DialogTitle>
                <DialogDescription className="text-xs font-medium">
                  {editingKategori
                    ? 'Sesuaikan kategori pengeluaran yang sudah terdaftar.'
                    : 'Kategori pengeluaran ini akan muncul di semua akun warung baru.'}
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-5 py-6">
                <div className="space-y-2">
                  <Label htmlFor="nama" className="text-[10px] font-black uppercase tracking-widest opacity-70">Nama Kategori</Label>
                  <Input
                    id="nama"
                    value={formData.nama_kategori}
                    onChange={(e) =>
                      setFormData({ ...formData, nama_kategori: e.target.value })
                    }
                    placeholder="Contoh: Gaji Karyawan"
                    className="h-12 rounded-2xl border-border/40 bg-background/50 focus:ring-brand/20"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="tipe" className="text-[10px] font-black uppercase tracking-widest opacity-70">Tipe</Label>
                    <select
                      id="tipe"
                      className="flex h-12 w-full rounded-2xl border border-border/40 bg-background/50 px-4 py-2 text-sm focus:ring-2 focus:ring-brand/20 focus:outline-none appearance-none cursor-pointer font-medium"
                      value={formData.tipe}
                      onChange={(e) =>
                        setFormData({ ...formData, tipe: e.target.value as any })
                      }
                    >
                      <option value="business">Bisnis (Warung)</option>
                      <option value="personal">Pribadi (User)</option>
                    </select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="icon" className="text-[10px] font-black uppercase tracking-widest opacity-70">Icon</Label>
                    <select
                      id="icon"
                      className="flex h-12 w-full rounded-2xl border border-border/40 bg-background/50 px-4 py-2 text-sm focus:ring-2 focus:ring-brand/20 focus:outline-none appearance-none cursor-pointer font-medium"
                      value={formData.icon || 'LainnyaPribadi.png'}
                      onChange={(e) =>
                        setFormData({ ...formData, icon: e.target.value })
                      }
                    >
                      {AVAILABLE_ICONS.map(icon => (
                        <option key={icon} value={icon}>{icon.split('.')[0]}</option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>
              <DialogFooter className="gap-2 sm:gap-0">
                <Button
                  variant="ghost"
                  onClick={() => setDialogOpen(false)}
                  className="rounded-xl font-bold opacity-60 hover:opacity-100"
                >
                  Batal
                </Button>
                <Button onClick={handleSubmit} className="bg-brand text-white font-bold rounded-xl px-8">
                  {editingKategori ? 'Simpan Perubahan' : 'Buat Kategori'}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
          <Button variant="outline" size="icon" className="rounded-xl border-border/40 bg-card/40 backdrop-blur-md cursor-pointer active:rotate-180 transition-all duration-500" onClick={fetchKategoris}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Card className="overflow-hidden border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 rounded-3xl shadow-sm">
        <CardHeader className="border-b border-border/20 bg-muted/20 pb-4">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-brand-secondary/10 p-2.5 ring-1 ring-brand-secondary/20">
              <Wallet className="h-5 w-5 text-brand-secondary" />
            </div>
            <div>
              <CardTitle className="text-base font-bold tracking-tight">Katalog Pengeluaran ({kategoris.length})</CardTitle>
              <CardDescription className="text-[10px] uppercase tracking-widest font-semibold opacity-60">Expense presets</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-4">
              <motion.div 
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="h-10 w-10 border-4 border-brand border-t-transparent rounded-full"
              />
              <p className="text-xs font-bold text-muted-foreground animate-pulse uppercase tracking-widest">Sinkronisasi Data...</p>
            </div>
          ) : kategoris.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center gap-3">
              <div className="rounded-full bg-muted p-6 ring-1 ring-border/40 shadow-inner">
                <Tag className="h-10 w-10 text-muted-foreground/20" />
              </div>
              <div className="space-y-1">
                <p className="text-sm font-bold">Katalog Kosong</p>
                <p className="text-xs text-muted-foreground/60 max-w-[200px]">Belum ada kategori pengeluaran master yang terdaftar.</p>
              </div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/30 border-b border-border/40 hover:bg-muted/30">
                    <TableHead className="py-4 pl-6 text-[10px] font-black uppercase tracking-widest text-center w-20">Icon</TableHead>
                    <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Nama Kategori</TableHead>
                    <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest">Tipe</TableHead>
                    <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest text-center">Status</TableHead>
                    <TableHead className="py-4 pr-6 text-right"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <AnimatePresence mode="popLayout">
                    <motion.div 
                      variants={container}
                      initial="hidden"
                      animate="show"
                      className="contents"
                    >
                      {kategoris.map((kategori) => (
                        <motion.tr 
                          key={kategori.id}
                          variants={item}
                          className="group hover:bg-muted/20 border-b border-border/20 last:border-0 transition-colors"
                        >
                          <TableCell className="py-4 pl-6 text-center">
                            <div className="h-10 w-10 mx-auto rounded-xl bg-background shadow-sm border border-border/40 flex items-center justify-center font-bold text-[10px] text-muted-foreground group-hover:scale-110 transition-transform duration-300 overflow-hidden bg-muted/10">
                              {kategori.icon ? (
                                <span className="text-[8px] truncate px-1 text-center leading-tight opacity-60">{kategori.icon.split('.')[0]}</span>
                              ) : <ImageIcon className="h-4 w-4 opacity-20" />}
                            </div>
                          </TableCell>
                          <TableCell className="py-4">
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-bold tracking-tight">{kategori.nama_kategori}</span>
                              <Button 
                                variant="ghost" 
                                size="icon" 
                                onClick={() => openEditDialog(kategori)}
                                className="h-6 w-6 rounded-lg opacity-0 group-hover:opacity-100 transition-all hover:bg-brand/10 hover:text-brand"
                              >
                                <Pencil className="h-3 w-3" />
                              </Button>
                            </div>
                          </TableCell>
                          <TableCell className="py-4">
                            <Badge variant="outline" className={cn(
                              "text-[10px] font-bold uppercase border-none px-0",
                              kategori.tipe === 'business' ? "text-blue-500" : "text-amber-500"
                            )}>
                              {kategori.tipe === 'business' ? 'Bisnis' : 'Pribadi'}
                            </Badge>
                          </TableCell>
                          <TableCell className="py-4 text-center">
                            <button 
                              onClick={() => toggleActive(kategori)}
                              className="cursor-pointer active:scale-95 transition-transform"
                            >
                              {kategori.is_active ? (
                                <Badge className="bg-brand/10 text-brand border-brand/20 hover:bg-brand/20 transition-colors">
                                  Aktif
                                </Badge>
                              ) : (
                                <Badge variant="secondary" className="opacity-60">
                                  Nonaktif
                                </Badge>
                              )}
                            </button>
                          </TableCell>
                          <TableCell className="py-4 pr-6 text-right">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                if (confirm(`Yakin ingin menonaktifkan "${kategori.nama_kategori}"?`)) {
                                  handleDelete(kategori.id);
                                }
                              }}
                              className="h-8 w-8 rounded-lg text-muted-foreground/40 hover:text-destructive hover:bg-destructive/10 transition-colors"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </TableCell>
                        </motion.tr>
                      ))}
                    </motion.div>
                  </AnimatePresence>
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="rounded-2xl border border-blue-500/20 bg-blue-500/5 p-4 flex gap-3"
      >
        <AlertCircle className="h-5 w-5 text-blue-500 shrink-0" />
        <div className="space-y-1">
          <p className="text-xs font-bold text-blue-600 dark:text-blue-400">Penting</p>
          <p className="text-[11px] text-blue-600/70 dark:text-blue-400/70 leading-relaxed">
            Data master ini akan menjadi pilihan standar bagi user baru. Perubahan pada tipe kategori akan mempengaruhi bagaimana data dikelompokkan dalam laporan keuangan user.
          </p>
        </div>
      </motion.div>
    </motion.div>
  );
}
