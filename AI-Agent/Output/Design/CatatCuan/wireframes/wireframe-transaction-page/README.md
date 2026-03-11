# Transaction Wireframes

This directory contains the wireframes designed for the `PENJUALAN` (Cashier/Transaction) feature.

| Screen / Flow             | Priority | Status  | File                                       | Description                                                   |
| ------------------------- | -------- | ------- | ------------------------------------------ | ------------------------------------------------------------- |
| **POS / Kasir**           | P0       | ✅ Done | [pos_cashier.md](pos_cashier.md)           | Layar utama untuk memilih produk dan menampung keranjang.     |
| **Checkout & Pembayaran** | P0       | ✅ Done | [checkout_payment.md](checkout_payment.md) | Detail item belanja, diskon, dan metode bayar (Tunai/Kasbon). |
| **Struk & Sukses**        | P0       | ✅ Done | [receipt_success.md](receipt_success.md)   | Opsi "Cetak" atau "Simpan Aja" (KEMBALI KE POS).              |

## Navigation Flow

`POS / Kasir` -> (Pilih Produk) -> (Click Cart Bottom Bar) -> `Checkout`
`Checkout` -> (Pilih Pembayaran) -> (Click Bayar) -> `Receipt`
`Receipt` -> (Simpan Aja) -> `POS / Kasir` (Reset Cart)
