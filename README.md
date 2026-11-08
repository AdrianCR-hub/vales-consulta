# Servicio de consulta de gastos de vales

API REST independiente para consultar gastos de vales usados en PostgreSQL. Se considera **USADO** únicamente el estado `3`; los anulados y los vales no atendidos no se incluyen.

## Requisitos y configuración

- Java 17 y Maven
- PostgreSQL con la base `vales`
- Variables opcionales: `DB_URL`, `DB_USER`, `DB_PASSWORD`, `PORT`

Ejemplo para PowerShell:

```powershell
$env:DB_URL="jdbc:postgresql://localhost:5432/vales"
$env:DB_USER="postgres"
$env:DB_PASSWORD="tu-clave"
mvn spring-boot:run
```

## Endpoints

- `GET /api/reportes/gastos?anio=2025&mes=4`: gasto y cantidad de vales agrupados por año, mes y municipio (localidad).
- `GET /api/reportes/gastos/detalle?anio=2025&mes=4&municipio=Centro`: detalle de vales usados, incluido el suministro.
- `GET /api/reportes/gastos/total?anio=2025&mes=4`: consolidado final; admite además el filtro `municipio`.

Los filtros de año, mes y municipio son opcionales. El importe se toma de `importe`; si está nulo, se calcula como `cantidad_consumida * precio_real`. `fecha_consumo` determina el período de gasto.

## Esquema PostgreSQL

El archivo `database/schema.sql` resuelve la incompatibilidad del `.txt`: define nombres coherentes `logis_zonal`, `logis_localidad`, `logis_centro_costo`, `logis_unidad_maquinaria` y `logis_vales`, crea las tablas referenciadas antes de agregar sus claves foráneas y corrige el typo `logis_centro_costo`. Incluye el catálogo de estados usado por la API (`3 = USADO`) e índices para los reportes.

En una base nueva, crea primero la base `vales` y luego ejecuta el esquema dentro de ella:

```powershell
psql -U postgres -d vales -f database/schema.sql
```

El `.txt` original se conserva sin cambios; no ejecutes sus `CREATE TABLE` defectuosos junto con este esquema. Si ya tienes datos en una base creada, respáldala antes de migrar y adapta los nombres mediante una migración de datos; este script está pensado para una instalación nueva.
