'use client';

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from 'recharts';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';

interface UserStatusChartProps {
  data: {
    status: string;
    count: number;
    color: string;
  }[];
  className?: string;
}

export function UserStatusChart({ data, className }: UserStatusChartProps) {
  const chartLabelColor = '#94a3b8';
  const tooltipTextColor = '#cbd5e1';

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: 0.4, duration: 0.5 }}
      className={cn('col-span-1 border-none md:col-span-1 lg:col-span-6', className)}
    >
      <Card className="h-full border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 shadow-sm transition-all hover:bg-card/60 dark:hover:bg-card/30">
        <CardHeader>
          <CardTitle className="text-sm font-bold tracking-tight">Status Pengguna</CardTitle>
          <CardDescription className="text-xs font-medium opacity-60">Distribusi status akun platform</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[180px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="hsl(var(--border))" opacity={0.3} />
                <XAxis 
                  dataKey="status" 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  stroke={chartLabelColor}
                  tick={{ fill: chartLabelColor, fontSize: 10, fontWeight: 600 }}
                  fontWeight="600"
                />
                <YAxis 
                  fontSize={10} 
                  tickLine={false} 
                  axisLine={false} 
                  stroke={chartLabelColor}
                  tick={{ fill: chartLabelColor, fontSize: 10 }}
                />
                <Tooltip
                  cursor={{ fill: 'hsl(var(--muted))', opacity: 0.2 }}
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    borderColor: 'hsl(var(--border))',
                    borderRadius: '12px',
                    fontSize: '11px',
                    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
                  }}
                  labelStyle={{ color: tooltipTextColor, fontWeight: 'bold' }}
                  itemStyle={{ color: tooltipTextColor }}
                />
                <Bar dataKey="count" radius={[6, 6, 0, 0]} barSize={45} animationBegin={800} animationDuration={1500}>
                  {data.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-5 flex justify-center gap-6">
            {data.map((item) => (
              <div key={item.status} className="flex items-center gap-2">
                <div className="h-2 w-2 rounded-full" style={{ backgroundColor: item.color }} />
                <span
                  className="text-[10px] font-bold uppercase tracking-wider"
                  style={{ color: chartLabelColor }}
                >
                  {item.status}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
