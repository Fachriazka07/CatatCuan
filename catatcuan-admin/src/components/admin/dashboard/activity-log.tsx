'use client';

import { Activity, Clock, Shield, User } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';
import { formatShortDateTime } from '@/lib/admin-format';

interface LogEntry {
  id: string;
  action: string;
  created_at: string;
  details?: Record<string, unknown>;
}

interface ActivityLogProps {
  logs: LogEntry[];
  className?: string;
}

export function ActivityLog({ logs, className }: ActivityLogProps) {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className={cn('col-span-1 border-none md:col-span-1 lg:col-span-4', className)}
    >
      <Card className="h-full border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="rounded-full bg-brand/10 p-1.5 ring-1 ring-brand/20">
                <Activity className="h-3.5 w-3.5 text-brand" />
              </div>
              <div>
                <CardTitle className="text-sm font-bold tracking-tight">Log Sistem</CardTitle>
                <CardDescription className="text-[10px] uppercase tracking-wider font-semibold opacity-60">Real-time status</CardDescription>
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {logs.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-center text-muted-foreground">
                <Shield className="mb-2 h-10 w-10 opacity-10" />
                <p className="text-xs font-medium italic opacity-50">Sistem bersih, tidak ada aktivitas</p>
              </div>
            ) : (
              logs.map((log, index) => (
                <motion.div 
                  key={log.id} 
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="relative flex gap-3 pb-4 last:pb-0"
                >
                  {index !== logs.length - 1 && (
                    <span className="absolute left-[15px] top-8 h-full w-[1.5px] bg-gradient-to-b from-border/80 via-border/20 to-transparent" />
                  )}
                  <div className="z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-background/50 ring-1 ring-border shadow-sm backdrop-blur-sm transition-transform hover:scale-110">
                    {log.action.toLowerCase().includes('user') ? (
                      <User className="h-3.5 w-3.5 text-blue-500" />
                    ) : log.action.toLowerCase().includes('warung') ? (
                      <Clock className="h-3.5 w-3.5 text-brand" />
                    ) : (
                      <Shield className="h-3.5 w-3.5 text-muted-foreground" />
                    )}
                  </div>
                  <div className="flex flex-col gap-0.5">
                    <span className="text-[11px] font-bold leading-tight group-hover:text-brand transition-colors">
                      {log.action}
                    </span>
                    <div className="flex items-center gap-1.5 text-[9px] font-medium text-muted-foreground/60">
                      <Clock className="h-2.5 w-2.5 opacity-50" />
                      {formatShortDateTime(log.created_at)}
                    </div>
                  </div>
                </motion.div>
              ))
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
