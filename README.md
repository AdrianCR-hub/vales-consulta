# Consulta de gastos de vales

Aplicación independiente para consultar en PostgreSQL los vales usados, con una página web que consume la API REST. Se considera **USADO** únicamente el estado `3`; los anulados y los vales no atendidos no se incluyen.

## Estructura

```text
backend/                 API REST Java 17 + Spring Boot
  src/main/java/          Controladores y consultas JDBC
  src/main/resources/     Configuración de Spring
frontend/                Página web y cliente HTTP JavaScript
  api/                    Consumo de los endpoints JSON
  features/gastos/        Pantalla de reportes
  styles/                 Estilos
database/schema.sql       Esquema corregido para PostgreSQL
.vscode/                 Perfil para ejecutar desde VS Code
```

El empaquetado de Maven incorpora `frontend/` dentro del JAR. Spring Boot sirve la página y la API desde el mismo origen, evitando configuración adicional de CORS.

## Ejecutar en Windows / VS Code

Requisitos: JDK 17 o superior, Maven, PostgreSQL y VS Code con **Extension Pack for Java**.

1. Crea la base de datos `vales` en PostgreSQL.
2. Ejecuta el esquema corregido:
   ```powershell
   psql -U postgres -d vales -f database/schema.sql
   ```
3. Copia `.env.example` como `.env` y actualiza el usuario y la contraseña de PostgreSQL. El archivo `.env` es local y no se publica en Git.
4. Abre la carpeta raíz del proyecto en VS Code. En **Run and Debug**, selecciona **Ejecutar consulta de gastos** y presiona `F5`.
5. Abre [http://localhost:8080](http://localhost:8080). La página permite consultar totales, gastos por municipio y el detalle de vales.

También puedes iniciar desde la terminal de VS Code. Configura las variables de entorno `DB_URL`, `DB_USER`, `DB_PASSWORD` y opcionalmente `PORT`, luego ejecuta:

```powershell
mvn -f backend/pom.xml spring-boot:run
```

Para compilar y probar:

```powershell
mvn -f backend/pom.xml test
```

El esquema está vacío hasta que se agreguen datos. Los reportes devolverán ceros/listas vacías mientras no existan vales usados.

## API

- `GET /api/reportes/gastos?anio=2025&mes=4`: gasto agrupado por año, mes y municipio/localidad.
- `GET /api/reportes/gastos/detalle?anio=2025&mes=4&municipio=Centro`: detalle de vales usados, incluido el suministro.
- `GET /api/reportes/gastos/total?anio=2025&mes=4`: consolidado final; también acepta el filtro `municipio`.

Los filtros son opcionales. `fecha_consumo` determina el período del gasto. Se suma `importe` y, cuando no está registrado, se calcula `cantidad_consumida * precio_real`.

## Esquema PostgreSQL

`database/schema.sql` corrige las referencias inconsistentes del archivo de base de datos original: define nombres coherentes `logis_zonal`, `logis_localidad`, `logis_centro_costo`, `logis_unidad_maquinaria` y `logis_vales`; crea las tablas antes de sus claves foráneas; y define `3 = USADO`. Está pensado para una instalación nueva, no para migrar datos existentes.
