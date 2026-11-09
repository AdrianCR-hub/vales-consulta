const BASE = "/api/reportes/gastos";

async function get(path, filters) {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(filters)) {
    if (value !== "" && value != null) query.set(key, value);
  }
  const response = await fetch(`${BASE}${path}?${query}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    let message = `Error HTTP ${response.status}`;
    try {
      const body = await response.json();
      message = body.detail || body.message || body.error || message;
    } catch { /* La respuesta del servidor no era JSON. */ }
    throw new Error(message);
  }
  return response.json();
}

export const consultarResumen = (filters) => get("", filters);
export const consultarDetalle = (filters) => get("/detalle", filters);
export const consultarTotal = (filters) => get("/total", filters);
