import { getFirebaseMessaging, isFirebaseConfigured } from '@/lib/firebase-admin';
import { sql } from '@/lib/server-sql';

type NotificationLogStatus = 'queued' | 'sent' | 'failed' | 'skipped';

type LogNotificationArgs = {
  userId?: string | null;
  warungId?: string | null;
  channel: 'push' | 'sms';
  notificationType: string;
  title?: string | null;
  body?: string | null;
  payload?: Record<string, unknown> | null;
  providerMessageId?: string | null;
  status: NotificationLogStatus;
  errorMessage?: string | null;
  sentAt?: Date | null;
};

type PushNotificationArgs = {
  userId: string;
  warungId?: string;
  title: string;
  body: string;
  notificationType: string;
  data?: Record<string, string | number | boolean>;
};

type DueDateReminderStage = 'due_soon' | 'due_today' | 'overdue';
type StockAlertStage = 'low_stock' | 'out_of_stock';

type DueDateReminderRow = {
  hutang_id: string;
  warung_id: string;
  user_id: string;
  nama_warung: string;
  jenis: string | null;
  pelanggan_nama: string | null;
  amount_sisa: string | number;
  tanggal_jatuh_tempo: string;
  reminder_stage: DueDateReminderStage;
};

type LowStockAlertRow = {
  product_id: string;
  warung_id: string;
  user_id: string;
  nama_warung: string;
  nama_produk: string;
  satuan: string | null;
  stok_saat_ini: number;
  stok_minimum: number | null;
  alert_stage: StockAlertStage;
  effective_threshold: number;
};

type LowStockAlertGroup = {
  warung_id: string;
  user_id: string;
  nama_warung: string;
  items: LowStockAlertRow[];
};

type PreferenceRow = {
  push_enabled: boolean;
  due_date_reminder: boolean;
  low_stock_alert: boolean;
  daily_reminder: boolean;
};

type DailyReminderRow = {
  warung_id: string;
  user_id: string;
  nama_warung: string;
  has_sales: boolean;
  has_expenses: boolean;
};

type DeviceTokenRow = {
  device_token: string;
};

const rupiahFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
});

const defaultNotificationPreferences: PreferenceRow = {
  push_enabled: true,
  due_date_reminder: true,
  low_stock_alert: true,
  daily_reminder: false,
};

function stringifyData(
  data: Record<string, string | number | boolean> | undefined,
) {
  if (!data) {
    return {};
  }

  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value)]),
  );
}

function isTypeEnabled(
  preferences: PreferenceRow | undefined,
  notificationType: string,
) {
  const effectivePreferences = preferences ?? defaultNotificationPreferences;

  if (!effectivePreferences.push_enabled) {
    return false;
  }

  switch (notificationType) {
    case 'due_date_reminder':
      return effectivePreferences.due_date_reminder;
    case 'low_stock_alert':
      return effectivePreferences.low_stock_alert;
    case 'daily_reminder':
      return effectivePreferences.daily_reminder;
    default:
      return true;
  }
}

function formatRupiah(value: string | number) {
  const amount =
    typeof value === 'number' ? value : Number.parseFloat(value) || 0;

  return rupiahFormatter.format(amount);
}

function diffInDays(fromDate: Date, toDate: Date) {
  const millisPerDay = 1000 * 60 * 60 * 24;
  return Math.round((toDate.getTime() - fromDate.getTime()) / millisPerDay);
}

function buildDueDateReminderCopy(row: DueDateReminderRow, asOfDate: Date) {
  const dueDate = new Date(`${row.tanggal_jatuh_tempo}T00:00:00`);
  const customerName = row.pelanggan_nama?.trim() || 'pelanggan';
  const warungName = row.nama_warung.trim() || 'warung kamu';
  const amountLabel = formatRupiah(row.amount_sisa);
  const debtLabel =
    row.jenis?.toUpperCase() === 'PIUTANG' ? 'piutang kasbon' : 'tagihan';

  switch (row.reminder_stage) {
    case 'due_soon':
      return {
        title: 'Besok ada piutang jatuh tempo',
        body: `${customerName} di ${warungName} punya sisa ${debtLabel} ${amountLabel} yang jatuh tempo besok.`,
      };
    case 'due_today':
      return {
        title: 'Hari ini ada piutang jatuh tempo',
        body: `${customerName} di ${warungName} punya sisa ${debtLabel} ${amountLabel} yang jatuh tempo hari ini.`,
      };
    case 'overdue': {
      const overdueDays = Math.max(diffInDays(dueDate, asOfDate), 1);

      return {
        title: 'Ada piutang yang lewat jatuh tempo',
        body: `${customerName} di ${warungName} punya sisa ${debtLabel} ${amountLabel} yang telat ${overdueDays} hari.`,
      };
    }
  }
}

