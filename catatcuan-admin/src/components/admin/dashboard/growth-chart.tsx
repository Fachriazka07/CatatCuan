'use client';

import {
  Area,
  AreaChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  CartesianGrid,
} from 'recharts';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { motion } from 'framer-motion';

interface GrowthChartProps {
  data: {
    date: string;
    users: number;
    warung: number;
  }[];
  title: string;
  description: string;
  className?: string;
}

export function GrowthChart({ data, title, description, className }: GrowthChartProps) {
  const chartLabelColor = '#94a3b8';
  const tooltipTextColor = '#cbd5e1';

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.2, duration: 0.6, ease: "easeOut" }}
      className={cn('col-span-1 border-none md:col-span-2 lg:col-span-8', className)}
    >
      <Card className="h-full border border-border/40 bg-card/40 backdrop-blur-md dark:bg-card/20 shadow-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold tracking-tight">{title}</CardTitle>
          <CardDescription className="text-xs font-medium opacity-60">{description}</CardDescription>
        </CardHeader>
        <CardContent className="px-2">
          <div className="h-[300px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart
                data={data}
                margin={{
                  top: 10,
                  right: 10,
                  left: 0,
                  bottom: 0,
                }}
              >
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--color-primary)" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="var(--color-primary)" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="colorWarung" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--color-brand-secondary)" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="var(--color-brand-secondary)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="hsl(var(--border))" opacity={0.3} />
                <XAxis
                  dataKey="date"
                  stroke={chartLabelColor}
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                  tick={{ fill: chartLabelColor, fontSize: 12 }}
                  tickFormatter={(value) => value.split('/')[0]}
                />
                <YAxis
                  stroke={chartLabelColor}
                  fontSize={12}
                  tickLine={false}
                  axisLine={false}
                  tick={{ fill: chartLabelColor, fontSize: 12 }}
                  tickFormatter={(value) => `${value}`}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    borderColor: 'hsl(var(--border))',
                    borderRadius: '16px',
                    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
                  }}
                  labelStyle={{ fontWeight: 'bold', marginBottom: '8px', color: tooltipTextColor }}
                  itemStyle={{ color: tooltipTextColor }}
                />
                <Area
                  type="monotone"
                  dataKey="users"
                  stroke="var(--color-primary)"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorUsers)"
                  name="Users"
                  animationDuration={2000}
                />
                <Area
                  type="monotone"
                  dataKey="warung"
                  stroke="var(--color-brand-secondary)"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorWarung)"
                  name="Warung"
                  animationDuration={2500}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
