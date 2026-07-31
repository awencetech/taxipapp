Email API (examples)

Base URL: http://localhost:5000/api/v1/email

1) Send OTP
POST /send-otp
Body (JSON): { "email": "user@example.com", "otp": "123456", "name": "User" }

2) Send Verification
POST /send-verification
Body: { "email": "user@example.com", "link": "https://app/verify?token=abc", "name": "User" }

3) Forgot Password
POST /forgot-password
Body: { "email": "user@example.com", "link": "https://app/reset?token=abc", "name": "User" }

4) Generic Send
POST /send
Body: { "to": "user@example.com", "subject": "Hello", "template": "welcome", "variables": { "name": "User" } }

Notes:
- Ensure backend has SMTP env vars set in `.env` (SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS).
- These endpoints are intended for internal/backend usage; restrict access via auth if exposing to clients.
