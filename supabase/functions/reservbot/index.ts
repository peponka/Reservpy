// supabase/functions/reservbot/index.ts
// Reservbot — asistente IA del panel de negocios (Gemini API con function calling).
// Stateless: el historial de mensajes (formato Gemini "contents") viaja con cada request.
// Las tools de consulta se ejecutan acá con el JWT del usuario (RLS aplica).
// cancel_reservation NUNCA se ejecuta sin confirmación: se devuelve como
// pending_action y el cliente la confirma en una segunda llamada.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Modelos en orden de preferencia — si uno está saturado (429/503) se prueba el siguiente.
const MODELS = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-2.5-flash-lite"];
const geminiUrl = (model: string) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
const MAX_LOOPS = 6;
// Paraguay no usa horario de verano desde 2024 — UTC-3 fijo.
const TZ_OFFSET = "-03:00";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function todayInAsuncion(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Asuncion",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

function nextDate(date: string): string {
  const d = new Date(`${date}T00:00:00${TZ_OFFSET}`);
  d.setUTCDate(d.getUTCDate() + 1);
  return d.toISOString().slice(0, 10);
}

/** HH:mm legible desde un timestamp ISO tal como está guardado. */
function hhmm(iso: string): string {
  const m = iso.match(/T(\d{2}:\d{2})/);
  return m ? m[1] : iso;
}

// ─── Declaración de tools (formato Gemini) ──────────────────

const FUNCTION_DECLARATIONS = [
  {
    name: "get_agenda",
    description:
      "Devuelve los turnos (reservas) del negocio para una fecha dada. Usala cuando el dueño pregunta qué turnos tiene un día, cuántas reservas hay, o quién viene.",
    parameters: {
      type: "object",
      properties: {
        date: { type: "string", description: "Fecha en formato YYYY-MM-DD" },
      },
      required: ["date"],
    },
  },
  {
    name: "find_gaps",
    description:
      "Calcula los huecos libres en la agenda de una fecha, según el horario de apertura/cierre y la duración de turno configurada. Usala cuando preguntan por disponibilidad o huecos.",
    parameters: {
      type: "object",
      properties: {
        date: { type: "string", description: "Fecha en formato YYYY-MM-DD" },
      },
      required: ["date"],
    },
  },
  {
    name: "get_reservations_by_client",
    description:
      "Busca reservas próximas por nombre de cliente (búsqueda parcial, sin distinguir mayúsculas). Usala antes de cancelar si solo te dan un nombre.",
    parameters: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Nombre (o parte del nombre) del cliente",
        },
      },
      required: ["name"],
    },
  },
  {
    name: "cancel_reservation",
    description:
      "Cancela un turno. ANTES de llamar esta función tenés que estar seguro de qué reserva es (usá get_agenda o get_reservations_by_client para obtener el id). El sistema pide confirmación al dueño antes de ejecutar — no necesitás pedirla vos en texto. Llamá esta función SOLA, sin combinarla con otras.",
    parameters: {
      type: "object",
      properties: {
        reservation_id: {
          type: "string",
          description: "UUID de la reserva a cancelar",
        },
        description: {
          type: "string",
          description:
            "Descripción corta y legible del turno (ej: 'Corte de Martina a las 15:00 del 12/06') para mostrar en la confirmación",
        },
        reason: {
          type: "string",
          description: "Motivo de cancelación si el dueño lo indicó",
        },
      },
      required: ["reservation_id", "description"],
    },
  },
];

// ─── Ejecución de tools (con el client del usuario — RLS aplica) ───

// deno-lint-ignore no-explicit-any
async function runGetAgenda(supabase: any, businessId: string, date: string) {
  const { data, error } = await supabase
    .from("reservations")
    .select(
      "id, start_time, end_time, status, is_manual, manual_client_name, notes, services(name), profiles(first_name, last_name)",
    )
    .eq("business_id", businessId)
    .gte("start_time", `${date}T00:00:00`)
    .lt("start_time", `${nextDate(date)}T00:00:00`)
    .neq("status", "cancelled")
    .order("start_time");
  if (error) return { error: error.message };
  // deno-lint-ignore no-explicit-any
  const rows = (data ?? []).map((r: any) => ({
    id: r.id,
    hora: hhmm(r.start_time),
    hora_fin: hhmm(r.end_time),
    servicio: r.services?.name ?? "(sin servicio)",
    cliente: r.profiles
      ? `${r.profiles.first_name} ${r.profiles.last_name}`
      : r.manual_client_name ?? "(sin nombre)",
    estado: r.status,
    notas: r.notes ?? undefined,
  }));
  return { fecha: date, total: rows.length, turnos: rows };
}

