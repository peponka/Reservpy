// supabase/functions/ai-generate/index.ts
// Genera texto con Gemini para el panel de negocios.
// Actualmente soporta: service_description.

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GEMINI_MODELS = [
  "gemini-2.0-flash",
  "gemini-2.5-flash-lite",
  "gemini-2.5-flash",
];

function geminiUrl(model: string): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function callGemini(
  apiKey: string,
  prompt: string,
  maxTokens = 150,
): Promise<string> {
  for (const model of GEMINI_MODELS) {
    const res = await fetch(`${geminiUrl(model)}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: maxTokens, temperature: 0.7 },
      }),
    });

    if (res.status === 429 || res.status === 503) continue; // try next model

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Gemini error (${res.status}): ${err}`);
    }

    const data = await res.json();
    return (data.candidates?.[0]?.content?.parts?.[0]?.text ?? "").trim();
  }
  throw new Error("All Gemini models exhausted");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return json({ error: "GEMINI_API_KEY not configured" }, 500);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { type, serviceName, businessCategory } = body as {
    type?: string;
    serviceName?: string;
    businessCategory?: string;
  };

  if (type === "review_analysis") {
    const { comments, avgRating, totalCount, businessName } = body as {
      comments?: string;
      avgRating?: number;
      totalCount?: number;
      businessName?: string;
    };

    if (!comments || String(comments).trim().length < 10) {
      return json({ text: "" }); // not enough content
    }

    const prompt =
      `Sos asistente de ReservPy, app de reservas en Paraguay.
Analizá las siguientes reseñas de clientes del negocio "${businessName ?? "este negocio"}" (promedio: ${(avgRating ?? 0).toFixed(1)}★ sobre ${totalCount ?? 0} reseñas):

${String(comments).trim()}

Respondé con exactamente 3 líneas separadas por salto de línea, sin numeración, sin títulos, sin emojis:
1. Un elogio concreto que los clientes mencionan frecuentemente.
2. Una oportunidad de mejora concreta que aparece en las reseñas.
3. Un tip accionable corto para mejorar la experiencia.
Cada línea máximo 90 caracteres.`;

    try {
      const text = await callGemini(apiKey, prompt, 200);
      return json({ text });
    } catch (e) {
      return json({ error: String(e) }, 502);
    }
  }

  if (type === "service_description") {
    if (!serviceName || String(serviceName).trim().length < 2) {
      return json({ error: "serviceName is required" }, 400);
    }

    const name = String(serviceName).trim();
    const category = businessCategory ? String(businessCategory).trim() : null;

    const prompt =
      `Sos asistente de un negocio en Paraguay que usa ReservPy, una app de reservas online.
El dueño quiere una descripción atractiva para el servicio llamado "${name}"${category ? ` (rubro: ${category})` : ""}.
Escribí UNA descripción corta, máximo 100 caracteres, en español rioplatense, clara y profesional.
Responde ÚNICAMENTE con el texto de la descripción. Sin comillas, sin punto final, sin explicaciones.`;

    try {
      const text = await callGemini(apiKey, prompt, 80);
      return json({ text });
    } catch (e) {
      return json({ error: String(e) }, 502);
    }
  }

  return json({ error: `Unknown type: "${type}"` }, 400);
});
