# PointStore

Production-ready Next.js + Supabase crypto points store.

## Deploy
1. Create a Supabase project.
2. Supabase → SQL Editor → paste `supabase/schema.sql` → Run.
3. Create a GitHub repository and upload this folder.
4. Import the repository into Vercel.
5. Add the variables from `.env.example` in Vercel.
6. Set `NEXT_PUBLIC_SITE_URL` to the Vercel URL.
7. Create a NOWPayments account and add its API key + IPN secret if you want live crypto point purchases.
8. In NOWPayments set the IPN callback to `https://YOUR-DOMAIN/api/payments/webhook`.

## Make yourself admin
After creating your account, run in Supabase SQL Editor:

`update profiles set role='admin' where email='YOUR_EMAIL';`

## Local
`npm install`
`npm run dev`

The app will run at http://localhost:3000.

Never commit `.env.local`, service-role keys, or payment secrets.
