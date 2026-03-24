import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// RevenueCat signs webhook payloads with this secret.
// Set it in Supabase Dashboard → Edge Functions → Secrets:
// REVENUECAT_WEBHOOK_SECRET
const WEBHOOK_SECRET = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? '';

serve(async (req: Request) => {
  // Validate RevenueCat webhook signature header.
  const authHeader = req.headers.get('Authorization');
  if (!WEBHOOK_SECRET || authHeader !== `Bearer ${WEBHOOK_SECRET}`) {
    return new Response('Unauthorized', { status: 401 });
  }

  const payload = await req.json();
  const event = payload?.event;

  if (!event) {
    return new Response('Bad Request', { status: 400 });
  }

  // RevenueCat app_user_id is the Supabase user UUID set in
  // SubscriptionService.init(). Used to locate the correct row.
  const userId: string = event.app_user_id;
  const eventType: string = event.type;
  const expiresAtMs: number | null = event.expiration_at_ms ?? null;

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  // Map RevenueCat event types to subscription_status values.
  // Full event type reference:
  // https://www.revenuecat.com/docs/webhooks#event-types
  let subscriptionStatus: string;
  let isPaidSubscriber: boolean;

  switch (eventType) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'REACTIVATION':
      subscriptionStatus = 'active';
      isPaidSubscriber = true;
      break;

    case 'CANCELLATION':
      // Cancelled but still within paid period — still active until expiry.
      subscriptionStatus = 'cancelled';
      isPaidSubscriber = true;
      break;

    case 'EXPIRATION':
    case 'BILLING_ISSUE':
      subscriptionStatus = 'expired';
      isPaidSubscriber = false;
      break;

    case 'TRIAL_STARTED':
      // RevenueCat trial — distinct from ZenForest's own 5-day app trial.
      // Only fires if store-level trial is configured in Play Console.
      subscriptionStatus = 'trial';
      isPaidSubscriber = false;
      break;

    default:
      // Unhandled event type — log and return 200 to prevent RC retries.
      console.log(`Unhandled RC event type: ${eventType}`);
      return new Response('OK', { status: 200 });
  }

  const expiresAt = expiresAtMs
    ? new Date(expiresAtMs).toISOString()
    : null;

  const { error } = await supabase
    .from('user_economy')
    .update({
      is_paid_subscriber: isPaidSubscriber,
      subscription_status: subscriptionStatus,
      subscription_expires_at: expiresAt,
      premium_source: isPaidSubscriber ? 'revenuecat' : 'none',
    })
    .eq('id', userId);

  if (error) {
    console.error(`Webhook DB update failed for user ${userId}:`, error);
    // Return 500 so RevenueCat retries the webhook.
    return new Response('Internal Server Error', { status: 500 });
  }

  console.log(
    `RC webhook processed: user=${userId} event=${eventType} status=${subscriptionStatus}`,
  );
  return new Response('OK', { status: 200 });
});
