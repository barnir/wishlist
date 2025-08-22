import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  // This is needed if you're planning to invoke your function from a browser.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create a Supabase client with the Auth context of the logged in user.
    const userSupabaseClient = createClient(
      // Supabase API URL - env var exported by default.
      Deno.env.get('SUPABASE_URL') ?? '',
      // Supabase API ANON KEY - env var exported by default.
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      // Create client with Auth context of the user that called the function.
      // This way your row-level-security (RLS) policies are applied.
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Now we can get the session or user object
    const {
      data: { user },
    } = await userSupabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // Create admin client for database operations
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const userId = user.id

    console.log(`Starting deletion process for user: ${userId}`)

    // Delete data in cascading order to avoid foreign key constraint violations
    
    // 1. Delete user interactions and analytics
    await adminClient.from('user_interactions').delete().eq('user_id', userId)
    await adminClient.from('analytics_events').delete().eq('user_id', userId)
    await adminClient.from('performance_tests').delete().eq('user_id', userId)
    await adminClient.from('performance_metrics').delete().eq('user_id', userId)
    await adminClient.from('request_logs').delete().eq('user_id', userId)
    await adminClient.from('error_logs').delete().eq('user_id', userId)

    // 2. Delete wish item statuses where user is involved
    await adminClient.from('wish_item_statuses').delete().eq('user_id', userId)

    // 3. Delete friendships and friends where user is involved
    await adminClient.from('friendships').delete().eq('user_id', userId)
    await adminClient.from('friendships').delete().eq('friend_id', userId)
    await adminClient.from('friends').delete().eq('user_id', userId)
    await adminClient.from('friends').delete().eq('friend_id', userId)

    // 4. Delete wish items from user's wishlists (before deleting wishlists)
    const { data: userWishlists } = await adminClient
      .from('wishlists')
      .select('id')
      .eq('owner_id', userId)

    if (userWishlists && userWishlists.length > 0) {
      const wishlistIds = userWishlists.map(w => w.id)
      
      // Delete wish item statuses for items in user's wishlists
      await adminClient
        .from('wish_item_statuses')
        .delete()
        .in('wish_item_id', 
          adminClient
            .from('wish_items')
            .select('id')
            .in('wishlist_id', wishlistIds)
        )
      
      // Delete wish items from user's wishlists
      await adminClient.from('wish_items').delete().in('wishlist_id', wishlistIds)
    }

    // 5. Delete user's wishlists
    await adminClient.from('wishlists').delete().eq('owner_id', userId)

    // 6. Delete from public.users table
    await adminClient.from('users').delete().eq('id', userId)

    // 7. Finally, delete from auth.users using admin auth client
    const { error } = await adminClient.auth.admin.deleteUser(userId)

    if (error) {
      throw new Error(`Failed to delete user from auth: ${error.message}`)
    }

    console.log(`Successfully deleted user: ${userId}`)

    return new Response(JSON.stringify({ message: 'User deleted successfully' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})