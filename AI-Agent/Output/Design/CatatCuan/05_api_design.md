# CatatCuan - API Design Document

**Version:** 1.0  
**Date:** 2026-01-22  
**API Type:** REST (Supabase Auto-generated + Custom RPC)  
**Auth:** Supabase Auth (JWT)  
**Rules Applied:** RULE-API01-06

---

## 1. API Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CATATCUAN API ARCHITECTURE                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐                    ┌──────────────┐       │
│  │ FLUTTER APP  │                    │ NEXT.JS ADMIN│       │
│  │ (Mobile)     │                    │ (Web)        │       │
│  └──────┬───────┘                    └──────┬───────┘       │
│         │                                   │               │
│         └─────────────┬─────────────────────┘               │
│                       ▼                                      │
│         ┌─────────────────────────┐                         │
│         │    SUPABASE GATEWAY     │                         │
│         │  ┌─────────────────┐    │                         │
│         │  │ PostgREST API   │────┼── Auto CRUD             │
│         │  ├─────────────────┤    │                         │
│         │  │ RPC Functions   │────┼── Custom Logic          │
│         │  ├─────────────────┤    │                         │
│         │  │ Supabase Auth   │────┼── JWT Auth              │
│         │  ├─────────────────┤    │                         │
│         │  │ Storage         │────┼── File Upload           │
│         │  └─────────────────┘    │                         │
│         └─────────────────────────┘                         │
│                       │                                      │
│                       ▼                                      │
│         ┌─────────────────────────┐                         │
│         │     POSTGRESQL 15       │                         │
│         │     + Row Level Security│                         │
│         └─────────────────────────┘                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Base URL & Versioning

| Environment | Base URL |
|-------------|----------|
| **Supabase API** | `https://{project-id}.supabase.co/rest/v1` |
| **Supabase Auth** | `https://{project-id}.supabase.co/auth/v1` |
| **Admin API** (Next.js) | `https://admin.catatcuan.id/api/v1` |

> **Note:** Supabase handles versioning internally. Custom admin API uses `/api/v1`.

---

## 3. Authentication (RULE-API04)

### 3.1 Auth Flow

```
┌─────────┐         ┌─────────────┐         ┌──────────┐
│ Mobile  │         │  Supabase   │         │ Database │
│  App    │         │    Auth     │         │ (RLS)    │
└────┬────┘         └──────┬──────┘         └────┬─────┘
     │                     │                     │
     │ 1. Login (phone)    │                     │
     ├────────────────────►│                     │
     │                     │                     │
     │ 2. JWT Token        │                     │
     │◄────────────────────┤                     │
     │                     │                     │
     │ 3. API Request      │                     │
     │   + Bearer Token    │                     │
     ├────────────────────►│ 4. Validate JWT    │
     │                     ├────────────────────►│
     │                     │ 5. Apply RLS        │
     │                     │◄────────────────────┤
     │ 6. Response         │                     │
     │◄────────────────────┤                     │
```

### 3.2 Auth Endpoints

| Method | Endpoint | Description | Public |
|--------|----------|-------------|--------|
| POST | `/auth/v1/signup` | Register with phone + password | ✅ Yes |
| POST | `/auth/v1/token?grant_type=password` | Login | ✅ Yes |
| POST | `/auth/v1/logout` | Logout | 🔒 Auth |
| POST | `/auth/v1/recover` | Password recovery | ✅ Yes |
| GET | `/auth/v1/user` | Get current user | 🔒 Auth |
| PATCH | `/auth/v1/user` | Update user | 🔒 Auth |

### 3.3 JWT Token Structure

```json
{
  "aud": "authenticated",
  "exp": 1706000000,
  "sub": "user-uuid-here",
  "email": null,
  "phone": "+6281234567890",
  "role": "authenticated",
  "app_metadata": {},
  "user_metadata": {}
}
```

---

## 4. API Endpoints (PostgREST)

