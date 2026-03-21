import type { SupabaseClient } from '@supabase/supabase-js';

interface AdminActivityDetails {
  [key: string]: unknown;
}

export async function logAdminActivity(
  supabase: SupabaseClient,
  action: string,
  details: AdminActivityDetails = {},
) {
  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();

    const actorEmail = user?.email ?? null;
    let adminId: string | null = null;

    if (actorEmail) {
      const adminLookup = await supabase
          .from('ADMIN_USERS')
          .select('id')
          .eq('email', actorEmail)
          .maybeSingle();

      adminId = (adminLookup.data as { id: string } | null)?.id ?? null;
    }

    const payload: {
      action: string;
      admin_id?: string;
      details: AdminActivityDetails;
    } = {
      action,
      details: {
        ...details,
        actor_email: actorEmail,
      },
    };

    if (adminId) {
      payload.admin_id = adminId;
    }

    const { error } = await supabase.from('SYSTEM_LOGS').insert(payload);

    if (error) {
      console.error('Failed to write admin activity log:', error.message);
    }
  } catch (error) {
    console.error('Failed to collect admin activity context:', error);
  }
}
