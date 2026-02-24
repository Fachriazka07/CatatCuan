import { createClient } from '@/lib/supabase/server';
import UserSearch from './UserSearch';

async function getUsersAndWarungs() {
  const supabase = await createClient();

  const [usersRes, warungRes] = await Promise.all([
    supabase
      .from('USERS')
      .select('*, WARUNG(nama_pemilik)')
      .order('created_at', { ascending: false }),
    supabase
      .from('WARUNG')
      .select('*, USERS(phone_number)')
      .order('created_at', { ascending: false }),
  ]);

  return {
    users: usersRes.data ?? [],
    warungs: warungRes.data ?? [],
  };
}

export default async function UsersPage() {
  const { users, warungs } = await getUsersAndWarungs();

  return <UserSearch users={users} warungs={warungs} />;
}