function buildLowStockAlertCopy(rows: LowStockAlertRow[]) {
  const [firstRow] = rows;
  const warungName = firstRow?.nama_warung.trim() || 'warung kamu';

  if (!firstRow) {
    return {
      title: 'Stok produk perlu dicek',
      body: `Ada perubahan stok produk di ${warungName}.`,
    };
  }

  if (rows.length === 1) {
    const unitLabel = firstRow.satuan?.trim() || 'pcs';

    if (firstRow.alert_stage === 'out_of_stock') {
      return {
        title: 'Produk habis',
        body: `${firstRow.nama_produk} di ${warungName} sudah habis. Segera isi ulang stok.`,
      };
    }

    return {
      title: 'Stok mulai menipis',
      body: `Sisa stok ${firstRow.nama_produk} di ${warungName} tinggal ${firstRow.stok_saat_ini} ${unitLabel}. Saatnya restok.`,
    };
  }

  const outOfStockItems = rows.filter(
    (row) => row.alert_stage === 'out_of_stock',
  );
  const lowStockItems = rows.filter((row) => row.alert_stage === 'low_stock');
  const previewNames = rows
    .slice(0, 3)
    .map((row) => row.nama_produk.trim())
    .join(', ');
  const extraCount = Math.max(rows.length - 3, 0);
  const previewLabel =
    extraCount > 0 ? `${previewNames}, +${extraCount} lagi` : previewNames;

  if (outOfStockItems.length === rows.length) {
    return {
      title: `${rows.length} produk habis`,
      body: `Produk di ${warungName} yang habis: ${previewLabel}. Segera isi ulang stok.`,
    };
  }

  if (lowStockItems.length === rows.length) {
    return {
      title: `${rows.length} stok produk menipis`,
      body: `Stok di ${warungName} mulai menipis: ${previewLabel}. Saatnya restok.`,
    };
  }

  return {
    title: 'Stok produk perlu dicek',
    body: `${outOfStockItems.length} produk habis dan ${lowStockItems.length} produk menipis di ${warungName}. Contoh: ${previewLabel}.`,
  };
}

function buildDailyReminderCopy(row: DailyReminderRow) {
  const warungName = row.nama_warung.trim() || 'warung kamu';

  return {
    title: 'Jangan lupa catat hari ini',
    body: `Belum ada penjualan atau pengeluaran yang tercatat di ${warungName} hari ini. Yuk cek lagi pencatatan warungmu.`,
  };
}

export async function logNotification({
  userId,
  warungId,
  channel,
  notificationType,
  title,
  body,
  payload,
  providerMessageId,
  status,
  errorMessage,
  sentAt,
}: LogNotificationArgs) {
  await sql`
    INSERT INTO public."NOTIFICATION_LOGS" (
      "user_id",
      "warung_id",
      "channel",
      "notification_type",
      "title",
      "body",
      "payload",
      "provider_message_id",
      "status",
      "error_message",
      "sent_at"
    )
    VALUES (
      ${userId ?? null},
      ${warungId ?? null},
      ${channel},
      ${notificationType},
      ${title ?? null},
      ${body ?? null},
      ${payload ? JSON.stringify(payload) : null}::jsonb,
      ${providerMessageId ?? null},
      ${status},
      ${errorMessage ?? null},
      ${sentAt ?? null}
    )
  `;
}

