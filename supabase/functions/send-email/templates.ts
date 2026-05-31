// supabase/functions/send-email/templates.ts
// Responsive HTML email templates for ReservPy — all text in Spanish (Argentina).

const PRIMARY = "#00C896";
const DARK = "#1A1A2E";
const LIGHT_BG = "#F4F6F8";
const CARD_BG = "#FFFFFF";
const FONT = "'Inter', 'Segoe UI', Arial, sans-serif";

/** Shared wrapper that renders the header, card body, and footer. */
function wrap(bodyHtml: string): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>ReservPy</title>
</head>
<body style="margin:0;padding:0;background-color:${LIGHT_BG};font-family:${FONT};color:${DARK};-webkit-font-smoothing:antialiased;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:${LIGHT_BG};">
    <tr><td style="padding:32px 16px;">
      <table role="presentation" align="center" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;">
        <!-- HEADER -->
        <tr><td style="text-align:center;padding-bottom:24px;">
          <span style="font-size:28px;font-weight:700;color:${PRIMARY};letter-spacing:-0.5px;">ReservPy</span>
        </td></tr>
        <!-- CARD -->
        <tr><td style="background-color:${CARD_BG};border-radius:12px;padding:36px 32px;box-shadow:0 2px 8px rgba(0,0,0,0.06);">
          ${bodyHtml}
        </td></tr>
        <!-- FOOTER -->
        <tr><td style="text-align:center;padding-top:24px;font-size:12px;color:#999999;line-height:1.6;">
          &copy; 2026 ReservPy. Todos los derechos reservados.<br/>
          Este email fue enviado automáticamente, no respondas a esta dirección.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

/** Small helper: render a key-value detail row inside the card. */
function detailRow(label: string, value: string): string {
  return `<tr>
    <td style="padding:6px 0;font-size:14px;color:#666666;width:120px;vertical-align:top;">${label}</td>
    <td style="padding:6px 0;font-size:14px;color:${DARK};font-weight:500;">${value}</td>
  </tr>`;
}

// ---------------------------------------------------------------------------
// Template builders
// ---------------------------------------------------------------------------

function welcome(data: Record<string, unknown>): { subject: string; html: string } {
  const { firstName, role } = data as { firstName: string; role: string };
  const roleMessage =
    role === "business"
      ? "Ya podés empezar a gestionar tu agenda, configurar tus servicios y recibir reservas de clientes."
      : "Ya podés explorar negocios cerca tuyo y reservar turnos en segundos.";

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">¡Hola, ${firstName}! 👋</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      Te damos la bienvenida a <strong style="color:${PRIMARY};">ReservPy</strong>. Estamos muy contentos de que te sumes.
    </p>
    <p style="margin:0 0 24px;font-size:15px;color:#555555;line-height:1.6;">
      ${roleMessage}
    </p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
      <tr><td style="background-color:${PRIMARY};border-radius:8px;text-align:center;">
        <a href="https://ReservPy.app" target="_blank"
           style="display:inline-block;padding:12px 28px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">
          Ir a ReservPy
        </a>
      </td></tr>
    </table>
  `);

  return { subject: "¡Bienvenido/a a ReservPy! 🎉", html };
}

function businessCreated(data: Record<string, unknown>): { subject: string; html: string } {
  const { ownerName, businessName, address } = data as {
    ownerName: string;
    businessName: string;
    address: string;
  };

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">¡Felicitaciones, ${ownerName}! 🎉</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      Tu negocio fue creado exitosamente en <strong style="color:${PRIMARY};">ReservPy</strong>.
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:${LIGHT_BG};border-radius:8px;padding:16px;margin-bottom:24px;">
      ${detailRow("Negocio", businessName)}
      ${detailRow("Dirección", address)}
    </table>
    <p style="margin:0 0 24px;font-size:15px;color:#555555;line-height:1.6;">
      Ya podés configurar tus servicios, horarios y empezar a recibir reservas de tus clientes.
    </p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
      <tr><td style="background-color:${PRIMARY};border-radius:8px;text-align:center;">
        <a href="https://ReservPy.app" target="_blank"
           style="display:inline-block;padding:12px 28px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">
          Gestionar mi negocio
        </a>
      </td></tr>
    </table>
  `);

  return { subject: "Tu negocio fue creado exitosamente 🏪", html };
}

