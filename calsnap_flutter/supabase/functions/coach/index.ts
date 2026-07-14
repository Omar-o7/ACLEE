// Supabase Edge Function: coach
// مدرب التغذية "أليكس" — نفس منطق الموقع مع سياق آخر 7 أيام من سجلات المستخدم.
// النشر:  supabase functions deploy coach

import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type LogRow = {
  logged_at: string;
  food_name: string;
  meal_type: string;
  calories: number | null;
  protein_g: number | null;
};

function summarizeLogs(logs: LogRow[]): string {
  if (!logs.length) return "(no recent food logs)";
  const byDay = new Map<string, LogRow[]>();
  for (const l of logs) {
    const day = l.logged_at.slice(0, 10);
    const arr = byDay.get(day) ?? [];
    arr.push(l);
    byDay.set(day, arr);
  }
  const lines: string[] = [];
  for (const d of Array.from(byDay.keys()).sort().reverse()) {
    const items = byDay.get(d)!;
    const total = items.reduce((s, x) => s + (x.calories ?? 0), 0);
    const p = items.reduce((s, x) => s + Number(x.protein_g ?? 0), 0);
    lines.push(
      `- ${d} (${total} kcal, ${Math.round(p)}g protein): ${
        items.map((x) => `${x.meal_type} ${x.food_name} ${x.calories ?? 0}kcal`).join("; ")
      }`,
    );
  }
  return lines.join("\n");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "Unauthorized" }, 401);

    const { message, history = [] } = await req.json();
    if (!message || typeof message !== "string" || message.length > 4000) {
      return json({ error: "Invalid message" }, 400);
    }

    const apiKey = Deno.env.get("LOVABLE_API_KEY");
    if (!apiKey) return json({ error: "AI is not configured" }, 500);

    // Personal context: profile + last 7 days of logs
    const { data: profile } = await supabase
      .from("profiles")
      .select("name,daily_calorie_goal")
      .eq("id", user.id)
      .maybeSingle();

    const sevenAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const { data: logs } = await supabase
      .from("food_logs")
      .select("logged_at,food_name,meal_type,calories,protein_g")
      .eq("user_id", user.id)
      .gte("logged_at", sevenAgo)
      .order("logged_at", { ascending: false });

    const systemPrompt =
      `You are Alex, a world-class AI nutrition coach inside the CalSnap app. You are warm, motivating, and evidence-based. You have access to the user's recent food history and goals shown below. Use this data to give personalized, specific advice — never generic responses.

User name: ${profile?.name ?? "friend"}
Daily calorie goal: ${profile?.daily_calorie_goal ?? 2000} kcal
Last 7 days of food logs:
${summarizeLogs((logs ?? []) as LogRow[])}

Capabilities: analyze patterns, suggest healthier alternatives, build weekly meal plans on request, explain the science, motivate the user. Always reference their actual data. Be conversational, not clinical. Use emojis occasionally. Keep responses concise unless they ask for a detailed plan. Reply in the same language the user writes in (Arabic or English).`;

    const messages = [
      { role: "system", content: systemPrompt },
      ...history.slice(-30),
      { role: "user", content: message },
    ];

    const res = await fetch(
      "https://ai.gateway.lovable.dev/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({ model: "google/gemini-2.5-flash", messages }),
      },
    );

    if (res.status === 429) {
      return json({ error: "AI is busy right now. Please try again." }, 429);
    }
    if (!res.ok) {
      console.error("AI gateway error", res.status, await res.text());
      return json({ error: "Coach is unavailable right now." }, 500);
    }

    const j = await res.json();
    const reply: string = j?.choices?.[0]?.message?.content ?? "...";
    return json({ reply });
  } catch (e) {
    console.error(e);
    return json({ error: "Unexpected error" }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