// deno-lint-ignore no-explicit-any
async function runFindGaps(supabase: any, business: any, date: string) {
  const agenda = await runGetAgenda(supabase, business.id, date);
  if ("error" in agenda) return agenda;

  const { data: blocked } = await supabase
    .from("blocked_slots")
    .select("start_time, end_time")
    .eq("business_id", business.id)
    .gte("start_time", `${date}T00:00:00`)
    .lt("start_time", `${nextDate(date)}T00:00:00`);

  const toMin = (t: string) => {
    const [h, m] = t.split(":").map(Number);
    return h * 60 + m;
  };
  const open = toMin(business.opening_time ?? "09:00");
  const close = toMin(business.closing_time ?? "18:00");
  const slot = business.slot_duration_minutes ?? 30;

  const busy: Array<[number, number]> = [
    // deno-lint-ignore no-explicit-any
    ...agenda.turnos.map((t: any) =>
      [toMin(t.hora), toMin(t.hora_fin)] as [number, number]
    ),
    // deno-lint-ignore no-explicit-any
    ...(blocked ?? []).map((b: any) =>
      [toMin(hhmm(b.start_time)), toMin(hhmm(b.end_time))] as [number, number]
    ),
  ];

  const gaps: string[] = [];
  for (let t = open; t + slot <= close; t += slot) {
    const overlaps = busy.some(([s, e]) => t < e && t + slot > s);
    if (!overlaps) {
      gaps.push(
        `${String(Math.floor(t / 60)).padStart(2, "0")}:${
          String(t % 60).padStart(2, "0")
        }`,
      );
    }
  }
  return {
    fecha: date,
    horario: `${business.opening_time} a ${business.closing_time}`,
    duracion_turno_min: slot,
    huecos_libres: gaps,
    total_huecos: gaps.length,
  };
}

// deno-lint-ignore no-explicit-any
async function runFindByClient(supabase: any, businessId: string, name: string) {
  const today = todayInAsuncion();
  const { data, error } = await supabase
    .from("reservations")
    .select(
      "id, start_time, status, is_manual, manual_client_name, services(name), profiles(first_name, last_name)",
    )
    .eq("business_id", businessId)
    .gte("start_time", `${today}T00:00:00`)
    .neq("status", "cancelled")
    .order("start_time")
    .limit(50);
  if (error) return { error: error.message };
  const q = name.toLowerCase();
  // deno-lint-ignore no-explicit-any
  const rows = (data ?? []).filter((r: any) => {
    const joined = r.profiles
      ? `${r.profiles.first_name} ${r.profiles.last_name}`
      : r.manual_client_name ?? "";
    return joined.toLowerCase().includes(q);
    // deno-lint-ignore no-explicit-any
  }).map((r: any) => ({
    id: r.id,
    fecha: r.start_time.slice(0, 10),
    hora: hhmm(r.start_time),
    servicio: r.services?.name ?? "(sin servicio)",
    cliente: r.profiles
      ? `${r.profiles.first_name} ${r.profiles.last_name}`
      : r.manual_client_name,
    estado: r.status,
  }));
  return { busqueda: name, encontradas: rows.length, reservas: rows };
}

async function runCancel(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  businessId: string,
  reservationId: string,
  reason?: string,
) {
  const { data, error } = await supabase
    .from("reservations")
    .update({
      status: "cancelled",
      cancellation_reason: reason ?? "Cancelado por el negocio vía Reservbot",
    })
    .eq("id", reservationId)
    .eq("business_id", businessId)
    .select("id")
    .maybeSingle();
  if (error) return { error: error.message };
  if (!data) {
    return { error: "No se encontró la reserva o no pertenece a tu negocio" };
  }
  return { ok: true, cancelada: reservationId };
}