function clientRegistered(data: Record<string, unknown>): { subject: string; html: string } {
  const { firstName } = data as { firstName: string };

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">¡Hola, ${firstName}! ✨</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      Tu cuenta en <strong style="color:${PRIMARY};">ReservPy</strong> ya está lista.
    </p>
    <p style="margin:0 0 24px;font-size:15px;color:#555555;line-height:1.6;">
      Ahora podés explorar negocios, ver sus servicios disponibles y reservar tu próximo turno en segundos.
    </p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
      <tr><td style="background-color:${PRIMARY};border-radius:8px;text-align:center;">
        <a href="https://ReservPy.app" target="_blank"
           style="display:inline-block;padding:12px 28px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">
          Explorar negocios
        </a>
      </td></tr>
    </table>
  `);

  return { subject: "¡Tu cuenta está lista! ✨", html };
}

function reservationConfirmed(data: Record<string, unknown>): { subject: string; html: string } {
  const {
    recipientName,
    clientName,
    businessName,
    serviceName,
    date,
    time,
    address,
    notes,
    isBusinessCopy,
  } = data as {
    recipientName: string;
    clientName?: string;
    businessName: string;
    serviceName: string;
    date: string;
    time: string;
    address: string;
    notes?: string;
    isBusinessCopy?: boolean;
  };

  const heading = isBusinessCopy
    ? `Tenés un nuevo turno 📅`
    : `Tu turno fue confirmado ✅`;

  const intro = isBusinessCopy
    ? `<strong>${clientName ?? recipientName}</strong> reservó un turno en tu negocio.`
    : `¡Listo, ${recipientName}! Tu reserva fue confirmada.`;

  const notesRow = notes
    ? detailRow("Notas", notes)
    : "";

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">${heading}</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      ${intro}
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:${LIGHT_BG};border-radius:8px;padding:16px;margin-bottom:24px;">
      ${detailRow("Negocio", businessName)}
      ${detailRow("Servicio", serviceName)}
      ${detailRow("Fecha", date)}
      ${detailRow("Hora", time)}
      ${detailRow("Dirección", address)}
      ${notesRow}
    </table>
    <p style="margin:0;font-size:13px;color:#999999;">
      Si necesitás cancelar o reprogramar, hacelo desde la app.
    </p>
  `);

  return { subject: `Turno confirmado ✅ — ${businessName}`, html };
}

