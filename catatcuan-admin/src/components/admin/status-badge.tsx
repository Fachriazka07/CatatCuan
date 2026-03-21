import { Badge } from '@/components/ui/badge';

interface UserStatusBadgeProps {
  status: string | null | undefined;
}

export function UserStatusBadge({ status }: UserStatusBadgeProps) {
  switch (status) {
    case 'active':
      return (
        <Badge className="border-brand/20 bg-brand/10 text-brand hover:bg-brand/20">
          Aktif
        </Badge>
      );
    case 'inactive':
      return <Badge variant="secondary">Nonaktif</Badge>;
    case 'suspended':
      return (
        <Badge className="border-destructive/20 bg-destructive/10 text-destructive hover:bg-destructive/20">
          Diblokir
        </Badge>
      );
    default:
      return <Badge variant="outline">{status ?? 'Tidak diketahui'}</Badge>;
    }
}