### 4.1 Warung (Store Profile)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/warung` | Get user's warung | 🔒 Owner |
| GET | `/rest/v1/warung?select=*,produk(*)` | With products | 🔒 Owner |
| POST | `/rest/v1/warung` | Create warung (first-time setup) | 🔒 Auth |
| PATCH | `/rest/v1/warung?id=eq.{id}` | Update warung | 🔒 Owner |

### 4.2 Produk (Products)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/produk?warung_id=eq.{id}` | List products | 🔒 Owner |
| GET | `/rest/v1/produk?warung_id=eq.{id}&is_active=eq.true` | Active only | 🔒 Owner |
| GET | `/rest/v1/produk?barcode=eq.{code}` | Find by barcode | 🔒 Owner |
| POST | `/rest/v1/produk` | Create product | 🔒 Owner |
| PATCH | `/rest/v1/produk?id=eq.{id}` | Update product | 🔒 Owner |
| DELETE | `/rest/v1/produk?id=eq.{id}` | Delete product | 🔒 Owner |

### 4.3 Pelanggan (Customers)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/pelanggan?warung_id=eq.{id}` | List customers | 🔒 Owner |
| GET | `/rest/v1/pelanggan?id=eq.{id}&select=*,hutang(*)` | With debts | 🔒 Owner |
| POST | `/rest/v1/pelanggan` | Create customer | 🔒 Owner |
| PATCH | `/rest/v1/pelanggan?id=eq.{id}` | Update customer | 🔒 Owner |
| DELETE | `/rest/v1/pelanggan?id=eq.{id}` | Delete customer | 🔒 Owner |

### 4.4 Penjualan (Sales)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/penjualan?warung_id=eq.{id}&order=tanggal.desc` | List sales | 🔒 Owner |
| GET | `/rest/v1/penjualan?id=eq.{id}&select=*,penjualan_item(*)` | With items | 🔒 Owner |
| GET | `/rest/v1/penjualan?tanggal=gte.{date}` | Filter by date | 🔒 Owner |
| POST | `/rest/v1/rpc/create_penjualan` | Create sale (RPC) | 🔒 Owner |
| PATCH | `/rest/v1/penjualan?id=eq.{id}` | Update sale | 🔒 Owner |

### 4.5 Pengeluaran (Expenses)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/pengeluaran?warung_id=eq.{id}` | List expenses | 🔒 Owner |
| GET | `/rest/v1/pengeluaran?kategori_id=eq.{id}` | Filter by category | 🔒 Owner |
| POST | `/rest/v1/pengeluaran` | Create expense | 🔒 Owner |
| PATCH | `/rest/v1/pengeluaran?id=eq.{id}` | Update expense | 🔒 Owner |
| DELETE | `/rest/v1/pengeluaran?id=eq.{id}` | Delete expense | 🔒 Owner |

### 4.6 Buku Kas (Cash Book)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/buku_kas?warung_id=eq.{id}&order=tanggal.desc` | List mutations | 🔒 Owner |
| GET | `/rest/v1/buku_kas?tanggal=gte.{date}&tanggal=lte.{date}` | Date range | 🔒 Owner |
| GET | `/rest/v1/rpc/get_saldo_kas` | Get current balance | 🔒 Owner |

### 4.7 Hutang (Debts)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/hutang?warung_id=eq.{id}` | List all debts | 🔒 Owner |
| GET | `/rest/v1/hutang?status=eq.belum_lunas` | Unpaid only | 🔒 Owner |
| GET | `/rest/v1/hutang?pelanggan_id=eq.{id}` | By customer | 🔒 Owner |
| POST | `/rest/v1/rpc/bayar_hutang` | Pay debt (RPC) | 🔒 Owner |

### 4.8 Laporan (Reports)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/rest/v1/laporan_harian?tanggal=eq.{date}` | Daily report | 🔒 Owner |
| GET | `/rest/v1/rpc/get_weekly_report` | Weekly summary | 🔒 Owner |
| GET | `/rest/v1/rpc/get_monthly_report` | Monthly summary | 🔒 Owner |
| GET | `/rest/v1/rpc/get_produk_terlaris` | Top products | 🔒 Owner |

---

## 5. RPC Functions (Custom Business Logic)

### 5.1 create_penjualan

