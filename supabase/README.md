# Supabase Backend Setup for Push Notifications

This guide walks you through deploying the Edge Function and setting up database webhooks in Supabase to dispatch notifications when a session starts.

---

## 1. Supabase Edge Function Code

Create a new function under `supabase/functions/send-session-notification/index.ts` with the following Deno/TypeScript content:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const FIREBASE_PROJECT_ID = "YOUR_FIREBASE_PROJECT_ID"
// Obtain this credential by generating a new Private Key from your Firebase Console:
// Project Settings -> Service Accounts -> Generate New Private Key
const FIREBASE_SERVICE_ACCOUNT = {
  type: "service_account",
  project_id: FIREBASE_PROJECT_ID,
  private_key_id: "...",
  private_key: "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  client_email: "...",
}

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Fetch all registered device tokens
    const { data: tokensData, error: tokensError } = await supabaseClient
      .from('device_tokens')
      .select('token')

    if (tokensError) throw tokensError

    const tokens = tokensData.map((d: any) => d.token)
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ message: "No tokens registered" }), { status: 200 })
    }

    // 2. Generate Google OAuth2 token for Firebase Messaging API v1
    const accessToken = await getGoogleAccessToken(FIREBASE_SERVICE_ACCOUNT)

    // 3. Send Notification payload to all tokens via FCM
    const results = await Promise.all(
      tokens.map(token => sendFcmMessage(token, accessToken))
    )

    return new Response(JSON.stringify({ success: true, dispatched: tokens.length, results }), { status: 200 })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})

async function sendFcmMessage(token: string, accessToken: string) {
  const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      message: {
        token: token,
        notification: {
          title: "FeastPool Started! 🍔",
          body: "Order window is open for 15 minutes. Add your meals now!"
        },
        webpush: {
          notification: {
            icon: "/favicon.png"
          }
        }
      }
    })
  })
  return res.json()
}

// OAuth2 helper to fetch token from Google
async function getGoogleAccessToken(serviceAccount: any): Promise<string> {
  // Use a standard library/package or custom JWT signing to generate OAuth tokens in Deno
  // For easy deployment, you can import: "https://esm.sh/google-auth-library" or use Deno Google Auth helpers.
  return "ACCESS_TOKEN"
}
```

---

## 2. Setting up the Database Trigger

Run this SQL in your Supabase SQL Editor to trigger the function automatically whenever a session starts:

```sql
-- Create a trigger function that fires an HTTP request to your Edge Function
create or replace function public.notify_session_started()
returns trigger as $$
begin
  perform
    net.http_post(
      url := 'https://<your-project-ref>.supabase.co/functions/v1/send-session-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || auth.role_key() -- Uses service role key for authentication
      ),
      body := '{}'::jsonb
    );
  return new;
end;
$$ language plpgsql security definer;

-- Bind the trigger to target pool_sessions inserts
create trigger on_pool_session_inserted
  after insert on public.pool_sessions
  for each row
  when (new.is_active = true)
  execute function public.notify_session_started();
```
