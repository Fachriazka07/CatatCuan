'use client';

import { useState, useTransition } from 'react';
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
    activeClassName:
      'border-brand bg-brand text-primary-foreground hover:bg-brand/90',
    inactiveClassName:
      'border-brand/30 bg-background text-brand hover:bg-brand/10',
  },
  {
    value: 'inactive',
    label: 'Nonaktifkan',
    icon: PauseCircle,
    activeClassName:
      'border-border bg-muted text-foreground hover:bg-muted',
    inactiveClassName:
      'border-border bg-background text-foreground hover:bg-muted/60',
  },
  {
    value: 'suspended',
    label: 'Blokir',
    icon: Ban,
    activeClassName:
      'border-destructive bg-destructive text-white hover:bg-destructive/90',
    inactiveClassName:
      'border-destructive/30 bg-background text-destructive hover:bg-destructive/10',
  },
];

export function UserStatusActions({
  userId,
  currentStatus,
}: UserStatusActionsProps) {
  const router = useRouter();
  const supabase = createClient();
  const [status, setStatus] = useState(currentStatus);
  const [isPending, startTransition] = useTransition();
  const [isUpdating, setIsUpdating] = useState(false);

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
            className={cn(
              'shadow-none',
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
  );
}
