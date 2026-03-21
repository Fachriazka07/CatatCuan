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
import { FolderTree, Plus, Pencil, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { logAdminActivity } from '@/lib/admin-activity';

interface Kategori {
  id: string;
  nama_kategori: string;
  icon: string | null;
  sort_order: number;
  is_active: boolean;
  created_at: string;
}

export default function MasterKategoriPage() {
  const [kategoris, setKategoris] = useState<Kategori[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingKategori, setEditingKategori] = useState<Kategori | null>(null);
  const [formData, setFormData] = useState({
    nama_kategori: '',
    icon: '',
  });

  const supabase = createClient();

  async function fetchKategoris() {
    setLoading(true);
    const { data, error } = await supabase
      .from('MASTER_KATEGORI_PRODUK')
      .select('*')
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
    setFormData({ nama_kategori: '', icon: 'Lainya.png' });
    setDialogOpen(true);
  }

  function openEditDialog(kategori: Kategori) {
    setEditingKategori(kategori);
    setFormData({
      nama_kategori: kategori.nama_kategori,
      icon: kategori.icon ?? '',
    });
    setDialogOpen(true);
  }

  async function handleSubmit() {
    if (!formData.nama_kategori.trim()) {
      toast.error('Nama kategori wajib diisi');
      return;
    }

    if (editingKategori) {
      const { error } = await supabase
        .from('MASTER_KATEGORI_PRODUK')
        .update({
          nama_kategori: formData.nama_kategori.trim(),
          icon: formData.icon.trim() || null,
        })
        .eq('id', editingKategori.id);

      if (error) {
        toast.error('Gagal update: ' + error.message);
        return;
      }
      await logAdminActivity(supabase, 'Memperbarui master kategori produk', {
        kategori_id: editingKategori.id,
        nama_kategori: formData.nama_kategori.trim(),
        icon: formData.icon.trim() || null,
      });
      toast.success('Kategori berhasil diupdate');
    } else {
      const { error } = await supabase.from('MASTER_KATEGORI_PRODUK').insert({
        nama_kategori: formData.nama_kategori.trim(),
        icon: formData.icon.trim() || null,
        sort_order: kategoris.length,
      });

      if (error) {
        toast.error('Gagal menambah: ' + error.message);
        return;
      }
      await logAdminActivity(supabase, 'Menambahkan master kategori produk', {
        nama_kategori: formData.nama_kategori.trim(),
        icon: formData.icon.trim() || null,
      });
      toast.success('Kategori berhasil ditambahkan');
    }

    setDialogOpen(false);
    fetchKategoris();
  }

  async function handleDelete(id: string) {
    if (!confirm('Yakin ingin menonaktifkan kategori ini? Kategori akan dihapus dari semua user.')) return;

    const { error } = await supabase
      .from('MASTER_KATEGORI_PRODUK')
      .update({ is_active: false })
      .eq('id', id);

    if (error) {
      toast.error('Gagal menonaktifkan: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Menonaktifkan master kategori produk', {
      kategori_id: id,
    });
    toast.success('Kategori berhasil dinonaktifkan');
    fetchKategoris();
  }

  async function toggleActive(kategori: Kategori) {
    const { error } = await supabase
      .from('MASTER_KATEGORI_PRODUK')
      .update({ is_active: !kategori.is_active })
      .eq('id', kategori.id);

    if (error) {
      toast.error('Gagal update status: ' + error.message);
      return;
    }
    await logAdminActivity(supabase, 'Mengubah status master kategori produk', {
      kategori_id: kategori.id,
      nama_kategori: kategori.nama_kategori,
      is_active: !kategori.is_active,
    });
    fetchKategoris();
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            Master Kategori Produk
          </h1>
          <p className="mt-1 text-muted-foreground">
            Kelola kategori default untuk user baru
          </p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openCreateDialog}>
              <Plus className="mr-2 h-4 w-4" />
              Tambah Kategori
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {editingKategori ? 'Edit Kategori' : 'Tambah Kategori Baru'}
              </DialogTitle>
              <DialogDescription>
                {editingKategori
                  ? 'Edit detail kategori produk'
                  : 'Kategori ini akan muncul sebagai default untuk user baru'}
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="nama">Nama Kategori</Label>
                <Input
                  id="nama"
                  value={formData.nama_kategori}
                  onChange={(e) =>
                    setFormData({ ...formData, nama_kategori: e.target.value })
                  }
                  placeholder="Contoh: Makanan Ringan"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="icon">Icon</Label>
                <select
                  id="icon"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={formData.icon || 'Lainya.png'}
                  onChange={(e) =>
                    setFormData({ ...formData, icon: e.target.value })
                  }
                >
                  <option value="Lainya.png">Lainnya (Default)</option>
                  <option value="Sembako.png">Sembako</option>
                  <option value="Cemilan.png">Cemilan</option>
                  <option value="Minuman.png">Minuman</option>
                  <option value="BumbuDapur.png">Bumbu Dapur</option>
                  <option value="Rokok.png">Rokok</option>
                  <option value="Obat.png">Obat-obatan</option>
                  <option value="PerlengkapanMandi.png">Perlengkapan Mandi</option>
                </select>
                <p className="text-xs text-muted-foreground">
                  Icon yang tersedia di mobile app
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
                {editingKategori ? 'Simpan' : 'Tambah'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <FolderTree className="h-5 w-5 text-brand-secondary" />
            <CardTitle>Daftar Kategori ({kategoris.length})</CardTitle>
          </div>
          <CardDescription>
            Kategori ini akan di-copy ke warung baru saat registrasi
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : kategoris.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <FolderTree className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                Belum ada kategori master
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-16">Icon</TableHead>
                    <TableHead>Nama Kategori</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {kategoris.map((kategori) => (
                    <TableRow key={kategori.id}>
                      <TableCell className="text-lg">
                        {kategori.icon ?? '-'}
                      </TableCell>
                      <TableCell className="font-medium">
                        {kategori.nama_kategori}
                      </TableCell>
                      <TableCell>
                        <button onClick={() => toggleActive(kategori)}>
                          {kategori.is_active ? (
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
                            onClick={() => openEditDialog(kategori)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleDelete(kategori.id)}
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
