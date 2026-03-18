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
import { Wallet, Plus, Pencil, Trash2, Tag, ImageIcon } from 'lucide-react';
import { toast } from 'sonner';

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

    if (editingKategori) {
      const { error } = await supabase
        .from('MASTER_KATEGORI_PENGELUARAN')
        .update({
          nama_kategori: formData.nama_kategori.trim(),
          tipe: formData.tipe,
          icon: formData.icon,
        })
        .eq('id', editingKategori.id);

      if (error) {
        toast.error('Gagal update: ' + error.message);
        return;
      }
      toast.success('Kategori pengeluaran berhasil diupdate');
    } else {
      const { error } = await supabase.from('MASTER_KATEGORI_PENGELUARAN').insert({
        nama_kategori: formData.nama_kategori.trim(),
        tipe: formData.tipe,
        icon: formData.icon,
        sort_order: kategoris.filter(k => k.tipe === formData.tipe).length + 1,
      });

      if (error) {
        toast.error('Gagal menambah: ' + error.message);
        return;
      }
      toast.success('Kategori pengeluaran berhasil ditambahkan');
    }

    setDialogOpen(false);
    fetchKategoris();
  }

  async function handleDelete(id: string) {
    if (!confirm('Yakin ingin menonaktifkan kategori ini?')) return;

    const { error } = await supabase
      .from('MASTER_KATEGORI_PENGELUARAN')
      .update({ is_active: false })
      .eq('id', id);

    if (error) {
      toast.error('Gagal menonaktifkan: ' + error.message);
      return;
    }
    toast.success('Kategori berhasil dinonaktifkan');
    fetchKategoris();
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            Master Kategori Pengeluaran
          </h1>
          <p className="mt-1 text-muted-foreground">
            Kelola kategori pengeluaran default untuk user baru
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
                Kategori ini akan muncul sebagai referensi default untuk pengeluaran user
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
                  placeholder="Contoh: Belanja Stok"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="tipe">Tipe Pengeluaran</Label>
                <select
                  id="tipe"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={formData.tipe}
                  onChange={(e) =>
                    setFormData({ ...formData, tipe: e.target.value as 'business' | 'personal' })
                  }
                >
                  <option value="business">Bisnis</option>
                  <option value="personal">Pribadi</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="icon">Pilih Icon</Label>
                <div className="grid grid-cols-3 gap-2">
                  {AVAILABLE_ICONS.map((icon) => (
                    <button
                      key={icon}
                      type="button"
                      onClick={() => setFormData({ ...formData, icon })}
                      className={`flex flex-col items-center justify-center p-2 border rounded-lg transition-all ${
                        formData.icon === icon
                          ? 'border-brand bg-brand/5 ring-1 ring-brand'
                          : 'border-muted hover:bg-muted/50'
                      }`}
                    >
                      <ImageIcon className={`h-6 w-6 mb-1 ${formData.icon === icon ? 'text-brand' : 'text-muted-foreground'}`} />
                      <span className="text-[10px] truncate w-full text-center">{icon.split('.')[0]}</span>
                    </button>
                  ))}
                </div>
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
            <Wallet className="h-5 w-5 text-brand-secondary" />
            <CardTitle>Daftar Kategori ({kategoris.length})</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-16">Icon</TableHead>
                    <TableHead>Nama Kategori</TableHead>
                    <TableHead>Tipe</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {kategoris.map((kategori) => (
                    <TableRow key={kategori.id}>
                      <TableCell className="text-xs">
                        <Badge variant="outline">{kategori.icon ?? '-'}</Badge>
                      </TableCell>
                      <TableCell className="font-medium">
                        {kategori.nama_kategori}
                      </TableCell>
                      <TableCell>
                        <Badge variant={kategori.tipe === 'business' ? 'default' : 'secondary'}>
                          {kategori.tipe === 'business' ? 'Bisnis' : 'Pribadi'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Badge variant={kategori.is_active ? 'outline' : 'secondary'} className={kategori.is_active ? 'text-brand border-brand/20 bg-brand/5' : ''}>
                          {kategori.is_active ? 'Aktif' : 'Nonaktif'}
                        </Badge>
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
                            className="text-destructive"
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
