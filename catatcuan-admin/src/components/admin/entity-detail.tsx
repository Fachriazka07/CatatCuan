import type { ReactNode } from 'react';
import Link from 'next/link';
import type { LucideIcon } from 'lucide-react';
import { ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { cn } from '@/lib/utils';

interface DetailPageHeaderProps {
  backHref: string;
  backLabel: string;
  title: string;
  description: string;
  actions?: ReactNode;
}

interface DetailHeroCardProps {
  icon: LucideIcon;
  iconClassName?: string;
  title: string;
  subtitle: string;
  badges?: ReactNode;
  metadata?: ReactNode;
  actions?: ReactNode;
}

interface DetailStatCardProps {
  label: string;
  value: string;
  description: string;
  icon: LucideIcon;
  accentClassName?: string;
}

interface DetailSectionProps {
  title: string;
  description: string;
  children: ReactNode;
  className?: string;
}

interface DetailInfoGridProps {
  items: Array<{
    label: string;
    value: ReactNode;
  }>;
}

export function DetailPageHeader({
  backHref,
  backLabel,
  title,
  description,
  actions,
}: DetailPageHeaderProps) {
  return (
    <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
      <div className="space-y-3">
        <Button variant="outline" size="sm" asChild>
          <Link href={backHref}>
            <ArrowLeft className="h-4 w-4" />
            {backLabel}
          </Link>
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{title}</h1>
          <p className="mt-1 text-muted-foreground">{description}</p>
        </div>
      </div>
      {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
    </div>
  );
}

export function DetailHeroCard({
  icon: Icon,
  iconClassName,
  title,
  subtitle,
  badges,
  metadata,
  actions,
}: DetailHeroCardProps) {
  return (
    <Card className="overflow-hidden border-border/60 bg-gradient-to-br from-brand/10 via-background to-brand-secondary/10 shadow-sm">
      <CardContent className="flex flex-col gap-6 p-6 lg:flex-row lg:items-start lg:justify-between">
        <div className="flex items-start gap-4">
          <div
            className={cn(
              'rounded-2xl border border-brand/20 bg-brand/10 p-4 text-brand shadow-sm',
              iconClassName,
            )}
          >
            <Icon className="h-8 w-8" />
          </div>
          <div className="space-y-3">
            <div>
              <h2 className="text-2xl font-semibold tracking-tight">{title}</h2>
              <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>
            </div>
            {badges ? <div className="flex flex-wrap gap-2">{badges}</div> : null}
            {metadata ? (
              <div className="flex flex-wrap gap-6 text-sm text-muted-foreground">
                {metadata}
              </div>
            ) : null}
          </div>
        </div>
        {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
      </CardContent>
    </Card>
  );
}

export function DetailStatCard({
  label,
  value,
  description,
  icon: Icon,
  accentClassName,
}: DetailStatCardProps) {
  return (
    <Card className="border-border/60 shadow-sm">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {label}
        </CardTitle>
        <div
          className={cn(
            'rounded-xl border border-brand/20 bg-brand/10 p-2 text-brand',
            accentClassName,
          )}
        >
          <Icon className="h-4 w-4" />
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-xl font-bold tracking-tight sm:text-2xl 2xl:text-3xl truncate">
          {value}
        </div>
        <CardDescription className="mt-1 text-[10px] sm:text-xs truncate">
          {description}
        </CardDescription>
      </CardContent>
    </Card>
  );
}

export function DetailSection({
  title,
  description,
  children,
  className,
}: DetailSectionProps) {
  return (
    <Card className={cn('border-border/60 shadow-sm', className)}>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

export function DetailInfoGrid({ items }: DetailInfoGridProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {items.map((item) => (
        <div
          key={item.label}
          className="rounded-xl border border-border/60 bg-muted/30 p-4"
        >
          <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {item.label}
          </p>
          <div className="mt-2 text-sm font-medium">{item.value}</div>
        </div>
      ))}
    </div>
  );
}
