# Stripe Local Test Guide (Step by Step)

Tai lieu nay huong dan test thanh toan Stripe local voi webhook cho backend.

## 1. Cai Stripe CLI

Download tai day:

https://stripe.com/docs/stripe-cli

Sau khi cai dat xong, kiem tra:

```bash
stripe --version
```

## 2. Dang nhap Stripe CLI

```bash
stripe login
```

Lenh nay se mo trinh duyet de ban xac thuc tai khoan Stripe.

## 3. Forward webhook ve localhost

Mo terminal moi va chay:

```bash
stripe listen --forward-to localhost:8080/api/payments/stripe/webhook
```

Neu thanh cong, ban se thay dong:

```text
Ready! Your webhook signing secret is whsec_xxx
```

Sao chep gia tri `whsec_xxx` de cau hinh backend.

## 4. Set webhook secret vao config

Trong file `src/main/resources/application.yml`, cap nhat:

```yaml
payment:
  stripe:
    webhook-secret: whsec_xxx
```

Ngoai ra can co day du cac key Stripe:

```yaml
payment:
  stripe:
    secret-key: sk_test_xxx
    publishable-key: pk_test_xxx
    webhook-secret: whsec_xxx
```

## 5. Chay backend

Chay API tai:

```text
http://localhost:8080
```

Dam bao endpoint webhook san sang:

```text
POST /api/payments/stripe/webhook
```

## 6. Test Payment Link

Mo Payment Link Stripe ban da tao va thanh toan bang test card:

- So the: `4242 4242 4242 4242`
- Ngay het han: `12/34`
- CVC: `123`

Neu luong xu ly dung, Stripe CLI se log event webhook gui ve backend va backend cap nhat trang thai giao dich.

## 7. Kiem tra nhanh webhook da vao backend

Ban co the theo doi log backend va log Stripe CLI:

- Stripe CLI: thay event `payment_intent.succeeded` (hoac event lien quan)
- Backend: nhan webhook, verify signature, cap nhat payment status

Neu khong thay event, kiem tra lai:

- Backend da chay dung cong `8080`
- URL forward dung: `/api/payments/stripe/webhook`
- `payment.stripe.webhook-secret` khop voi secret vua nhan tu `stripe listen`
