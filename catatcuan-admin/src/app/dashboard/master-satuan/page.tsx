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
import { Ruler, Plus, Pencil, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { logAdminActivity } from '@/lib/admin-activity';

interface Satuan {
  id: string;
  nama_satuan: string;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

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

    if (editingSatuan) {
      const { error } = await supabase
        .from('MASTER_SATUAN')
        .update({
          nama_satuan: formData.nama_satuan.trim().toUpperCase(),
        })
        .eq('id', editingSatuan.id);

      if (error) {
        toast.error('Gagal update: ' + error.message);
        return;
      }
      await logAdminActivity(supabase, 'Memperbarui master satuan', {
        satuan_id: editingSatuan.id,
        nama_satuan: formData.nama_satuan.trim().toUpperCase(),
      });
      toast.success('Satuan berhasil diupdate');
    } else {
      const { error } = await supabase.from('MASTER_SATUAN').insert({
        nama_satuan: formData.nama_satuan.trim().toUpperCase(),
        sort_order: satuans.length,
      });

      if (error) {
        toast.error('Gagal menambah: ' + error.message);
        return;
      }
      await logAdminActivity(supabase, 'Menambahkan master satuan', {
        nama_satuan: formData.nama_satuan.trim().toUpperCase(),
      });
      toast.success('Satuan berhasil ditambahkan');
    }

    setDialogOpen(false);
    fetchSatuans();
  }

  async function handleDelete(id: string) {
    if (!confirm('Yakin ingin menonaktifkan satuan ini? Satuan akan dihapus dari semua user.')) return;

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
    toast.success('Satuan berhasil dinonaktifkan');
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
      nama_satuan: satuan.nama_satuan,
      is_active: !satuan.is_active,
    });
    fetchSatuans();
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            Master Satuan
          </h1>
          <p className="mt-1 text-muted-foreground">
            Kelola satuan default untuk user baru
          </p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openCreateDialog}>
              <Plus className="mr-2 h-4 w-4" />
              Tambah Satuan
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {editingSatuan ? 'Edit Satuan' : 'Tambah Satuan Baru'}
              </DialogTitle>
              <DialogDescription>
                {editingSatuan
                  ? 'Edit detail satuan produk'
                  : 'Satuan ini akan muncul sebagai default untuk user baru'}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="nama">Nama Satuan</Label>
                <Input
                  id="nama"
                  value={formData.nama_satuan}
                  onChange={(e) =>
                    setFormData({ ...formData, nama_satuan: e.target.value })
                  }
                  placeholder="Contoh: PCS"
                />
                <p className="text-xs text-muted-foreground">
                  Akan disimpan dalam huruf kapital
                </p>
              </div>

            </div>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setDialogOpen(false)}
              >
                Batal
              </Button>
              <Button onClick={handleSubmit}>
                {editingSatuan ? 'Simpan' : 'Tambah'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Ruler className="h-5 w-5 text-brand-secondary" />
            <CardTitle>Daftar Satuan ({satuans.length})</CardTitle>
          </div>
          <CardDescription>
            Satuan ini akan di-copy ke warung baru saat registrasi
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : satuans.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <Ruler className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                Belum ada satuan master
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Nama Satuan</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {satuans.map((satuan) => (
                    <TableRow key={satuan.id}>
                      <TableCell className="font-medium">
                        {satuan.nama_satuan}
                      </TableCell>
                      <TableCell>
                        <button onClick={() => toggleActive(satuan)}>
                          {satuan.is_active ? (
                            <Badge className="cursor-pointer bg-brand/10 text-brand hover:bg-brand/20">
                              Aktif
                            </Badge>
                          ) : (
                            <Badge
                              variant="secondary"
                              className="cursor-pointer"
                            >
                              Nonaktif
                            </Badge>
                          )}
                        </button>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => openEditDialog(satuan)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleDelete(satuan.id)}
                            className="text-destructive hover:bg-destructive/10 hover:text-destructive"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
