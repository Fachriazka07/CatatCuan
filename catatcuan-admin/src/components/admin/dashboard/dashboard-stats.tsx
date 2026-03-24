'use client';

import { useEffect, useState } from 'react';
import { LucideIcon } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { motion, animate } from 'framer-motion';

interface StatCardProps {
  title: string;
  value: number | string;
  description: string;
  icon: LucideIcon;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  className?: string;
  colorClass?: string;
}

function Counter({ value }: { value: number | string }) {
  const [displayValue, setDisplayValue] = useState(0);
  const isNumber = typeof value === 'number';

  useEffect(() => {
    if (!isNumber) return;
    const controls = animate(0, value as number, {
      duration: 1.5,
      ease: "easeOut",
      onUpdate(value) {
        setDisplayValue(Math.floor(value));
      },
    });
    return () => controls.stop();
  }, [value, isNumber]);

  if (!isNumber) return <span>{value}</span>;
  return <span>{displayValue.toLocaleString('id-ID')}</span>;
}

export function StatCard({
  title,
  value,
  description,
  icon: Icon,
  trend,
  className,
  colorClass,
}: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className={className}
    >
      <Card className={cn(
        'group relative overflow-hidden border border-border/40 bg-card/40 shadow-sm backdrop-blur-md transition-all hover:border-brand/40 dark:bg-card/20 dark:hover:bg-card/30',
      )}>
        {/* Glow effect on hover */}
        <div className="absolute -right-4 -top-4 h-24 w-24 rounded-full bg-brand/5 blur-3xl transition-all group-hover:bg-brand/10" />
        
        <CardHeader className="flex flex-row items-center justify-between pb-2">
          <CardTitle className="text-[10px] font-bold uppercase tracking-[0.15em] text-muted-foreground/80 group-hover:text-muted-foreground">
            {title}
          </CardTitle>
          <motion.div 
            whileHover={{ scale: 1.1, rotate: 5 }}
            className={cn('rounded-xl p-2.5 shadow-sm transition-colors group-hover:shadow-md', colorClass)}
          >
            <Icon className="h-4 w-4" />
          </motion.div>
        </CardHeader>
        <CardContent>
          <div className="flex items-baseline space-x-2">
            <div className="text-2xl font-black tracking-tight">
              <Counter value={value} />
            </div>
            {trend && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.5, type: 'spring' }}
                className={cn(
                  'flex items-center text-[10px] font-bold px-2 py-0.5 rounded-full ring-1 ring-inset',
                  trend.isPositive 
                    ? 'bg-brand/5 text-brand ring-brand/20' 
                    : 'bg-destructive/5 text-destructive ring-destructive/20'
                )}
              >
                {trend.isPositive ? '↑' : '↓'} {Math.abs(trend.value)}%
              </motion.div>
            )}
          </div>
          <CardDescription className="mt-1.5 text-[11px] font-medium text-muted-foreground/60 group-hover:text-muted-foreground/80">
            {description}
          </CardDescription>
        </CardContent>
      </Card>
    </motion.div>
  );
}
