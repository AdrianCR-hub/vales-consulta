import { consultarDetalle, consultarLocalidades, consultarResumen, consultarTotal } from "../../api/gastos-api.js";

const months = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
const money = (value) => new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN" }).format(value ?? 0);
const compactMoney = (value) => new Intl.NumberFormat("es-PE", { style: "currency", currency: "PEN", notation: "compact", maximumFractionDigits: 1 }).format(value ?? 0);
const number = (value, digits = 2) => new Intl.NumberFormat("es-PE", { maximumFractionDigits: digits }).format(value ?? 0);
const safe = (value) => String(value ?? "—").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

const form = document.querySelector("#filters");
const feedback = document.querySelector("#feedback");
const results = document.querySelector("#results");
const button = document.querySelector("#search");
const current = new Date();
document.querySelector("#year").value = current.getFullYear();
document.querySelector("#month").value = String(current.getMonth() + 1);
loadMunicipios();

async function loadMunicipios() {
  const select = document.querySelector("#locality");
  try {
    const rows = await consultarLocalidades();
    const groups = new Map();
    for (const row of rows) {
      let group = groups.get(row.idZona);
      if (!group) {
        group = document.createElement("optgroup");
        group.label = row.zona;
        groups.set(row.idZona, group);
        select.append(group);
      }
      const option = document.createElement("option");
      option.value = row.idLocalidad;
      option.textContent = row.nombre;
      group.append(option);
    }
  } catch (error) {
    feedback.className = "feedback error";
    feedback.textContent = `No se pudo cargar el catálogo de localidades: ${error.message}.`;
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const filters = {
    anio: document.querySelector("#year").value,
    mes: document.querySelector("#month").value,
    localidad: document.querySelector("#locality").value,
  };
  feedback.className = "feedback loading";
  feedback.textContent = "Consultando la base de datos…";
  results.hidden = true;
  button.disabled = true;

  try {
    const [summary, total, details, annualSummary] = await Promise.all([
      consultarResumen(filters), consultarTotal(filters), consultarDetalle(filters),
      consultarResumen({ anio: filters.anio, localidad: filters.localidad }),
    ]);
    render(summary, total, details, filters, annualSummary);
    feedback.className = "feedback";
    feedback.textContent = "Consulta completada.";
    results.hidden = false;
  } catch (error) {
    feedback.className = "feedback error";
    feedback.textContent = `No se pudo consultar el servicio: ${error.message}. Verifica que Spring Boot y PostgreSQL estén ejecutándose.`;
  } finally {
    button.disabled = false;
  }
});

function render(summary, total, details, filters, annualSummary) {
  document.querySelector("#total-amount").textContent = money(total.gastoTotal);
  document.querySelector("#total-vouchers").textContent = number(total.cantidadVales, 0);
  document.querySelector("#total-gallons").textContent = `${number(total.galonesConsumidos)} gal`;
  const period = filters.mes ? `${months[Number(filters.mes) - 1]} de ${filters.anio}` : `Todos los meses de ${filters.anio}`;
  document.querySelector("#period-label").textContent = period;

  const monthlyTotals = new Map(Array.from({ length: 12 }, (_, index) => [index + 1, 0]));
  for (const row of annualSummary) {
    monthlyTotals.set(row.mes, (monthlyTotals.get(row.mes) ?? 0) + Number(row.gastoTotal ?? 0));
  }
  const chartMax = Math.max(...monthlyTotals.values(), 0);
  const year = Number(filters.anio);
  document.querySelector("#expense-chart").innerHTML = `<div class="chart-columns">${[...monthlyTotals.entries()].map(([month, amount]) => {
    const height = chartMax > 0 ? (amount / chartMax) * 100 : 0;
    const label = `${months[month - 1]} ${year}: ${money(amount)}`;
    return `<div class="chart-column" title="${safe(label)}"><span class="chart-column-value">${amount > 0 ? compactMoney(amount) : "–"}</span><div class="chart-column-area"><span class="chart-column-bar" style="height:${height}%"></span></div><span class="chart-column-label">${safe(months[month - 1].slice(0, 3))}</span></div>`;
  }).join("")}</div>`;

  const summaryRows = document.querySelector("#summary-rows");
  summaryRows.innerHTML = summary.map((row) => `<tr><td>${safe(months[row.mes - 1])} ${row.anio}</td><td>${safe(row.combustible)}</td><td><span class="municipality-dot"></span>${safe(row.localidad)}</td><td class="numeric">${number(row.cantidadVales, 0)}</td><td class="numeric">${number(row.galonesConsumidos)}</td><td class="numeric amount">${money(row.gastoTotal)}</td></tr>`).join("");
  document.querySelector("#summary-empty").hidden = summary.length > 0;

  const detailRows = document.querySelector("#detail-rows");
  detailRows.innerHTML = details.map((row) => `<tr><td class="code">${safe(row.codigoVale)}</td><td>${safe(row.fechaConsumo)}</td><td>${safe(row.municipio)}</td><td>${safe(row.suministro)}</td><td class="numeric">${number(row.cantidadConsumida)} gal</td><td class="numeric">${money(row.precioReal)}</td><td class="numeric amount">${money(row.importe)}</td><td>${safe(row.ticket)}</td></tr>`).join("");
  document.querySelector("#detail-count").textContent = `${details.length} ${details.length === 1 ? "vale" : "vales"}`;
  document.querySelector("#detail-empty").hidden = details.length > 0;
}
