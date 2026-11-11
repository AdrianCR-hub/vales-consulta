package com.adriancr.vales.report;

import java.math.BigDecimal;
import java.sql.Types;
import java.util.List;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

import static com.adriancr.vales.report.ReporteGastosController.*;

@Service
public class ReporteGastosService {
    private static final String FILTER = """
        WHERE v.estado_vale = 3
          AND v.estado = TRUE
          AND v.fecha_consumo IS NOT NULL
          AND (:anio IS NULL OR EXTRACT(YEAR FROM v.fecha_consumo)::int = :anio)
          AND (:mes IS NULL OR EXTRACT(MONTH FROM v.fecha_consumo)::int = :mes)
          AND (:localidad IS NULL OR l.id_localidad = :localidad
               OR LOWER(l.nom_localidad) = LOWER(:localidad))
        """;

    private final NamedParameterJdbcTemplate jdbc;

    public ReporteGastosService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<GastoLocalidad> resumen(Integer anio, Integer mes, String localidad) {
        String sql = """
            SELECT EXTRACT(YEAR FROM v.fecha_consumo)::int AS anio,
                   EXTRACT(MONTH FROM v.fecha_consumo)::int AS mes,
                   l.nom_localidad AS localidad,
                   CASE v.id_suministro
                       WHEN 'REGULAR' THEN 'Gasolina regular'
                       WHEN 'PREMIUM' THEN 'Gasolina premium'
                       WHEN 'DIESEL_B5' THEN 'Diésel B5'
                       WHEN 'GLP' THEN 'GLP'
                       ELSE v.id_suministro
                   END AS combustible,
                   COUNT(*) AS cantidad_vales,
                   COALESCE(SUM(v.cantidad_consumida), 0) AS galones_consumidos,
                   COALESCE(SUM(COALESCE(v.importe, v.cantidad_consumida * v.precio_real)), 0) AS gasto_total
              FROM logis_vales v
              JOIN logis_localidad l ON l.id_localidad = v.cod_localidad
            """ + FILTER + """
            GROUP BY 1, 2, 3, 4
            ORDER BY 1 DESC, 2 DESC, 4, 3
            """;
        return jdbc.query(sql, params(anio, mes, limpio(localidad)), (rs, row) -> new GastoLocalidad(
            rs.getInt("anio"), rs.getInt("mes"), rs.getString("localidad"), rs.getString("combustible"),
            rs.getLong("cantidad_vales"), rs.getBigDecimal("galones_consumidos"),
            rs.getBigDecimal("gasto_total")));
    }

    public List<Localidad> localidades() {
        return jdbc.query("""
            SELECT l.id_zona, z.nom_zona, l.id_localidad, l.nom_localidad
              FROM logis_localidad l
              JOIN logis_zonal z ON z.id_zona = l.id_zona
             ORDER BY l.id_zona, l.nom_localidad, l.id_localidad
            """, (rs, row) -> new Localidad(rs.getString("id_zona"), rs.getString("nom_zona"),
                                             rs.getString("id_localidad"), rs.getString("nom_localidad")));
    }

    public List<DetalleVale> detalle(Integer anio, Integer mes, String localidad) {
        String sql = """
            SELECT v.codigo_vale, v.fecha_consumo::date AS fecha_consumo, l.nom_localidad AS municipio,
                   v.id_suministro AS suministro, v.cantidad_consumida, v.precio_real,
                   COALESCE(v.importe, v.cantidad_consumida * v.precio_real) AS importe, v.ticket
              FROM logis_vales v
              JOIN logis_localidad l ON l.id_localidad = v.cod_localidad
            """ + FILTER + """
            ORDER BY v.fecha_consumo DESC, v.codigo_vale
            """;
        return jdbc.query(sql, params(anio, mes, limpio(localidad)), (rs, row) -> new DetalleVale(
            rs.getString("codigo_vale"), rs.getDate("fecha_consumo").toLocalDate(),
            rs.getString("municipio"), rs.getString("suministro"),
            rs.getBigDecimal("cantidad_consumida"), rs.getBigDecimal("precio_real"),
            rs.getBigDecimal("importe"), rs.getString("ticket")));
    }

    public TotalGastos total(Integer anio, Integer mes, String localidad) {
        String sql = """
            SELECT COUNT(*) AS cantidad_vales,
                   COALESCE(SUM(v.cantidad_consumida), 0) AS galones_consumidos,
                   COALESCE(SUM(COALESCE(v.importe, v.cantidad_consumida * v.precio_real)), 0) AS gasto_total
              FROM logis_vales v
              JOIN logis_localidad l ON l.id_localidad = v.cod_localidad
            """ + FILTER;
        return jdbc.queryForObject(sql, params(anio, mes, limpio(localidad)), (rs, row) ->
            new TotalGastos(rs.getLong("cantidad_vales"), rs.getBigDecimal("galones_consumidos"),
                            rs.getBigDecimal("gasto_total")));
    }

    private static MapSqlParameterSource params(Integer anio, Integer mes, String localidad) {
        // PostgreSQL necesita conocer el tipo SQL aunque los filtros opcionales sean NULL.
        return new MapSqlParameterSource()
            .addValue("anio", anio, Types.INTEGER)
            .addValue("mes", mes, Types.INTEGER)
            .addValue("localidad", localidad, Types.VARCHAR);
    }

    private static String limpio(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