export async function sendPushNotificationToUser({
  userId,
  warungId,
  title,
  body,
  notificationType,
  data,
}: PushNotificationArgs) {
  const [preferenceRow] = await sql<PreferenceRow[]>`
    SELECT
      "push_enabled",
      "due_date_reminder",
      "low_stock_alert",
      "daily_reminder"
    FROM public."USER_NOTIFICATION_PREFERENCES"
    WHERE "user_id" = ${userId}
    LIMIT 1
  `;

  if (!isTypeEnabled(preferenceRow, notificationType)) {
    await logNotification({
      userId,
      warungId,
      channel: 'push',
      notificationType,
      title,
      body,
      payload: data,
      status: 'skipped',
      errorMessage: 'Notification preference disabled',
    });

    return {
      success: true,
      skipped: true,
      sentCount: 0,
      reason: 'Notification preference disabled',
    };
  }

  const deviceTokenRows = await sql<DeviceTokenRow[]>`
    SELECT "device_token"
    FROM public."MOBILE_DEVICE_TOKENS"
    WHERE "user_id" = ${userId}
      AND "is_active" = true
  `;

  if (deviceTokenRows.length === 0) {
    await logNotification({
      userId,
      warungId,
      channel: 'push',
      notificationType,
      title,
      body,
      payload: data,
      status: 'skipped',
      errorMessage: 'No active device token registered',
    });

    return {
      success: true,
      skipped: true,
      sentCount: 0,
      reason: 'No active device token registered',
    };
  }

  if (!isFirebaseConfigured()) {
    await logNotification({
      userId,
      warungId,
      channel: 'push',
      notificationType,
      title,
      body,
      payload: data,
      status: 'failed',
      errorMessage: 'Firebase Admin is not configured',
    });

    return {
      success: false,
      skipped: false,
      sentCount: 0,
      reason: 'Firebase Admin is not configured',
    };
  }

  const tokens = deviceTokenRows.map((row) => row.device_token);
  const response = await getFirebaseMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data: stringifyData(data),
  });

  const invalidTokens: string[] = [];

  response.responses.forEach((entry, index) => {
    if (
      !entry.success &&
      entry.error?.code === 'messaging/registration-token-not-registered'
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    for (const token of invalidTokens) {
      await sql`
        UPDATE public."MOBILE_DEVICE_TOKENS"
        SET
          "is_active" = false,
          "last_error" = 'messaging/registration-token-not-registered',
          "updated_at" = now()
        WHERE "device_token" = ${token}
      `;
    }
  }

  const errorMessages = response.responses
    .filter((entry) => !entry.success && entry.error?.message)
    .map((entry) => entry.error?.message)
    .filter((message): message is string => Boolean(message));

  await logNotification({
    userId,
    warungId,
    channel: 'push',
    notificationType,
    title,
    body,
    payload: {
      ...data,
      requestedTokenCount: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
    },
    status: response.successCount > 0 ? 'sent' : 'failed',
    errorMessage: errorMessages.length > 0 ? errorMessages.join(' | ') : null,
    sentAt: response.successCount > 0 ? new Date() : null,
  });

  return {
    success: response.successCount > 0,
    skipped: false,
    sentCount: response.successCount,
    failedCount: response.failureCount,
    invalidTokenCount: invalidTokens.length,
  };
}

export async function processDueDateReminders(args?: {
  asOfDate?: string;
  lookaheadDays?: number;
}) {
  const asOfDate = args?.asOfDate ?? new Date().toISOString().slice(0, 10);
  const lookaheadDays = args?.lookaheadDays ?? 1;
  const baseDate = new Date(`${asOfDate}T00:00:00`);

  const rows = await sql<DueDateReminderRow[]>`
    WITH due_hutang AS (
      SELECT
        h."id" AS hutang_id,
        h."warung_id" AS warung_id,
        w."user_id" AS user_id,
        w."nama_warung" AS nama_warung,
        h."jenis" AS jenis,
        p."nama" AS pelanggan_nama,
        h."amount_sisa" AS amount_sisa,
        h."tanggal_jatuh_tempo"::text AS tanggal_jatuh_tempo,
        CASE
          WHEN h."tanggal_jatuh_tempo" = ((${asOfDate})::date + ${lookaheadDays} * interval '1 day')::date THEN 'due_soon'
          WHEN h."tanggal_jatuh_tempo" = (${asOfDate})::date THEN 'due_today'
          WHEN h."tanggal_jatuh_tempo" < (${asOfDate})::date THEN 'overdue'
        END AS reminder_stage
      FROM public."HUTANG" h
      JOIN public."WARUNG" w
        ON w."id" = h."warung_id"
      LEFT JOIN public."PELANGGAN" p
        ON p."id" = h."pelanggan_id"
      WHERE h."tanggal_jatuh_tempo" IS NOT NULL
        AND h."jenis" = 'PIUTANG'
        AND coalesce(h."amount_sisa", 0) > 0
        AND h."status" <> 'lunas'
        AND (
          h."tanggal_jatuh_tempo" = ((${asOfDate})::date + ${lookaheadDays} * interval '1 day')::date
          OR h."tanggal_jatuh_tempo" = (${asOfDate})::date
          OR h."tanggal_jatuh_tempo" < (${asOfDate})::date
        )
    )
    SELECT *
    FROM due_hutang dh
    WHERE NOT EXISTS (
      SELECT 1
      FROM public."NOTIFICATION_LOGS" nl
      WHERE nl."user_id" = dh."user_id"
        AND nl."channel" = 'push'
        AND nl."notification_type" = 'due_date_reminder'
        AND nl."status" = 'sent'
        AND nl."created_at"::date = (${asOfDate})::date
        AND coalesce(nl."payload"->>'debtId', '') = dh."hutang_id"::text
        AND coalesce(nl."payload"->>'stage', '') = dh."reminder_stage"
    )
    ORDER BY dh."tanggal_jatuh_tempo" ASC
  `;

  const summary = {
    scannedCount: rows.length,
    sentCount: 0,
    failedCount: 0,
    skippedCount: 0,
    asOfDate,
  };

  for (const row of rows) {
    const copy = buildDueDateReminderCopy(row, baseDate);
    const result = await sendPushNotificationToUser({
      userId: row.user_id,
      warungId: row.warung_id,
      title: copy.title,
      body: copy.body,
      notificationType: 'due_date_reminder',
      data: {
        screen: 'hutang',
        debtId: row.hutang_id,
        stage: row.reminder_stage,
        dueDate: row.tanggal_jatuh_tempo,
      },
    });

    if (result.skipped) {
      summary.skippedCount += 1;
      continue;
    }

    if (result.success) {
      summary.sentCount += 1;
      continue;
    }

    summary.failedCount += 1;
  }

  return summary;
}

export async function processLowStockAlerts(args?: {
  asOfDate?: string;
  fallbackThreshold?: number;
}) {
  const asOfDate = args?.asOfDate ?? new Date().toISOString().slice(0, 10);
  const fallbackThreshold = Math.max(args?.fallbackThreshold ?? 3, 1);

  const rows = await sql<LowStockAlertRow[]>`
    WITH stock_products AS (
      SELECT
        p."id" AS product_id,
        p."warung_id" AS warung_id,
        w."user_id" AS user_id,
        w."nama_warung" AS nama_warung,
        p."nama_produk" AS nama_produk,
        p."satuan" AS satuan,
        coalesce(p."stok_saat_ini", 0) AS stok_saat_ini,
        p."stok_minimum" AS stok_minimum,
        CASE
          WHEN coalesce(p."stok_saat_ini", 0) <= 0 THEN 'out_of_stock'
          ELSE 'low_stock'
        END AS alert_stage,
        GREATEST(coalesce(NULLIF(p."stok_minimum", 0), ${fallbackThreshold}), 1) AS effective_threshold
      FROM public."PRODUK" p
      JOIN public."WARUNG" w
        ON w."id" = p."warung_id"
      WHERE coalesce(p."is_active", true) = true
        AND (
          coalesce(p."stok_saat_ini", 0) <= 0
          OR coalesce(p."stok_saat_ini", 0) < GREATEST(coalesce(NULLIF(p."stok_minimum", 0), ${fallbackThreshold}), 1)
        )
    )
    SELECT *
    FROM stock_products sp
    WHERE NOT EXISTS (
      SELECT 1
      FROM public."NOTIFICATION_LOGS" nl
      WHERE nl."user_id" = sp."user_id"
        AND nl."warung_id" = sp."warung_id"
        AND nl."channel" = 'push'
        AND nl."notification_type" = 'low_stock_alert'
        AND nl."status" = 'sent'
        AND coalesce(nl."payload"->>'asOfDate', '') = ${asOfDate}
    )
    ORDER BY sp."stok_saat_ini" ASC, sp."nama_produk" ASC
  `;

  const groupedRows = new Map<string, LowStockAlertGroup>();

  for (const row of rows) {
    const groupKey = `${row.user_id}:${row.warung_id}`;
    const existing = groupedRows.get(groupKey);

    if (existing) {
      existing.items.push(row);
      continue;
    }

    groupedRows.set(groupKey, {
      warung_id: row.warung_id,
      user_id: row.user_id,
      nama_warung: row.nama_warung,
      items: [row],
    });
  }

  const summary = {
    scannedCount: rows.length,
    groupedCount: groupedRows.size,
    sentCount: 0,
    failedCount: 0,
    skippedCount: 0,
    asOfDate,
  };

  for (const group of groupedRows.values()) {
    const outOfStockCount = group.items.filter(
      (row) => row.alert_stage === 'out_of_stock',
    ).length;
    const lowStockCount = group.items.length - outOfStockCount;
    const copy = buildLowStockAlertCopy(group.items);
    const result = await sendPushNotificationToUser({
      userId: group.user_id,
      warungId: group.warung_id,
      title: copy.title,
      body: copy.body,
      notificationType: 'low_stock_alert',
      data: {
        screen: 'produk',
        asOfDate,
        productCount: group.items.length,
        outOfStockCount,
        lowStockCount,
        productIds: group.items.map((row) => row.product_id).join(','),
        productNames: group.items.map((row) => row.nama_produk).join(', '),
      },
    });

    if (result.skipped) {
      summary.skippedCount += 1;
      continue;
    }

    if (result.success) {
      summary.sentCount += 1;
      continue;
    }

    summary.failedCount += 1;
  }

  return summary;
}

export async function processDailyReminders(args?: {
  asOfDate?: string;
  timezone?: string;
}) {
  const asOfDate = args?.asOfDate ?? new Date().toISOString().slice(0, 10);
  const timezone = args?.timezone?.trim() || 'Asia/Jakarta';

  const rows = await sql<DailyReminderRow[]>`
    SELECT
      w."id" AS warung_id,
      w."user_id" AS user_id,
      w."nama_warung" AS nama_warung,
      EXISTS (
        SELECT 1
        FROM public."PENJUALAN" p
        WHERE p."warung_id" = w."id"
          AND (p."tanggal" AT TIME ZONE ${timezone})::date = (${asOfDate})::date
      ) AS has_sales,
      EXISTS (
        SELECT 1
        FROM public."PENGELUARAN" e
        WHERE e."warung_id" = w."id"
          AND (e."tanggal" AT TIME ZONE ${timezone})::date = (${asOfDate})::date
      ) AS has_expenses
    FROM public."WARUNG" w
    WHERE w."user_id" IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM public."PENJUALAN" p
        WHERE p."warung_id" = w."id"
          AND (p."tanggal" AT TIME ZONE ${timezone})::date = (${asOfDate})::date
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public."PENGELUARAN" e
        WHERE e."warung_id" = w."id"
          AND (e."tanggal" AT TIME ZONE ${timezone})::date = (${asOfDate})::date
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public."NOTIFICATION_LOGS" nl
        WHERE nl."user_id" = w."user_id"
          AND nl."warung_id" = w."id"
          AND nl."channel" = 'push'
          AND nl."notification_type" = 'daily_reminder'
          AND nl."status" = 'sent'
          AND coalesce(nl."payload"->>'asOfDate', '') = ${asOfDate}
      )
    ORDER BY w."nama_warung" ASC
  `;

  const summary = {
    scannedCount: rows.length,
    sentCount: 0,
    failedCount: 0,
    skippedCount: 0,
    asOfDate,
  };

  for (const row of rows) {
    const copy = buildDailyReminderCopy(row);
    const result = await sendPushNotificationToUser({
      userId: row.user_id,
      warungId: row.warung_id,
      title: copy.title,
      body: copy.body,
      notificationType: 'daily_reminder',
      data: {
        screen: 'home',
        asOfDate,
        reminderType: 'daily_reminder',
      },
    });

    if (result.skipped) {
      summary.skippedCount += 1;
      continue;
    }

    if (result.success) {
      summary.sentCount += 1;
      continue;
    }

    summary.failedCount += 1;
  }

  return summary;
}
