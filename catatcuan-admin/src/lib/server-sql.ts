import postgres from 'postgres';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not defined');
}

declare global {
  var __catatCuanSql: ReturnType<typeof postgres> | undefined;
}

export const sql =
  global.__catatCuanSql ??
  postgres(connectionString, {
    prepare: false,
  });

if (process.env.NODE_ENV !== 'production') {
  global.__catatCuanSql = sql;
}