// deno-lint-ignore no-explicit-any
async function executeQueryTool(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  // deno-lint-ignore no-explicit-any
  business: any,
  name: string,
  args: Record<string, unknown>,
): Promise<unknown> {
  switch (name) {
    case "get_agenda":
      return await runGetAgenda(supabase, business.id, String(args.date));
    case "find_gaps":
      return await runFindGaps(supabase, business, String(args.date));
    case "get_reservations_by_client":
      return await runFindByClient(supabase, business.id, String(args.name));
    default:
      return { error: `Función desconocida: ${name}` };
  }
}

// ─── Handler principal ─────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "Unauthorized" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } } },
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Solo dueños de negocio: buscamos el negocio del usuario autenticado.
  const { data: business, error: bizErr } = await supabase
    .from("businesses")
    .select(
      "id, name, opening_time, closing_time, slot_duration_minutes, working_days",
    )
    .eq("owner_id", user.id)
    .limit(1)
    .maybeSingle();
  if (bizErr || !business) {
    return json({ error: "No tenés un negocio registrado" }, 403);
  }

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    return json({ error: "Reservbot no está configurado (falta API key)" }, 500);
  }

  let body: {
    // deno-lint-ignore no-explicit-any
    messages?: any[];
    user_message?: string;
    decision?: {
      tool_use_id: string; // nombre de la función pendiente (cancel_reservation)
      approved: boolean;
      input?: Record<string, unknown>;
      // deno-lint-ignore no-explicit-any
      other_responses?: any[];
    };
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  // deno-lint-ignore no-explicit-any
  const contents: any[] = body.messages ?? [];

  if (body.user_message) {
    contents.push({ role: "user", parts: [{ text: body.user_message }] });
  } else if (body.decision) {
    // Respuesta a una confirmación pendiente de cancel_reservation.
    const { approved, input, other_responses } = body.decision;
    let result: unknown;
    if (approved) {
      result = await runCancel(
        supabase,
        business.id,
        String(input?.reservation_id ?? ""),
        input?.reason ? String(input.reason) : undefined,
      );
    } else {
      result = {
        cancelado_por_usuario: true,
        mensaje: "El dueño rechazó la cancelación. No canceles el turno.",
      };
    }
    contents.push({
      role: "user",
      parts: [
        // Si el modelo había llamado otras funciones junto a la cancelación,
        // sus resultados (ya ejecutados) van en el mismo turno.
        ...(other_responses ?? []),
        {
          functionResponse: {
            name: "cancel_reservation",
            response: { result },
          },
        },
      ],
    });
  } else {
    return json({ error: "Falta user_message o decision" }, 400);
  }

  const services = await supabase
    .from("services")
    .select("name, duration_minutes, price")
    .eq("business_id", business.id)
    .eq("is_active", true);
  const servicesList = (services.data ?? [])
    // deno-lint-ignore no-explicit-any
    .map((s: any) => `- ${s.name} (${s.duration_minutes} min, ${s.price ?? 0} Gs)`)
    .join("\n");

  const systemInstruction =
    `Sos Reservbot, el asistente del panel de ReservPy para el negocio "${business.name}".
Ayudás al dueño a consultar su agenda y gestionar turnos en lenguaje natural.

Contexto del negocio:
- Horario: ${business.opening_time} a ${business.closing_time}, turnos de ${business.slot_duration_minutes} minutos.
- Servicios:
${servicesList || "- (sin servicios cargados)"}

Hoy es ${todayInAsuncion()} (zona horaria de Paraguay).

Reglas:
- Respondé SIEMPRE en español rioplatense (vos), corto y al grano.
- Si te dan una fecha relativa ("hoy", "mañana", "el jueves"), convertila a YYYY-MM-DD a partir de la fecha de hoy.
- Para cancelar un turno primero identificá la reserva exacta con las funciones de consulta; después llamá cancel_reservation (sola, sin otras funciones en el mismo turno). El sistema le muestra al dueño un botón de confirmación — no preguntes "¿estás seguro?" en texto.
- Si una función devuelve error, explicalo en simple y sugerí qué hacer.
- No inventes datos: si no hay turnos, decilo.`;

  let reply = "";
  let pendingAction: Record<string, unknown> | null = null;

  try {
    for (let i = 0; i < MAX_LOOPS; i++) {
      const payload = JSON.stringify({
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents,
        tools: [{ functionDeclarations: FUNCTION_DECLARATIONS }],
      });

      // Probar cada modelo; ante 429/5xx pasar al siguiente, con un
      // reintento extra (tras 1.5s) sobre el primero al agotar la lista.
      let geminiRes: Response | null = null;
      let lastStatus = 0;
      const attempts = [...MODELS, MODELS[0]];
      for (let a = 0; a < attempts.length; a++) {
        if (a === attempts.length - 1) {
          await new Promise((r) => setTimeout(r, 1500));
        }
        const res = await fetch(geminiUrl(attempts[a]), {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": apiKey,
          },
          body: payload,
        });
        if (res.ok) {
          geminiRes = res;
          break;
        }
        lastStatus = res.status;
        const errBody = await res.text();
        console.error(`Gemini error (${attempts[a]}):`, res.status, errBody);
        // Errores no recuperables (clave inválida, request malformado):
        // no tiene sentido probar otro modelo.
        if (res.status !== 429 && res.status < 500) break;
      }

      if (!geminiRes) {
        const friendly = lastStatus === 429
          ? "El asistente alcanzó el límite de uso por ahora. Esperá un minuto y volvé a intentar."
          : "Los servidores de IA están saturados. Intentá de nuevo en unos segundos.";
        return json({ error: friendly }, 500);
      }

      const data = await geminiRes.json();
      const candidate = data.candidates?.[0];
      // deno-lint-ignore no-explicit-any
      const parts: any[] = candidate?.content?.parts ?? [];

      if (parts.length === 0) {
        reply = reply || "No pude generar una respuesta, probá de nuevo.";
        break;
      }

      contents.push({ role: "model", parts });

      const textParts = parts.filter((p) => p.text);
      if (textParts.length > 0) {
        reply = textParts.map((p) => p.text).join("\n").trim();
      }

      const functionCalls = parts.filter((p) => p.functionCall);
      if (functionCalls.length === 0) break;

      const cancelCall = functionCalls.find(
        (p) => p.functionCall.name === "cancel_reservation",
      );

      if (cancelCall) {
        // Ejecutar ahora las otras funciones del mismo turno (si las hay) y
        // guardar sus resultados para incluirlos en la ronda de confirmación.
        // deno-lint-ignore no-explicit-any
        const otherResponses: any[] = [];
        for (const fc of functionCalls) {
          if (fc === cancelCall) continue;
          const result = await executeQueryTool(
            supabase,
            business,
            fc.functionCall.name,
            fc.functionCall.args ?? {},
          );
          otherResponses.push({
            functionResponse: {
              name: fc.functionCall.name,
              response: { result },
            },
          });
        }
        const input = cancelCall.functionCall.args ?? {};
        pendingAction = {
          tool_use_id: "cancel_reservation",
          type: "cancel_reservation",
          description: input.description ?? "Cancelar turno",
          input,
          other_responses: otherResponses,
        };
        break;
      }

      // Solo funciones de consulta: ejecutarlas y seguir el loop.
      // deno-lint-ignore no-explicit-any
      const responseParts: any[] = [];
      for (const fc of functionCalls) {
        const result = await executeQueryTool(
          supabase,
          business,
          fc.functionCall.name,
          fc.functionCall.args ?? {},
        );
        responseParts.push({
          functionResponse: {
            name: fc.functionCall.name,
            response: { result },
          },
        });
      }
      contents.push({ role: "user", parts: responseParts });
    }
  } catch (e) {
    console.error("reservbot error:", e);
    return json({ error: `Error consultando a Gemini: ${String(e)}` }, 500);
  }

  return json({ messages: contents, reply, pending_action: pendingAction });
});
