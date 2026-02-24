'use client';

import { useState } from 'react';
import { Input } from '@/components/ui/input';
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
import { Badge } from '@/components/ui/badge';
import { Users, Store, Search } from 'lucide-react';

interface User {
  id: string;
  phone_number: string;
  status: string;
  created_at: string;
  last_login_at: string | null;
  WARUNG: { nama_pemilik: string | null }[];
}

interface Warung {
  id: string;
  nama_warung: string;
  nama_pemilik: string | null;
  phone: string | null;
  alamat: string | null;
  created_at: string;
  USERS: { phone_number: string } | null;
}

interface UserSearchProps {
  users: User[];
  warungs: Warung[];
}

function getStatusBadge(status: string) {
  switch (status) {
    case 'active':
      return (
        <Badge className="bg-brand/10 text-brand hover:bg-brand/20">
          Aktif
        </Badge>
      );
    case 'inactive':
      return (
        <Badge variant="secondary">Nonaktif</Badge>
      );
    case 'suspended':
      return (
        <Badge className="bg-destructive/10 text-destructive hover:bg-destructive/20">
          Diblokir
        </Badge>
      );
    default:
      return <Badge variant="outline">{status}</Badge>;
  }
}

export default function UserSearch({ users, warungs }: UserSearchProps) {
  const [search, setSearch] = useState('');

  const query = search.trim().toLowerCase();

  const filteredUsers = query
    ? users.filter((u) => {
        const phoneMatch = u.phone_number.toLowerCase().includes(query);
        const nameMatch = u.WARUNG?.[0]?.nama_pemilik?.toLowerCase().includes(query);
        return phoneMatch || nameMatch;
      })
    : users;

  const filteredWarungs = query
    ? warungs.filter(
        (w) =>
          w.phone?.toLowerCase().includes(query) ||
          w.USERS?.phone_number.toLowerCase().includes(query) ||
          w.nama_warung?.toLowerCase().includes(query) ||
          w.nama_pemilik?.toLowerCase().includes(query),
      )
    : warungs;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Users & Warung</h1>
        <p className="mt-1 text-muted-foreground">
          Monitoring user terdaftar dan warung mereka
        </p>
      </div>

      {/* Search Bar */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Cari user (nama, no. hp, atau nama warung)..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-10"
        />
      </div>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Users className="h-5 w-5 text-blue-500" />
            <CardTitle>Daftar User ({filteredUsers.length})</CardTitle>
          </div>
          <CardDescription>
            {query
              ? `Hasil pencarian "${search}" — ${filteredUsers.length} user ditemukan`
              : 'Semua user yang terdaftar di platform'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredUsers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <Users className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                {query ? 'Tidak ada user yang cocok' : 'Belum ada user terdaftar'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Nama User</TableHead>
                    <TableHead>No. Telepon</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Terdaftar</TableHead>
                    <TableHead>Login Terakhir</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredUsers.map((user) => (
                    <TableRow key={user.id}>
                      <TableCell className="font-medium">
                        {user.WARUNG?.[0]?.nama_pemilik ?? '-'}
                      </TableCell>
                      <TableCell className="font-mono text-sm">
                        {user.phone_number}
                      </TableCell>
                      <TableCell>{getStatusBadge(user.status)}</TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {new Date(user.created_at).toLocaleDateString('id-ID')}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {user.last_login_at
                          ? new Date(user.last_login_at).toLocaleString('id-ID')
                          : '-'}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Warungs Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Store className="h-5 w-5 text-brand" />
            <CardTitle>Daftar Warung ({filteredWarungs.length})</CardTitle>
          </div>
          <CardDescription>
            {query
              ? `Hasil pencarian "${search}" — ${filteredWarungs.length} warung ditemukan`
              : 'Semua warung yang terdaftar di platform'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {filteredWarungs.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <Store className="mb-3 h-12 w-12 text-muted-foreground/30" />
              <p className="text-sm text-muted-foreground">
                {query ? 'Tidak ada warung yang cocok' : 'Belum ada warung terdaftar'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Nama Warung</TableHead>
                    <TableHead>Pemilik</TableHead>
                    <TableHead>No. Telepon</TableHead>
                    <TableHead>Alamat</TableHead>
                    <TableHead>Terdaftar</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredWarungs.map((warung) => (
                    <TableRow key={warung.id}>
                      <TableCell className="font-medium">
                        {warung.nama_warung}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                         {warung.nama_pemilik ?? '-'}
                      </TableCell>
                      <TableCell className="font-mono text-sm">
                        {warung.phone ?? warung.USERS?.phone_number ?? '-'}
                      </TableCell>
                      <TableCell className="max-w-xs truncate text-sm text-muted-foreground">
                        {warung.alamat ?? '-'}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {new Date(warung.created_at).toLocaleDateString('id-ID')}
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
