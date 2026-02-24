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
import { Textarea } from '@/components/ui/textarea';
import { Settings, Plus, Pencil, Trash2 } from 'lucide-react';
import { toast } from 'sonner';

interface AppConfig {
  id: string;
  key: string;
  value: string | null;
  description: string | null;
  updated_at: string;
}

export default function ConfigPage() {
  const [configs, setConfigs] = useState<AppConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState<AppConfig | null>(null);
  const [formData, setFormData] = useState({
    key: '',
    value: '',
    description: '',
  });

  const supabase = createClient();

  async function fetchConfigs() {
    setLoading(true);
    const { data, error } = await supabase
      .from('APP_CONFIG')
      .select('*')
      .order('key', { ascending: true });

    if (error) {
      toast.error('Gagal memuat konfigurasi: ' + error.message);
    } else {
      setConfigs(data ?? []);
    }
    setLoading(false);
  }

  useEffect(() => {
    fetchConfigs();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function openCreateDialog() {
    setEditingConfig(null);
    setFormData({ key: '', value: '', description: '' });
    setDialogOpen(true);
  }

  function openEditDialog(config: AppConfig) {
    setEditingConfig(config);
    setFormData({
      key: config.key,
      value: config.value ?? '',
      description: config.description ?? '',
    });
    setDialogOpen(true);
  }

  async function handleSubmit() {
    if (!formData.key.trim()) {
      toast.error('Key wajib diisi');
      return;
    }

    if (editingConfig) {
      const { error } = await supabase
        .from('APP_CONFIG')
        .update({
          value: formData.value.trim() || null,
          description: formData.description.trim() || null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', editingConfig.id);

      if (error) {
        toast.error('Gagal update: ' + error.message);
        return;
      }
      toast.success('Konfigurasi berhasil diupdate');
    } else {
      const { error } = await supabase.from('APP_CONFIG').insert({
        key: formData.key.trim(),
        value: formData.value.trim() || null,
        description: formData.description.trim() || null,
      });

      if (error) {
        toast.error('Gagal menambah: ' + error.message);
        return;
      }
      toast.success('Konfigurasi berhasil ditambahkan');
    }

    setDialogOpen(false);
    fetchConfigs();
  }

  async function handleDelete(id: string) {
    if (!confirm('Yakin ingin menghapus konfigurasi ini?')) return;

    const { error } = await supabase
      .from('APP_CONFIG')
      .delete()
      .eq('id', id);

    if (error) {
      toast.error('Gagal menghapus: ' + error.message);
      return;
    }
    toast.success('Konfigurasi berhasil dihapus');
    fetchConfigs();
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            Konfigurasi Aplikasi
          </h1>
          <p className="mt-1 text-muted-foreground">
            Atur konfigurasi global untuk platform CatatCuan
          </p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openCreateDialog}>
              <Plus className="mr-2 h-4 w-4" />
              Tambah Config
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {editingConfig
                  ? 'Edit Konfigurasi'
                  : 'Tambah Konfigurasi Baru'}
              </DialogTitle>
              <DialogDescription>
                Konfigurasi akan berlaku untuk seluruh platform
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="key">Key</Label>
                <Input
                  id="key"
                  value={formData.key}
                  onChange={(e) =>
                    setFormData({ ...formData, key: e.target.value })
                  }
                  placeholder="Contoh: MAX_WARUNG_PER_USER"
                  disabled={!!editingConfig}
                  className="font-mono"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="value">Value</Label>
                <Input
                  id="value"
                  value={formData.value}
                  onChange={(e) =>
                    setFormData({ ...formData, value: e.target.value })
                  }
                  placeholder="Contoh: 3"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="desc">Deskripsi</Label>
                <Textarea
                  id="desc"
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  placeholder="Penjelasan fungsi konfigurasi ini"
                  rows={3}
                />
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
                {editingConfig ? 'Simpan' : 'Tambah'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5 text-muted-foreground" />
            <CardTitle>App Config ({configs.length})</CardTitle>
          </div>
          <CardDescription>
            Key-value pairs untuk konfigurasi global
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
            </div>
          ) : configs.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <Settings className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                Belum ada konfigurasi. Tambahkan yang pertama.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Key</TableHead>
                    <TableHead>Value</TableHead>
                    <TableHead>Deskripsi</TableHead>
                    <TableHead>Updated</TableHead>
                    <TableHead className="text-right">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {configs.map((config) => (
                    <TableRow key={config.id}>
                      <TableCell className="font-mono text-sm text-primary">
                        {config.key}
                      </TableCell>
                      <TableCell className="font-mono text-sm">
                        {config.value ?? '-'}
                      </TableCell>
                      <TableCell className="max-w-xs truncate text-sm text-muted-foreground">
                        {config.description ?? '-'}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {new Date(config.updated_at).toLocaleDateString(
                          'id-ID',
                        )}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => openEditDialog(config)}
                          >
                            <Pencil className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => handleDelete(config.id)}
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