```sql
CREATE OR REPLACE FUNCTION create_penjualan(
    p_warung_id UUID,
    p_pelanggan_id UUID DEFAULT NULL,
    p_payment_method payment_method,
    p_amount_paid DECIMAL,
    p_items JSONB
) RETURNS UUID AS $$
DECLARE
    v_penjualan_id UUID;
    v_total DECIMAL := 0;
    v_item JSONB;
BEGIN
    -- Calculate total
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_total := v_total + (v_item->>'subtotal')::DECIMAL;
    END LOOP;
    
    -- Create penjualan header
    INSERT INTO penjualan (warung_id, pelanggan_id, invoice_no, total_amount, amount_paid, amount_change, payment_method)
    VALUES (p_warung_id, p_pelanggan_id, generate_invoice_no(), v_total, p_amount_paid, p_amount_paid - v_total, p_payment_method)
    RETURNING id INTO v_penjualan_id;
    
    -- Create items
    INSERT INTO penjualan_item (penjualan_id, produk_id, nama_produk, quantity, harga_satuan, subtotal)
    SELECT v_penjualan_id, (item->>'produk_id')::UUID, item->>'nama_produk', 
           (item->>'quantity')::INT, (item->>'harga_satuan')::DECIMAL, (item->>'subtotal')::DECIMAL
    FROM jsonb_array_elements(p_items) AS item;
    
    -- Update stock
    UPDATE produk SET stok_saat_ini = stok_saat_ini - (item->>'quantity')::INT
    FROM jsonb_array_elements(p_items) AS item
    WHERE produk.id = (item->>'produk_id')::UUID;
    
    -- Create buku_kas entry
    INSERT INTO buku_kas (warung_id, tipe, sumber, reference_id, reference_type, amount, saldo_setelah, keterangan)
    VALUES (p_warung_id, 'masuk', 'penjualan', v_penjualan_id, 'penjualan', p_amount_paid, get_saldo_kas(p_warung_id), 'Penjualan #' || generate_invoice_no());
    
    -- If hutang, create hutang record
    IF p_payment_method = 'hutang' THEN
        INSERT INTO hutang (warung_id, pelanggan_id, penjualan_id, amount_awal, amount_sisa)
        VALUES (p_warung_id, p_pelanggan_id, v_penjualan_id, v_total, v_total);
    END IF;
    
    RETURN v_penjualan_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 5.2 bayar_hutang

```sql
CREATE OR REPLACE FUNCTION bayar_hutang(
    p_hutang_id UUID,
    p_amount DECIMAL,
    p_metode VARCHAR DEFAULT 'tunai'
) RETURNS BOOLEAN AS $$
DECLARE
    v_warung_id UUID;
    v_sisa DECIMAL;
BEGIN
    -- Get current debt
    SELECT warung_id, amount_sisa INTO v_warung_id, v_sisa
    FROM hutang WHERE id = p_hutang_id;
    
    -- Create payment record
    INSERT INTO pembayaran_hutang (hutang_id, amount, metode_bayar)
    VALUES (p_hutang_id, p_amount, p_metode);
    
    -- Update hutang
    UPDATE hutang SET 
        amount_terbayar = amount_terbayar + p_amount,
        amount_sisa = amount_sisa - p_amount,
        status = CASE WHEN amount_sisa - p_amount <= 0 THEN 'lunas' ELSE status END
    WHERE id = p_hutang_id;
    
    -- Update buku_kas
    INSERT INTO buku_kas (warung_id, tipe, sumber, reference_id, reference_type, amount, saldo_setelah, keterangan)
    VALUES (v_warung_id, 'masuk', 'hutang_bayar', p_hutang_id, 'hutang', p_amount, get_saldo_kas(v_warung_id), 'Pembayaran Hutang');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 5.3 get_saldo_kas

