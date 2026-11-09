-- Datos ficticios de demostración inspirados en los casos del proyecto de referencia.
-- Ejecutar después de schema.sql dentro de la base `vales`.
-- Genera consumos para el mes actual y los tres meses anteriores. Es idempotente.

BEGIN;

INSERT INTO logis_zonal (id_zona, nom_zona) VALUES
    ('01', 'PIURA'), ('02', 'CHULUCANAS'), ('03', 'PAITA'),
    ('04', 'SULLANA'), ('05', 'TALARA'), ('08', 'SECHURA')
ON CONFLICT (id_zona) DO NOTHING;

INSERT INTO logis_localidad (id_localidad, nom_localidad, id_zona) VALUES
    ('01', 'ZONAL PIURA', '01'), ('02', 'PIURA', '01'), ('03', 'CATACAOS', '01'),
    ('04', 'LAS LOMAS', '01'), ('05', 'CASTILLA', '01'), ('46', 'SEDE CENTRAL', '01'),
    ('07', 'ZONAL CHULUCANAS', '02'), ('08', 'CHULUCANAS', '02'), ('09', 'MORROPON', '02'),
    ('12', 'ZONAL PAITA', '03'), ('13', 'PAITA', '03'), ('14', 'AMOTAPE', '03'),
    ('15', 'EL ARENAL', '03'), ('16', 'COLAN', '03'), ('17', 'LA HUACA', '03'),
    ('18', 'TAMARINDO', '03'), ('19', 'VICHAYAL', '03'), ('20', 'VIVIATE', '03'),
    ('21', 'PUEBLO NUEVO COLAN', '03'), ('22', 'EL TAMBO', '03'), ('23', 'MIRAMAR', '03'),
    ('24', 'YACILA', '03'), ('27', 'ZONAL SULLANA', '04'), ('28', 'SULLANA', '04'),
    ('30', 'LANCONES', '04'), ('31', 'MARCAVELICA', '04'), ('32', 'QUERECOTILLO', '04'),
    ('33', 'SALITRAL', '04'), ('36', 'ZONAL TALARA', '05'), ('37', 'TALARA-PARIÑAS', '05'),
    ('38', 'NEGRITOS', '05'), ('39', 'MANCORA', '05'), ('40', 'LOS ORGANOS', '05'),
    ('41', 'EL ALTO', '05'), ('47', 'ZONAL SECHURA', '08'), ('48', 'SECHURA', '08'),
    ('49', 'VICE', '08')
ON CONFLICT (id_localidad) DO NOTHING;

INSERT INTO logis_centro_costo (cod_centro_costo, descripcion) VALUES
    ('90211214', 'Centro de costo de demostración - Piura'),
    ('90214201', 'Centro de costo de demostración - Sullana'),
    ('90321109', 'Centro de costo de demostración - Paita'),
    ('90421109', 'Centro de costo de demostración - Talara')
ON CONFLICT (cod_centro_costo) DO NOTHING;

INSERT INTO unidad_organizativa (cod_uni_organizativa, unidad_organizativa) VALUES
    ('DEMO-PIU', 'Unidad de demostración Piura'),
    ('DEMO-SUL', 'Unidad de demostración Sullana'),
    ('DEMO-PAI', 'Unidad de demostración Paita'),
    ('DEMO-TAL', 'Unidad de demostración Talara')
ON CONFLICT (cod_uni_organizativa) DO NOTHING;

INSERT INTO persona (codigo_persona, nombre, ap_paterno) VALUES
    (990001, 'Rosa', 'Demo Piura'), (990002, 'Luis', 'Demo Sullana'),
    (990003, 'Julia', 'Demo Paita'), (990004, 'Mario', 'Demo Talara')
ON CONFLICT (codigo_persona) DO NOTHING;

SELECT setval(pg_get_serial_sequence('persona', 'codigo_persona'),
              GREATEST((SELECT COALESCE(MAX(codigo_persona), 1) FROM persona), 990004), true);

INSERT INTO trabajador (dni, codigo_persona, centro_costo, cod_uni_organizativa) VALUES
    ('90000001', 990001, '90211214', 'DEMO-PIU'),
    ('90000002', 990002, '90214201', 'DEMO-SUL'),
    ('90000011', 990003, '90321109', 'DEMO-PAI'),
    ('90000014', 990004, '90421109', 'DEMO-TAL')
ON CONFLICT (dni) DO NOTHING;

INSERT INTO proveedor (cod_proveedor, razon_social) VALUES
    ('20000000001', 'Grifo Los Algarrobos (demo)'),
    ('20000000002', 'Estación Santa Elena (demo)'),
    ('20000000004', 'Estación Puerto Paita (demo)'),
    ('20000000005', 'Grifo Costa Talara (demo)')
ON CONFLICT (cod_proveedor) DO NOTHING;

INSERT INTO logis_contrato_vale (cod_contrato, ruc, monto_total, fecha_inicio, fecha_fin, observacion) VALUES
    ('DEMO-PIU', '20000000001', 15000, DATE '2020-01-01', DATE '2099-12-31', 'Contrato ficticio para pruebas'),
    ('DEMO-SUL', '20000000002',  8000, DATE '2020-01-01', DATE '2099-12-31', 'Contrato ficticio para pruebas'),
    ('DEMO-PAI', '20000000004',  9000, DATE '2020-01-01', DATE '2099-12-31', 'Contrato ficticio para pruebas'),
    ('DEMO-TAL', '20000000005', 10000, DATE '2020-01-01', DATE '2099-12-31', 'Contrato ficticio para pruebas')
