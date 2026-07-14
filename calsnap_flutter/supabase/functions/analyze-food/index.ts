// Supabase Edge Function: analyze-food
// نفس منطق دالة السيرفر في الموقع، لكن كـ Edge Function للموبايل.
// النشر:  supabase functions deploy analyze-food
// السر:   supabase secrets set LOVABLE_API_KEY=xxxx
//         (أو GEMINI_API_KEY إذا أردت Google AI مباشرة)

import { createClient } from "npm:@supabase/supabase-js@2";

const SYSTEM_PROMPT = `You are a professional nutritionist AI. Analyze the food in this image and return ONLY a valid JSON object with no extra text, no markdown, no explanation. The JSON must follow this exact structure:
{
  "food_name": "string (name of the food or dish)",
  "serving_size": "string (estimated portion, e.g. '1 medium plate ~300g')",
  "calories": number (integer),
  "protein_g": number (one decimal),
  "carbs_g": number (one decimal),
  "fat_g": number (one decimal),
  "fiber_g": number (one decimal),
  "confidence_score": number (between 0 and 1),
  "notes": "string (any important notes, e.g. 'Values are estimates. Actual nutrition may vary based on preparation method.')"
}
If you cannot identify the food clearly, still return a JSON with your best estimate and a lower confidence_score.`;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    // تحقق من هوية المستخدم (JWT من تطبيق Flutter)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { imageBase64, mimeType } = await req.json();
    if (!imageBase64 || typeof imageBase64 !== "string") {
      return json({ error: "Image is required" }, 400);
    }
    if (imageBase64.length > 12_000_000) {
      return json({ error: "Image too large (max ~9MB)" }, 400);
    }

    const apiKey = Deno.env.get("LOVABLE_API_KEY");
    if (!apiKey) return json({ error: "AI is not configured" }, 500);

    const dataUrl = `data:${mimeType};base64,${imageBase64}`;

    const res = await fetch(
      "https://ai.gateway.lovable.dev/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "google/gemini-2.5-pro",
          messages: [
            { role: "system", content: SYSTEM_PROMPT },
            {
              role: "user",
              content: [
                { type: "text", text: "Analyze this food and return JSON only." },
                { type: "image_url", image_url: { url: dataUrl } },
              ],
            },
          ],
          response_format: { type: "json_object" },
        }),
      },
    );

    if (res.status === 429) {
      return json({ error: "AI is busy right now. Please try again in a moment." }, 429);
    }
    if (res.status === 402) {
      return json({ error: "AI credits exhausted." }, 402);
    }
    if (!res.ok) {
      console.error("AI gateway error", res.status, await res.text());
      return json({ error: "Could not analyze this image. Please try a clearer photo." }, 500);
    }

    const j = await res.json();
    const text: string = j?.choices?.[0]?.message?.content ?? "";
    let nutrition: unknown;
    try {
      nutrition = JSON.parse(text.replace(/```json|```/g, "").trim());
    } catch {
      return json({ error: "Could not analyze this image. Please try a clearer photo." }, 500);
    }

    return json({ nutrition });
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
