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
  Ruler, 
  Plus, 
  Pencil, 
  Trash2, 
  RefreshCw, 
  AlertCircle,
  Hash
} from 'lucide-react';
import { toast } from 'sonner';
import { logAdminActivity } from '@/lib/admin-activity';
import { motion, AnimatePresence } from 'framer-motion';

interface Satuan {
  id: string;
  nama_satuan: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) {
    return error.message;
  }

  return 'Terjadi kesalahan yang tidak diketahui';
}

const item = {
  hidden: { opacity: 0, y: 10 },
  show: { opacity: 1, y: 0 }
};

export default function MasterSatuanPage() {
  const [satuans, setSatuans] = useState<Satuan[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingSatuan, setEditingSatuan] = useState<Satuan | null>(null);
  const [formData, setFormData] = useState({
    nama_satuan: '',
  });

  const supabase = createClient();

  async function fetchSatuans() {
    setLoading(true);
    const { data, error } = await supabase
      .from('MASTER_SATUAN')
      .select('*')
      .order('sort_order', { ascending: true });

    if (error) {
      toast.error('Gagal memuat data: ' + error.message);
    } else {
      setSatuans(data ?? []);
    }
    setLoading(false);
  }

  useEffect(() => {
    fetchSatuans();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function openCreateDialog() {
    setEditingSatuan(null);
    setFormData({ nama_satuan: '' });
    setDialogOpen(true);
  }

  function openEditDialog(satuan: Satuan) {
    setEditingSatuan(satuan);
    setFormData({
      nama_satuan: satuan.nama_satuan,
    });
    setDialogOpen(true);
  }

  async function handleSubmit() {
    if (!formData.nama_satuan.trim()) {
      toast.error('Nama satuan wajib diisi');
      return;
    }

    try {
      if (editingSatuan) {
        const { error } = await supabase
          .from('MASTER_SATUAN')
          .update({
            nama_satuan: formData.nama_satuan.trim().toUpperCase(),
          })
          .eq('id', editingSatuan.id);

        if (error) throw error;
        
        await logAdminActivity(supabase, 'Memperbarui master satuan', {
          satuan_id: editingSatuan.id,
          nama_satuan: formData.nama_satuan.trim().toUpperCase(),
        });
        toast.success('Satuan berhasil diperbarui');
      } else {
        const { error } = await supabase.from('MASTER_SATUAN').insert({
          nama_satuan: formData.nama_satuan.trim().toUpperCase(),
          sort_order: satuans.length,
        });

        if (error) throw error;
        
        await logAdminActivity(supabase, 'Menambahkan master satuan', {
          nama_satuan: formData.nama_satuan.trim().toUpperCase(),
        });
        toast.success('Satuan baru ditambahkan');
      }

      setDialogOpen(false);
      fetchSatuans();
    } catch (error: unknown) {
      toast.error('Terjadi kesalahan: ' + getErrorMessage(error));
    }
  }

  async function handleDelete(id: string) {
    const { error } = await supabase
      .from('MASTER_SATUAN')
      .update({ is_active: false })
      .eq('id', id);

    if (error) {
      toast.error('Gagal menonaktifkan: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Menonaktifkan master satuan', {
      satuan_id: id,
    });
    toast.success('Satuan dinonaktifkan');
    fetchSatuans();
  }

  async function toggleActive(satuan: Satuan) {
    const { error } = await supabase
      .from('MASTER_SATUAN')
      .update({ is_active: !satuan.is_active })
      .eq('id', satuan.id);

    if (error) {
      toast.error('Gagal update status: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Mengubah status master satuan', {
      satuan_id: satuan.id,
      is_active: !satuan.is_active,
    });
    fetchSatuans();
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
            Master Satuan
          </h1>
          <p className="text-sm font-medium text-muted-foreground/60">
            Kelola unit satuan default (PCS, KG, dll) untuk seluruh warung.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={openCreateDialog} className="bg-brand hover:bg-brand-dark text-white font-bold rounded-xl shadow-lg shadow-brand/20 cursor-pointer active:scale-95 transition-all">
                <Plus className="mr-2 h-4 w-4" />
                Tambah Satuan
              </Button>
            </DialogTrigger>
            <DialogContent className="rounded-3xl border-border/40 bg-card/90 backdrop-blur-xl max-w-md">
              <DialogHeader>
                <DialogTitle className="text-xl font-black italic">
                  {editingSatuan ? 'Update Satuan' : 'Satuan Baru'}
                </DialogTitle>
                <DialogDescription className="text-xs font-medium">
                  {editingSatuan
                    ? 'Sesuaikan unit satuan produk yang sudah ada.'
                    : 'Satuan ini akan otomatis tersedia sebagai pilihan di aplikasi mobile.'}
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-5 py-6">
                <div className="space-y-2">
                  <Label htmlFor="nama" className="text-[10px] font-black uppercase tracking-widest opacity-70">Nama Satuan</Label>
                  <Input
                    id="nama"
                    value={formData.nama_satuan}
                    onChange={(e) =>
                      setFormData({ ...formData, nama_satuan: e.target.value })
                    }
                    placeholder="Contoh: PCS"
                    className="h-12 rounded-2xl border-border/40 bg-background/50 focus:ring-brand/20 font-mono uppercase"
                  />
                  <p className="text-[10px] text-muted-foreground italic px-1">
                    *Akan otomatis dikonversi ke huruf kapital
                  </p>
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
                  {editingSatuan ? 'Simpan Perubahan' : 'Buat Satuan'}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
          <Button variant="outline" size="icon" className="rounded-xl border-border/40 bg-card/40 backdrop-blur-md cursor-pointer active:rotate-180 transition-all duration-500" onClick={fetchSatuans}>
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Card className="overflow-hidden border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 rounded-3xl shadow-sm">
        <CardHeader className="border-b border-border/20 bg-muted/20 pb-4">
          <div className="flex items-center gap-3">
            <div className="rounded-xl bg-brand-secondary/10 p-2.5 ring-1 ring-brand-secondary/20">
              <Ruler className="h-5 w-5 text-brand-secondary" />
            </div>
            <div>
              <CardTitle className="text-base font-bold tracking-tight">Katalog Satuan ({satuans.length})</CardTitle>
              <CardDescription className="text-[10px] uppercase tracking-widest font-semibold opacity-60">Global unit configuration</CardDescription>
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
          ) : satuans.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 text-center gap-3">
              <div className="rounded-full bg-muted p-6 ring-1 ring-border/40 shadow-inner">
                <Hash className="h-10 w-10 text-muted-foreground/20" />
              </div>
              <div className="space-y-1">
                <p className="text-sm font-bold">Katalog Kosong</p>
                <p className="text-xs text-muted-foreground/60 max-w-[200px]">Belum ada satuan master yang terdaftar di sistem.</p>
              </div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/30 border-b border-border/40 hover:bg-muted/30">
                    <TableHead className="py-4 pl-6 text-[10px] font-black uppercase tracking-widest">Nama Satuan</TableHead>
                    <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest text-center">Status</TableHead>
                    <TableHead className="py-4 text-[10px] font-black uppercase tracking-widest text-center">Order</TableHead>
                    <TableHead className="py-4 pr-6 text-right"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <AnimatePresence mode="popLayout">
                    {satuans.map((satuan) => (
                      <motion.tr 
                        key={satuan.id}
                        variants={item}
                        initial="hidden"
                        animate="show"
                        exit="hidden"
                        className="group hover:bg-muted/20 border-b border-border/20 last:border-0 transition-colors"
                      >
                          <TableCell className="py-4 pl-6">
                            <div className="flex items-center gap-3">
                              <div className="h-8 w-8 rounded-lg bg-background border border-border/40 flex items-center justify-center font-black text-[10px] text-muted-foreground/40 uppercase font-mono">
                                {satuan.nama_satuan.charAt(0)}
                              </div>
                              <div className="flex items-center gap-2">
                                <span className="text-sm font-bold tracking-tight uppercase font-mono">{satuan.nama_satuan}</span>
                                <Button 
                                  variant="ghost" 
                                  size="icon" 
                                  onClick={() => openEditDialog(satuan)}
                                  className="h-6 w-6 rounded-lg opacity-0 group-hover:opacity-100 transition-all hover:bg-brand/10 hover:text-brand"
                                >
                                  <Pencil className="h-3 w-3" />
                                </Button>
                              </div>
                            </div>
                          </TableCell>
                          <TableCell className="py-4 text-center">
                            <button 
                              onClick={() => toggleActive(satuan)}
                              className="cursor-pointer active:scale-95 transition-transform"
                            >
                              {satuan.is_active ? (
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
                          <TableCell className="py-4 text-center">
                            <span className="font-mono text-xs font-bold text-muted-foreground/40">#{satuan.sort_order}</span>
                          </TableCell>
                          <TableCell className="py-4 pr-6 text-right">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                if (confirm(`Yakin ingin menonaktifkan "${satuan.nama_satuan}"?`)) {
                                  handleDelete(satuan.id);
                                }
                              }}
                              className="h-8 w-8 rounded-lg text-muted-foreground/40 hover:text-destructive hover:bg-destructive/10 transition-colors"
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </TableCell>
                      </motion.tr>
                    ))}
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
            Unit satuan ini akan digunakan di seluruh platform. Pastikan penulisan standar (misal: PCS, KG, PACK) agar konsisten bagi pengguna mobile.
          </p>
        </div>
      </motion.div>
    </motion.div>
  );
}
