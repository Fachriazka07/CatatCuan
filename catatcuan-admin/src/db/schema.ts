
import { pgTable, uuid, text, timestamp, boolean, integer, pgEnum, jsonb } from 'drizzle-orm/pg-core';

// Enums
export const adminRoleEnum = pgEnum('admin_role', ['superadmin', 'admin']);
export const userStatusEnum = pgEnum('user_status', ['active', 'inactive', 'suspended']);
export const expenseCategoryType = pgEnum('expense_category_type', ['business', 'personal']);

// Admin Tables
export const adminUsers = pgTable('ADMIN_USERS', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  role: adminRoleEnum('role').notNull(),
  createdAt: timestamp('created_at').defaultNow(),
  lastLoginAt: timestamp('last_login_at'),
});

export const appConfig = pgTable('APP_CONFIG', {
  id: uuid('id').defaultRandom().primaryKey(),
  key: text('key').notNull().unique(),
  value: text('value'),
  description: text('description'),
  updatedAt: timestamp('updated_at').defaultNow(),
  updatedBy: uuid('updated_by').references(() => adminUsers.id),
});

export const masterKategoriProduk = pgTable('MASTER_KATEGORI_PRODUK', {
  id: uuid('id').defaultRandom().primaryKey(),
  namaKategori: text('nama_kategori').notNull(),
  icon: text('icon'),
  sortOrder: integer('sort_order').default(0),
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
});

export const masterSatuan = pgTable('MASTER_SATUAN', {
  id: uuid('id').defaultRandom().primaryKey(),
  namaSatuan: text('nama_satuan').notNull(),
  sortOrder: integer('sort_order').default(0),
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
});

export const masterKategoriPengeluaran = pgTable('MASTER_KATEGORI_PENGELUARAN', {
  id: uuid('id').defaultRandom().primaryKey(),
  namaKategori: text('nama_kategori').notNull(),
  tipe: expenseCategoryType('tipe').notNull(),
  icon: text('icon'),
  sortOrder: integer('sort_order').default(0),
  isActive: boolean('is_active').default(true),
  createdAt: timestamp('created_at').defaultNow(),
});

export const systemLogs = pgTable('SYSTEM_LOGS', {
  id: uuid('id').defaultRandom().primaryKey(),
  action: text('action').notNull(),
  adminId: uuid('admin_id').references(() => adminUsers.id),
  details: jsonb('details'),
  createdAt: timestamp('created_at').defaultNow(),
});

// Read-Only / Reference Tables (Partial Definition)
export const users = pgTable('USERS', {
  id: uuid('id').defaultRandom().primaryKey(),
  phoneNumber: text('phone_number').notNull(),
  status: userStatusEnum('status').default('active'),
  createdAt: timestamp('created_at').defaultNow(),
});

export const mobileDeviceTokens = pgTable('MOBILE_DEVICE_TOKENS', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id),
  deviceToken: text('device_token').notNull().unique(),
  platform: text('platform').notNull(),
  deviceLabel: text('device_label'),
  isActive: boolean('is_active').default(true),
  lastSeenAt: timestamp('last_seen_at').defaultNow(),
  lastError: text('last_error'),
  createdAt: timestamp('created_at').defaultNow(),
  updatedAt: timestamp('updated_at').defaultNow(),
});

export const userNotificationPreferences = pgTable(
  'USER_NOTIFICATION_PREFERENCES',
  {
    userId: uuid('user_id')
      .primaryKey()
      .references(() => users.id),
    pushEnabled: boolean('push_enabled').default(true),
    smsEnabled: boolean('sms_enabled').default(true),
    dueDateReminder: boolean('due_date_reminder').default(true),
    lowStockAlert: boolean('low_stock_alert').default(true),
    dailyReminder: boolean('daily_reminder').default(false),
    updatedAt: timestamp('updated_at').defaultNow(),
  },
);

export const passwordResetOtps = pgTable('PASSWORD_RESET_OTPS', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id),
  phoneNumber: text('phone_number').notNull(),
  codeHash: text('code_hash').notNull(),
  channel: text('channel').notNull(),
  expiresAt: timestamp('expires_at').notNull(),
  usedAt: timestamp('used_at'),
  attemptCount: integer('attempt_count').default(0),
  sentAt: timestamp('sent_at').defaultNow(),
  createdAt: timestamp('created_at').defaultNow(),
});

export const warung = pgTable('WARUNG', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id),
  namaWarung: text('nama_warung').notNull(),
  createdAt: timestamp('created_at').defaultNow(),
});

export const notificationLogs = pgTable('NOTIFICATION_LOGS', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').references(() => users.id),
  warungId: uuid('warung_id').references(() => warung.id),
  channel: text('channel').notNull(),
  notificationType: text('notification_type').notNull(),
  title: text('title'),
  body: text('body'),
  payload: jsonb('payload'),
  providerMessageId: text('provider_message_id'),
  status: text('status').notNull(),
  errorMessage: text('error_message'),
  sentAt: timestamp('sent_at'),
  createdAt: timestamp('created_at').defaultNow(),
});

export const kategoriPengeluaran = pgTable('KATEGORI_PENGELUARAN', {
  id: uuid('id').defaultRandom().primaryKey(),
  warungId: uuid('warung_id').references(() => warung.id),
  namaKategori: text('nama_kategori').notNull(),
  tipe: expenseCategoryType('tipe').notNull(),
  icon: text('icon'),
  sortOrder: integer('sort_order').default(0),
  masterKategoriId: uuid('master_kategori_id').references(() => masterKategoriPengeluaran.id),
});
