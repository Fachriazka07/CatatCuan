'use client';

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Ban, CheckCircle2, PauseCircle } from 'lucide-react';
import { toast } from 'sonner';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { logAdminActivity } from '@/lib/admin-activity';
import { cn } from '@/lib/utils';

interface UserStatusActionsProps {
  userId: string;
  currentStatus: string;
}

const statusOptions = [
  {
    value: 'active',
    label: 'Aktifkan',
    icon: CheckCircle2,
    helper:
      'User bisa login dan memakai aplikasi mobile seperti biasa.',
    activeClassName:
      '!border-brand !bg-brand !text-primary-foreground shadow-sm hover:!border-brand hover:!bg-brand/90',
    inactiveClassName:
      'border-slate-300 bg-background text-slate-500 hover:border-slate-400 hover:bg-slate-100 hover:text-slate-700',
  },
  {
    value: 'inactive',
    label: 'Nonaktifkan',
    icon: PauseCircle,
    helper:
      'Akses login dihentikan sementara, tapi status ini masih cocok untuk akun yang bisa diaktifkan lagi tanpa catatan pelanggaran.',
    activeClassName:
      '!border-slate-400 !bg-slate-100 !text-slate-900 shadow-sm hover:!border-slate-400 hover:!bg-slate-200',
    inactiveClassName:
      'border-slate-300 bg-background text-slate-500 hover:border-slate-400 hover:bg-slate-100 hover:text-slate-700',
  },
  {
    value: 'suspended',
    label: 'Blokir',
    icon: Ban,
    helper:
      'Akses ditolak karena pelanggaran, penyalahgunaan, atau keputusan final admin. Status ini lebih keras daripada nonaktif.',
    activeClassName:
      '!border-destructive !bg-destructive !text-white shadow-sm hover:!border-destructive hover:!bg-destructive/90',
    inactiveClassName:
      'border-slate-300 bg-background text-slate-500 hover:border-slate-400 hover:bg-slate-100 hover:text-slate-700',
  },
];

export function UserStatusActions({
  userId,
  currentStatus,
}: UserStatusActionsProps) {
  const router = useRouter();
  const supabase = createClient();
  const normalizedCurrentStatus = currentStatus.trim().toLowerCase();
  const [status, setStatus] = useState(normalizedCurrentStatus);
  const [isPending, startTransition] = useTransition();
  const [isUpdating, setIsUpdating] = useState(false);

  useEffect(() => {
    setStatus(normalizedCurrentStatus);
  }, [normalizedCurrentStatus]);

  async function updateStatus(nextStatus: string) {
    if (nextStatus === status) {
      return;
    }

    setIsUpdating(true);

    const { error } = await supabase
      .from('USERS')
      .update({
        status: nextStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', userId);

    if (error) {
      toast.error(`Gagal memperbarui status: ${error.message}`);
      setIsUpdating(false);
      return;
    }

    await logAdminActivity(supabase, 'Memperbarui status user', {
      user_id: userId,
      previous_status: status,
      next_status: nextStatus,
    });

    setStatus(nextStatus);
    toast.success('Status user berhasil diperbarui');
    startTransition(() => router.refresh());
    setIsUpdating(false);
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        {statusOptions.map((option) => {
          const Icon = option.icon;
          const isSelected = status === option.value;

          return (
            <Button
              key={option.value}
              type="button"
              size="sm"
              variant="outline"
              aria-pressed={isSelected}
              className={cn(
                'rounded-full px-4 transition-colors duration-200',
                isSelected ? option.activeClassName : option.inactiveClassName,
              )}
              disabled={isUpdating || isPending}
              onClick={() => updateStatus(option.value)}
            >
              <Icon className="h-4 w-4" />
              {option.label}
            </Button>
          );
        })}
      </div>
      <p className="text-sm text-muted-foreground">
        {statusOptions.find((option) => option.value == status)?.helper}
      </p>
    </div>
  );
}
