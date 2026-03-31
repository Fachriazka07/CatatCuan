const adminTimeZone = 'Asia/Jakarta';

const currencyFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
});

const numberFormatter = new Intl.NumberFormat('id-ID');

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
  timeZone: adminTimeZone,
});

const dateTimeFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
  timeZone: adminTimeZone,
});

const shortDateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: adminTimeZone,
});

const shortMonthDayFormatter = new Intl.DateTimeFormat('id-ID', {
  day: 'numeric',
  month: 'short',
  timeZone: adminTimeZone,
});

const shortDateTimeFormatter = new Intl.DateTimeFormat('id-ID', {
  day: 'numeric',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
  timeZone: adminTimeZone,
});

export function formatCurrency(value: number | string | null | undefined) {
  if (value === null || value === undefined || value === '') {
    return 'Rp0';
  }

  const numericValue =
    typeof value === 'number' ? value : Number.parseFloat(String(value));

  if (Number.isNaN(numericValue)) {
    return 'Rp0';
  }

  return currencyFormatter.format(numericValue);
}

export function formatNumber(value: number | null | undefined) {
  if (value === null || value === undefined) {
    return '0';
  }

  return numberFormatter.format(value);
}

export function formatDate(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '-';
  }

  return dateFormatter.format(parsed);
}

export function formatDateTime(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '-';
  }

  return dateTimeFormatter.format(parsed);
}

export function formatShortDate(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '-';
  }

  return shortDateFormatter.format(parsed);
}

export function formatShortMonthDay(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '-';
  }

  return shortMonthDayFormatter.format(parsed);
}

export function formatShortDateTime(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return '-';
  }

  return shortDateTimeFormatter.format(parsed);
}

export function formatShortId(value: string | null | undefined) {
  if (!value) {
    return '-';
  }

  if (value.length <= 12) {
    return value;
  }

  return `${value.slice(0, 8)}...${value.slice(-4)}`;
}

export function sumNumericValues(
  values: Array<number | string | null | undefined>,
) {
  return values.reduce<number>((total, value) => {
    if (value === null || value === undefined || value === '') {
      return total;
    }

    const numericValue =
      typeof value === 'number' ? value : Number.parseFloat(String(value));

    if (Number.isNaN(numericValue)) {
      return total;
    }

    return total + numericValue;
  }, 0);
}
