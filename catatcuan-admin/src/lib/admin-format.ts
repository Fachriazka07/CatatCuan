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
});

const dateTimeFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
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
  return values.reduce((total, value) => {
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