```sql
CREATE OR REPLACE FUNCTION get_saldo_kas(p_warung_id UUID)
RETURNS DECIMAL AS $$
DECLARE
    v_saldo DECIMAL;
BEGIN
    SELECT COALESCE(
        (SELECT saldo_awal FROM warung WHERE id = p_warung_id), 0
    ) + COALESCE(
        (SELECT SUM(CASE WHEN tipe = 'masuk' THEN amount ELSE -amount END) 
         FROM buku_kas WHERE warung_id = p_warung_id), 0
    ) INTO v_saldo;
    
    RETURN v_saldo;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 6. Admin API (Next.js Routes)

### 6.1 Dashboard Statistics

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v1/stats/users` | Total users count | 🔒 Admin |
| GET | `/api/v1/stats/transactions` | Total transactions volume | 🔒 Admin |
| GET | `/api/v1/stats/growth` | User growth chart data | 🔒 Admin |

### 6.2 User Management

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v1/users` | List all warung users | 🔒 Admin |
| GET | `/api/v1/users/:id` | Get user detail | 🔒 Admin |
| PATCH | `/api/v1/users/:id/status` | Activate/Suspend user | 🔒 Admin |
| POST | `/api/v1/users/:id/reset-password` | Trigger password reset | 🔒 Admin |

### 6.3 System Config

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v1/config` | Get all config | 🔒 Admin |
| PATCH | `/api/v1/config/maintenance` | Toggle maintenance mode | 🔒 Admin |
| PATCH | `/api/v1/config/min-version` | Set minimum app version | 🔒 Admin |

### 6.4 Master Data

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/v1/master/categories` | List default categories | 🔒 Admin |
| POST | `/api/v1/master/categories` | Create category | 🔒 Admin |
| PATCH | `/api/v1/master/categories/:id` | Update category | 🔒 Admin |
| DELETE | `/api/v1/master/categories/:id` | Delete category | 🔒 Admin |

---

## 7. Response Envelope (RULE-API06)

### 7.1 Success Response

```json
{
  "data": {
    "id": "uuid",
    "nama_produk": "Indomie Goreng",
    "harga_jual": 3500
  }
}
```

### 7.2 List Response (with Pagination)

```json
{
  "data": [
    { "id": "uuid", "nama_produk": "Indomie Goreng" },
    { "id": "uuid", "nama_produk": "Aqua 600ml" }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "limit": 20,
    "totalPages": 8
  }
}
```

### 7.3 Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Harga jual harus lebih dari 0",
    "details": {
      "field": "harga_jual",
      "value": -100
    }
  }
}
```

---

## 8. Status Codes (RULE-API03)

| Status | When | Example |
|--------|------|---------|
| **200** | GET success | Get product list |
| **201** | POST created | Create new product |
| **204** | DELETE success | Delete product |
| **400** | Bad request | Missing required field |
| **401** | Unauthorized | No/expired JWT |
| **403** | Forbidden | Access other warung's data |
| **404** | Not found | Product doesn't exist |
| **409** | Conflict | Duplicate barcode |
| **422** | Validation error | Invalid data format |
| **429** | Rate limited | Too many requests |
| **500** | Server error | Database connection failed |

---

## 9. Rate Limiting (RULE-API05)

| Client Type | Limit | Window |
|-------------|-------|--------|
| **Public** | 60 requests | 1 minute |
| **Authenticated** | 200 requests | 1 minute |
| **Admin** | 500 requests | 1 minute |

---

## 10. Security Headers

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
```

---

## 11. CORS Configuration

```javascript
// Supabase handles CORS automatically

// Next.js Admin API
const corsOptions = {
  origin: [
    'https://admin.catatcuan.id',
    'http://localhost:3000' // Development
  ],
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  credentials: true
};
```

---

## ✅ Output Checklist

- [x] API type determined (REST via Supabase)
- [x] Entities mapped to endpoints (17 tables)
- [x] Endpoints listed with auth levels
- [x] Response envelope defined (RULE-API06)
- [x] Authentication configured (Supabase JWT)
- [x] Rate limiting configured (RULE-API05)
- [x] Status codes documented (RULE-API03)
- [x] CORS configured
- [x] Security headers documented
- [x] RPC functions defined (3 custom functions)
- [x] Admin API routes defined

---

*Generated by /design-api workflow (WF-API01)*
*Rules Applied: RULE-API01-06*
