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
import { Settings, Plus, Pencil, Trash2, BellRing, Send, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { logAdminActivity } from '@/lib/admin-activity';

interface AppConfig {
  id: string;
  key: string;
  value: string | null;
  description: string | null;
  updated_at: string;
}

export default function ConfigPage() {
  const today = new Date().toISOString().slice(0, 10);
  const [configs, setConfigs] = useState<AppConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState<AppConfig | null>(null);
  const [testLoading, setTestLoading] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    key: '',
    value: '',
    description: '',
  });
  const [manualPushData, setManualPushData] = useState({
    userId: '',
    warungId: '',
    title: 'Tes Notifikasi',
    body: 'Kalau ini muncul berarti push notification jalan.',
  });
  const [reminderData, setReminderData] = useState({
    asOfDate: today,
    lookaheadDays: '1',
    fallbackThreshold: '3',
    timezone: 'Asia/Jakarta',
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
      await logAdminActivity(supabase, 'Memperbarui konfigurasi aplikasi', {
        config_id: editingConfig.id,
        key: editingConfig.key,
        value: formData.value.trim() || null,
      });
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
      await logAdminActivity(supabase, 'Menambahkan konfigurasi aplikasi', {
        key: formData.key.trim(),
        value: formData.value.trim() || null,
      });
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
    await logAdminActivity(supabase, 'Menghapus konfigurasi aplikasi', {
      config_id: id,
    });
    toast.success('Konfigurasi berhasil dihapus');
    fetchConfigs();
  }

  async function runNotificationTest(
    type: 'manual_push' | 'due_date' | 'low_stock' | 'daily_reminder',
  ) {
    try {
      setTestLoading(type);

      const payload =
        type === 'manual_push'
          ? {
              type,
              userId: manualPushData.userId.trim(),
              warungId: manualPushData.warungId.trim() || undefined,
              title: manualPushData.title.trim(),
              body: manualPushData.body.trim(),
            }
          : type === 'due_date'
            ? {
                type,
                asOfDate: reminderData.asOfDate,
                lookaheadDays: Number(reminderData.lookaheadDays || '1'),
              }
            : type === 'low_stock'
              ? {
                  type,
                  asOfDate: reminderData.asOfDate,
                  fallbackThreshold: Number(
                    reminderData.fallbackThreshold || '3',
                  ),
                }
              : {
                  type,
                  asOfDate: reminderData.asOfDate,
                  timezone: reminderData.timezone.trim() || 'Asia/Jakarta',
                };

      const response = await fetch('/api/admin/notification-tests', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const result = (await response.json()) as {
        success: boolean;
        message?: string;
        error?: string;
      };

      if (!response.ok || !result.success) {
        throw new Error(result.error || 'Gagal menjalankan test notifikasi');
      }

      toast.success(result.message || 'Test notifikasi berhasil dijalankan');
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : 'Terjadi kesalahan saat menjalankan test';
      toast.error(message);
    } finally {
      setTestLoading(null);
    }
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
            <BellRing className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Test Notifikasi</CardTitle>
          </div>
          <CardDescription>
            Jalankan test notifikasi langsung dari dashboard tanpa perlu copy
            paste PowerShell.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
            <div className="rounded-xl border border-border/60 p-4">
              <div className="mb-4 space-y-1">
                <h3 className="font-semibold">1. Push Manual</h3>
                <p className="text-sm text-muted-foreground">
                  Kirim notif custom ke user tertentu. Cocok buat cek notif
                  kamu sendiri saat demo.
                </p>
              </div>

              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="manual-user-id">User ID Tujuan</Label>
                  <Input
                    id="manual-user-id"
                    value={manualPushData.userId}
                    onChange={(e) =>
                      setManualPushData((prev) => ({
                        ...prev,
                        userId: e.target.value,
                      }))
                    }
                    placeholder="Contoh: 711a7019-b8e1-40f1-a4c9-0f1c8087dc08"
                    className="font-mono text-sm"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="manual-warung-id">Warung ID (Opsional)</Label>
                  <Input
                    id="manual-warung-id"
                    value={manualPushData.warungId}
                    onChange={(e) =>
                      setManualPushData((prev) => ({
                        ...prev,
                        warungId: e.target.value,
                      }))
                    }
                    placeholder="Isi kalau mau payload lebih spesifik"
                    className="font-mono text-sm"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="manual-title">Judul Notifikasi</Label>
                  <Input
                    id="manual-title"
                    value={manualPushData.title}
                    onChange={(e) =>
                      setManualPushData((prev) => ({
                        ...prev,
                        title: e.target.value,
                      }))
                    }
                    placeholder="Contoh: Tes Notifikasi"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="manual-body">Isi Notifikasi</Label>
                  <Textarea
                    id="manual-body"
                    value={manualPushData.body}
                    onChange={(e) =>
                      setManualPushData((prev) => ({
                        ...prev,
                        body: e.target.value,
                      }))
                    }
                    rows={4}
                    placeholder="Tulis isi notif yang ingin kamu tampilkan"
                  />
                </div>

                <Button
                  onClick={() => runNotificationTest('manual_push')}
                  disabled={testLoading !== null}
                  className="w-full sm:w-auto"
                >
                  {testLoading === 'manual_push' ? (
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  ) : (
                    <Send className="mr-2 h-4 w-4" />
                  )}
                  Kirim Push Manual
                </Button>
              </div>
            </div>

            <div className="rounded-xl border border-border/60 p-4">
              <div className="mb-4 space-y-1">
                <h3 className="font-semibold">2. Reminder Terjadwal</h3>
                <p className="text-sm text-muted-foreground">
                  Tiga tombol ini menjalankan rule reminder yang sama seperti di
                  production.
                </p>
              </div>

              <div className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="reminder-date">Tanggal Acuan</Label>
                  <Input
                    id="reminder-date"
                    type="date"
                    value={reminderData.asOfDate}
                    onChange={(e) =>
                      setReminderData((prev) => ({
                        ...prev,
                        asOfDate: e.target.value,
                      }))
                    }
                  />
                </div>

                <div className="grid gap-4 sm:grid-cols-2">
                  <div className="space-y-2">
                    <Label htmlFor="lookahead-days">Lookahead Hutang</Label>
                    <Input
                      id="lookahead-days"
                      type="number"
                      min="0"
                      value={reminderData.lookaheadDays}
                      onChange={(e) =>
                        setReminderData((prev) => ({
                          ...prev,
                          lookaheadDays: e.target.value,
                        }))
                      }
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="fallback-threshold">
                      Threshold Stok
                    </Label>
                    <Input
                      id="fallback-threshold"
                      type="number"
                      min="1"
                      value={reminderData.fallbackThreshold}
                      onChange={(e) =>
                        setReminderData((prev) => ({
                          ...prev,
                          fallbackThreshold: e.target.value,
                        }))
                      }
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="timezone">Timezone Daily Reminder</Label>
                  <Input
                    id="timezone"
                    value={reminderData.timezone}
                    onChange={(e) =>
                      setReminderData((prev) => ({
                        ...prev,
                        timezone: e.target.value,
                      }))
                    }
                  />
                </div>

                <div className="space-y-3 pt-2">
                  <Button
                    variant="outline"
                    onClick={() => runNotificationTest('due_date')}
                    disabled={testLoading !== null}
                    className="w-full justify-start"
                  >
                    {testLoading === 'due_date' ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <BellRing className="mr-2 h-4 w-4" />
                    )}
                    Test Reminder Hutang Jatuh Tempo
                  </Button>

                  <Button
                    variant="outline"
                    onClick={() => runNotificationTest('low_stock')}
                    disabled={testLoading !== null}
                    className="w-full justify-start"
                  >
                    {testLoading === 'low_stock' ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <BellRing className="mr-2 h-4 w-4" />
                    )}
                    Test Alert Stok Menipis / Habis
                  </Button>

                  <Button
                    variant="outline"
                    onClick={() => runNotificationTest('daily_reminder')}
                    disabled={testLoading !== null}
                    className="w-full justify-start"
                  >
                    {testLoading === 'daily_reminder' ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    ) : (
                      <BellRing className="mr-2 h-4 w-4" />
                    )}
                    Test Pengingat Catat Hari Ini
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

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
