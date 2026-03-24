'use client';

import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from 'recharts';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';

interface MasterDataChartProps {
  data: {
    name: string;
    count: number;
    color: string;
  }[];
  title: string;
  description: string;
  className?: string;
}

export function MasterDataChart({ data, title, description, className }: MasterDataChartProps) {
  const total = data.reduce((acc, curr) => acc + curr.count, 0);
  const tooltipTextColor = '#cbd5e1';
  const legendTextColor = '#94a3b8';

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: 0.3, duration: 0.5 }}
      className={cn('col-span-1 border-none lg:col-span-6', className)}
    >
      <Card className="h-full border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 shadow-sm transition-all hover:bg-card/60 dark:hover:bg-card/30">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-bold tracking-tight">{title}</CardTitle>
          <CardDescription className="text-xs font-medium opacity-60">{description}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="relative h-[220px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={data}
                  cx="50%"
                  cy="50%"
                  innerRadius={65}
                  outerRadius={85}
                  paddingAngle={8}
                  dataKey="count"
                  animationBegin={500}
                  animationDuration={1500}
                >
                  {data.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} stroke="none" />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    borderColor: 'hsl(var(--border))',
                    borderRadius: '16px',
                    boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
                    fontSize: '12px'
                  }}
                  labelStyle={{ color: tooltipTextColor, fontWeight: 'bold' }}
                  itemStyle={{ color: tooltipTextColor }}
                />
                <Legend 
                  verticalAlign="bottom" 
                  align="center"
                  iconType="circle"
                  wrapperStyle={{ fontSize: '11px', paddingTop: '20px', fontWeight: '600' }}
                  formatter={(value) => (
                    <span style={{ color: legendTextColor }}>
                      {value}
                    </span>
                  )}
                />
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute left-1/2 top-[44%] flex -translate-x-1/2 -translate-y-1/2 flex-col items-center pointer-events-none">
              <motion.span 
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 1.2 }}
                className="text-3xl font-black leading-none tracking-tighter"
                style={{ color: '#e2e8f0' }}
              >
                {total}
              </motion.span>
              <span
                className="mt-2 text-[9px] font-black uppercase tracking-[0.2em]"
                style={{ color: legendTextColor, opacity: 0.8 }}
              >
                Total Data
              </span>
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