function reservationCancelled(data: Record<string, unknown>): { subject: string; html: string } {
  const {
    recipientName,
    clientName,
    businessName,
    serviceName,
    date,
    time,
    cancelledBy,
    reason,
    isBusinessCopy,
  } = data as {
    recipientName: string;
    clientName?: string;
    businessName: string;
    serviceName: string;
    date: string;
    time: string;
    cancelledBy?: string;
    reason?: string;
    isBusinessCopy?: boolean;
  };

  const heading = isBusinessCopy
    ? `Turno cancelado ❌`
    : `Tu turno fue cancelado`;

  const intro = isBusinessCopy
    ? `<strong>${clientName ?? recipientName}</strong> canceló su turno en tu negocio.`
    : `Hola, ${recipientName}. Lamentablemente tu reserva fue cancelada.`;

  const cancelledByRow = cancelledBy
    ? detailRow("Cancelado por", cancelledBy)
    : "";

  const reasonRow = reason
    ? detailRow("Motivo", reason)
    : "";

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">${heading}</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      ${intro}
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:${LIGHT_BG};border-radius:8px;padding:16px;margin-bottom:24px;">
      ${detailRow("Negocio", businessName)}
      ${detailRow("Servicio", serviceName)}
      ${detailRow("Fecha", date)}
      ${detailRow("Hora", time)}
      ${cancelledByRow}
      ${reasonRow}
    </table>
    <p style="margin:0;font-size:13px;color:#999999;">
      Si tenés dudas, contactá ${isBusinessCopy ? "al cliente" : "al negocio"} directamente desde la app.
    </p>
  `);

  return { subject: `Turno cancelado ❌ — ${businessName}`, html };
}

function paymentReceipt(data: Record<string, unknown>): { subject: string; html: string } {
  const { payerName, amount, period } = data as {
    payerName: string;
    amount: string;
    period: string;
  };

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">Recibo de pago 💳</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      Hola, ${payerName}. Acá tenés el resumen de tu pago en <strong style="color:${PRIMARY};">ReservPy</strong>.
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:${LIGHT_BG};border-radius:8px;padding:16px;margin-bottom:24px;">
      ${detailRow("Monto", amount)}
      ${detailRow("Período", period)}
      ${detailRow("Estado", '<span style="color:' + PRIMARY + ';font-weight:600;">Pagado</span>')}
    </table>
    <p style="margin:0;font-size:13px;color:#999999;">
      <!-- PLACEHOLDER: En una versión futura se incluirá el detalle completo del comprobante y enlace de descarga. -->
      Este recibo es un comprobante preliminar. El comprobante fiscal definitivo estará disponible próximamente.
    </p>
  `);

  return { subject: "Recibo de pago — ReservPy", html };
}

function planUpgraded(data: Record<string, unknown>): { subject: string; html: string } {
  const { ownerName, businessName, planName, amount, activatedAt } = data as {
    ownerName: string;
    businessName: string;
    planName: string;
    amount: string;
    activatedAt: string;
  };

  const html = wrap(`
    <h1 style="margin:0 0 8px;font-size:22px;color:${DARK};">¡Plan actualizado! ⭐</h1>
    <p style="margin:0 0 20px;font-size:15px;color:#555555;line-height:1.6;">
      Hola, ${ownerName}. Tu negocio <strong style="color:${PRIMARY};">${businessName}</strong> ahora tiene el plan <strong style="color:#F59E0B;">${planName}</strong>.
    </p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0"
           style="background-color:${LIGHT_BG};border-radius:8px;padding:16px;margin-bottom:24px;">
      ${detailRow("Plan", planName)}
      ${detailRow("Monto", amount)}
      ${detailRow("Activado", activatedAt)}
      ${detailRow("Estado", '<span style="color:' + PRIMARY + ';font-weight:600;">Activo</span>')}
    </table>
    <p style="margin:0 0 24px;font-size:15px;color:#555555;line-height:1.6;">
      Ya tenés acceso a reservas ilimitadas, equipo ilimitado, reportes avanzados y soporte prioritario.
    </p>
    <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
      <tr><td style="background-color:${PRIMARY};border-radius:8px;text-align:center;">
        <a href="https://ReservPy.app" target="_blank"
           style="display:inline-block;padding:12px 28px;color:#ffffff;font-size:15px;font-weight:600;text-decoration:none;">
          Ir a mi negocio
        </a>
      </td></tr>
    </table>
  `);

  return { subject: "¡Tu plan fue actualizado a Pro! ⭐", html };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

const templates: Record<
  string,
  (data: Record<string, unknown>) => { subject: string; html: string }
> = {
  welcome,
  business_created: businessCreated,
  client_registered: clientRegistered,
  reservation_confirmed: reservationConfirmed,
  reservation_cancelled: reservationCancelled,
  payment_receipt: paymentReceipt,
  plan_upgraded: planUpgraded,
};

/**
 * Returns the subject and rendered HTML for the given email type.
 * Throws if the type is unknown.
 */
export function getEmailTemplate(
  type: string,
  data: Record<string, unknown>,
): { subject: string; html: string } {
  const builder = templates[type];
  if (!builder) {
    throw new Error(`Unknown email template type: "${type}"`);
  }
  return builder(data);
}
