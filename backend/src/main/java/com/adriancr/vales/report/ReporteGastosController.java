package com.adriancr.vales.report;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reportes/gastos")
public class ReporteGastosController {
    private final ReporteGastosService service;

    public ReporteGastosController(ReporteGastosService service) {
        this.service = service;
    }

    /** Resumen agrupado por año, mes y localidad operativa del vale. */
    @GetMapping
    public List<GastoLocalidad> resumen(@RequestParam(required = false) Integer anio,
                                        @RequestParam(required = false) Integer mes,
                                        @RequestParam(required = false) String localidad,
                                        @RequestParam(required = false) String municipio) {
        validar(anio, mes);
        return service.resumen(anio, mes, localidad != null ? localidad : municipio);
    }

    /** Catálogo de localidades, ordenadas y agrupadas por zonal. */
    @GetMapping({"/localidades", "/municipios"})
    public List<Localidad> localidades() {
        return service.localidades();
    }

    /** Detalle de los vales usados, con suministro, para el período indicado. */
    @GetMapping("/detalle")
    public List<DetalleVale> detalle(@RequestParam(required = false) Integer anio,
                                     @RequestParam(required = false) Integer mes,
                                     @RequestParam(required = false) String localidad,
                                     @RequestParam(required = false) String municipio) {
        validar(anio, mes);
        return service.detalle(anio, mes, localidad != null ? localidad : municipio);
    }

    /** Total final consolidado con los mismos filtros opcionales. */
    @GetMapping("/total")
    public TotalGastos total(@RequestParam(required = false) Integer anio,
                             @RequestParam(required = false) Integer mes,
                             @RequestParam(required = false) String localidad,
                             @RequestParam(required = false) String municipio) {
        validar(anio, mes);
        return service.total(anio, mes, localidad != null ? localidad : municipio);
    }

    private static void validar(Integer anio, Integer mes) {
        if (anio != null && (anio < 1900 || anio > 9999))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El año debe estar entre 1900 y 9999.");
        if (mes != null && (mes < 1 || mes > 12))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "El mes debe estar entre 1 y 12.");
    }

    public record GastoLocalidad(int anio, int mes, String localidad, String combustible, long cantidadVales,
                                 BigDecimal galonesConsumidos, BigDecimal gastoTotal) {}
    public record Localidad(String idZona, String zona, String idLocalidad, String nombre) {}
    public record DetalleVale(String codigoVale, LocalDate fechaConsumo, String municipio,
                              String suministro, BigDecimal cantidadConsumida,
                              BigDecimal precioReal, BigDecimal importe, String ticket) {}
    public record TotalGastos(long cantidadVales, BigDecimal galonesConsumidos, BigDecimal gastoTotal) {}
}