ON CONFLICT (cod_contrato) DO NOTHING;

INSERT INTO logis_unidad_maquinaria (codigo, descripcion, tipo_vehiculo, placa) VALUES
    (9901, 'Unidad de mantenimiento Piura (demo)', 'Camioneta', 'DEM-101'),
    (9902, 'Unidad operativa Sullana (demo)', 'Camioneta', 'DEM-202'),
    (9903, 'Unidad operativa Paita (demo)', 'Camioneta', 'DEM-303'),
    (9904, 'Unidad de servicio Talara (demo)', 'Camión', 'DEM-404')
ON CONFLICT (codigo) DO NOTHING;

SELECT setval(pg_get_serial_sequence('logis_unidad_maquinaria', 'codigo'),
              GREATEST((SELECT COALESCE(MAX(codigo), 1) FROM logis_unidad_maquinaria), 9904), true);

WITH localidades(id_localidad, cod_zonal, proveedor, trabajador, contrato, suministro, cantidad, precio, dia) AS (
    VALUES
        ('05', '01', '20000000001', '90000001', 'DEMO-PIU', 'REGULAR', 15.00::numeric, 22.60::numeric, 2),
        ('28', '04', '20000000002', '90000002', 'DEMO-SUL', 'DIESEL_B5',  6.00::numeric, 25.10::numeric, 4),
        ('13', '03', '20000000004', '90000011', 'DEMO-PAI', 'REGULAR',  8.50::numeric, 21.65::numeric, 6),
        ('37', '05', '20000000005', '90000014', 'DEMO-TAL', 'DIESEL_B5', 10.00::numeric, 25.25::numeric, 8)
), meses(meses_atras) AS (
    VALUES (0), (1), (2), (3)
), consumos AS (
    SELECT l.*, (date_trunc('month', CURRENT_DATE)::date
                 - (m.meses_atras * INTERVAL '1 month')::interval)::date + l.dia - 1 AS fecha
      FROM localidades l CROSS JOIN meses m
)
INSERT INTO logis_vales (
    codigo_vale, cod_zonal, cod_localidad, cod_proveedor, nrocontrato, cod_trabajador,
    fecha_emision, id_suministro, cantidad_emitida, precio, cod_centrocosto,
    codigo_unidad, estado_vale, observacion, fecha_consumo, cantidad_consumida,
    precio_real, importe, ticket, usuario, estado_comprobante, estado
)
SELECT to_char(fecha, 'YYYYMM') || lpad((900 + id_localidad::integer)::text, 4, '0'),
       cod_zonal, id_localidad, proveedor, contrato, trabajador,
       fecha::timestamp - INTERVAL '1 day', suministro, cantidad + 1, precio,
       CASE cod_zonal WHEN '01' THEN '90211214' WHEN '04' THEN '90214201'
            WHEN '03' THEN '90321109' ELSE '90421109' END,
       CASE cod_zonal WHEN '01' THEN 9901 WHEN '04' THEN 9902
            WHEN '03' THEN 9903 ELSE 9904 END,
       3, 'Vale usado de demostración', fecha::timestamp, cantidad, precio,
       round(cantidad * precio, 2),
       'T' || to_char(fecha, 'YYYYMM') || lpad((900 + id_localidad::integer)::text, 4, '0'),
       trabajador, TRUE, TRUE
  FROM consumos
ON CONFLICT (codigo_vale) DO NOTHING;

-- Casos de control: autorizado y anulado no deben aparecer en los gastos.
INSERT INTO logis_vales (
    codigo_vale, cod_zonal, cod_localidad, cod_proveedor, nrocontrato, cod_trabajador,
    id_suministro, cantidad_emitida, precio, estado_vale, observacion, estado
)
SELECT to_char(CURRENT_DATE, 'YYYYMM') || '9991', '01', '05', '20000000001',
       'DEMO-PIU', '90000001', 'REGULAR', 5, 22.60, 1, 'Demo autorizado (no consumido)', TRUE
WHERE NOT EXISTS (SELECT 1 FROM logis_vales WHERE codigo_vale = to_char(CURRENT_DATE, 'YYYYMM') || '9991')
ON CONFLICT (codigo_vale) DO NOTHING;

INSERT INTO logis_vales (
    codigo_vale, cod_zonal, cod_localidad, cod_proveedor, nrocontrato, cod_trabajador,
    id_suministro, cantidad_emitida, precio, estado_vale, observacion,
    observacion_anulacion, fecha_anulacion, estado
)
SELECT to_char(CURRENT_DATE, 'YYYYMM') || '9992', '04', '28', '20000000002',
       'DEMO-SUL', '90000002', 'REGULAR', 5, 21.80, 4,
       'Demo anulado (no consumido)', 'Prueba de vale anulado', CURRENT_TIMESTAMP, TRUE
WHERE NOT EXISTS (SELECT 1 FROM logis_vales WHERE codigo_vale = to_char(CURRENT_DATE, 'YYYYMM') || '9992')
ON CONFLICT (codigo_vale) DO NOTHING;

COMMIT;
