-- =====================================================================
-- 01_estructura.sql
-- Proyecto: Gestor de Combustible 
-- Motor: Oracle Database Free (23ai)
-- Contenido: creacion de 19 tablas con PK, FK, UNIQUE, CHECK y DEFAULT
-- Las llaves primarias usan IDENTITY (Oracle crea la secuencia solo).
-- =====================================================================

-- ---------------------------------------------------------------------
-- (OPCIONAL) Para volver a empezar de cero, descomenta este bloque.
-- Borra todas las tablas en orden inverso. Ojo: borra tambien los datos.
-- ---------------------------------------------------------------------
-- DROP TABLE IF EXISTS Auditoria_Log CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Usuario_Sistema CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Formulario_Bidones CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Cupo CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Alerta CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Incumplimiento CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Regla_limite CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Transaccion_carga CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Reclamo_Calidad CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Inventario_Estacion CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Distribucion_combustible CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Estacion_servicio CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Planta_Refineria CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Conductor_Vehiculo CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Vehiculo CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Entidad CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Conductores CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Categoria_Vehiculo CASCADE CONSTRAINTS;
-- DROP TABLE IF EXISTS Tipo_Combustible CASCADE CONSTRAINTS;

-- 1. CATALOGOS

CREATE TABLE Tipo_Combustible (
    id_tipo_combustible  NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre               VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_tipo_combustible PRIMARY KEY (id_tipo_combustible),
    CONSTRAINT uq_tipo_combustible_nombre UNIQUE (nombre)
);

CREATE TABLE Categoria_Vehiculo (
    id_categoria             NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre_categoria         VARCHAR2(50) NOT NULL,
    consumo_esperado_litros  NUMBER(10,2) NOT NULL,
    periodo_dias             NUMBER(5) DEFAULT 30 NOT NULL,
    CONSTRAINT pk_categoria_vehiculo PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nombre UNIQUE (nombre_categoria),
    CONSTRAINT ck_categoria_consumo CHECK (consumo_esperado_litros > 0),
    CONSTRAINT ck_categoria_periodo CHECK (periodo_dias > 0)
);

-- 2. PERSONAS Y VEHICULOS

CREATE TABLE Conductores (
    id_conductor     NUMBER GENERATED ALWAYS AS IDENTITY,
    ci_dni           VARCHAR2(20) NOT NULL,
    nombre_completo  VARCHAR2(100) NOT NULL,
    huella_hash      VARCHAR2(255),   -- solo hash sintetico, nunca biometria real
    estado           VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_conductores PRIMARY KEY (id_conductor),
    CONSTRAINT uq_conductores_ci UNIQUE (ci_dni),
    CONSTRAINT ck_conductores_estado CHECK (estado IN ('ACTIVO','INACTIVO','SUSPENDIDO'))
);

-- Entidad = propietario (persona o empresa)
CREATE TABLE Entidad (
    id_entidad      NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre_entidad  VARCHAR2(100) NOT NULL,
    tipo_entidad    VARCHAR2(30) NOT NULL,
    ci_nit          VARCHAR2(20) NOT NULL,   -- CI si es PERSONA, NIT si es EMPRESA
    estado          VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_entidad PRIMARY KEY (id_entidad),
    CONSTRAINT uq_entidad_ci_nit UNIQUE (ci_nit),
    CONSTRAINT ck_entidad_tipo CHECK (tipo_entidad IN ('PERSONA','EMPRESA')),
    CONSTRAINT ck_entidad_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE Vehiculo (
    id_vehiculo          NUMBER GENERATED ALWAYS AS IDENTITY,
    placa                VARCHAR2(20) NOT NULL,
    vin                  VARCHAR2(50),
    marca                VARCHAR2(50),
    modelo               VARCHAR2(50),
    anio                 NUMBER(4),
    cilindrada_cc        NUMBER(6),
    capacidad_tanque     NUMBER(10,2),
    id_tipo_combustible  NUMBER NOT NULL,
    id_categoria         NUMBER NOT NULL,
    id_entidad           NUMBER NOT NULL,   -- propietario
    estado               VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_vehiculo),
    CONSTRAINT uq_vehiculo_placa UNIQUE (placa),
    CONSTRAINT uq_vehiculo_vin UNIQUE (vin),
    CONSTRAINT fk_vehiculo_tipo_comb FOREIGN KEY (id_tipo_combustible)
        REFERENCES Tipo_Combustible (id_tipo_combustible),
    CONSTRAINT fk_vehiculo_categoria FOREIGN KEY (id_categoria)
        REFERENCES Categoria_Vehiculo (id_categoria),
    CONSTRAINT fk_vehiculo_entidad FOREIGN KEY (id_entidad)
        REFERENCES Entidad (id_entidad),
    CONSTRAINT ck_vehiculo_anio CHECK (anio IS NULL OR anio BETWEEN 1950 AND 2100),
    CONSTRAINT ck_vehiculo_cilindrada CHECK (cilindrada_cc IS NULL OR cilindrada_cc > 0),
    CONSTRAINT ck_vehiculo_tanque CHECK (capacidad_tanque IS NULL OR capacidad_tanque > 0),
    CONSTRAINT ck_vehiculo_estado CHECK (estado IN ('ACTIVO','INACTIVO','BLOQUEADO'))
);

CREATE TABLE Conductor_Vehiculo (
    id_asignacion     NUMBER GENERATED ALWAYS AS IDENTITY,
    id_conductor      NUMBER NOT NULL,
    id_vehiculo       NUMBER NOT NULL,
    fecha_asignacion  DATE NOT NULL,
    fecha_fin         DATE,                  -- NULL = asignacion vigente
    estado_permiso    VARCHAR2(20) DEFAULT 'VIGENTE' NOT NULL,
    CONSTRAINT pk_conductor_vehiculo PRIMARY KEY (id_asignacion),
    CONSTRAINT fk_cv_conductor FOREIGN KEY (id_conductor)
        REFERENCES Conductores (id_conductor),
    CONSTRAINT fk_cv_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES Vehiculo (id_vehiculo),
    CONSTRAINT ck_cv_estado CHECK (estado_permiso IN ('VIGENTE','VENCIDO','REVOCADO')),
    CONSTRAINT ck_cv_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_asignacion)
);

-- 3. ABASTECIMIENTO

CREATE TABLE Planta_Refineria (
    id_planta         NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre            VARCHAR2(100) NOT NULL,
    tipo_planta       VARCHAR2(40),
    departamento      VARCHAR2(50),
    ubicacion         VARCHAR2(150),
    capacidad_litros  NUMBER(12,2),
    estado            VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_planta PRIMARY KEY (id_planta),
    CONSTRAINT ck_planta_capacidad CHECK (capacidad_litros IS NULL OR capacidad_litros > 0),
    CONSTRAINT ck_planta_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE Estacion_servicio (
    id_estacion    NUMBER GENERATED ALWAYS AS IDENTITY,
    codigo_anh     VARCHAR2(20),
    nombre         VARCHAR2(100) NOT NULL,
    departamento   VARCHAR2(50),
    localidad      VARCHAR2(80),
    ubicacion_geo  VARCHAR2(150),
    latitud        NUMBER(9,6),
    longitud       NUMBER(9,6),
    estado         VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_estacion PRIMARY KEY (id_estacion),
    CONSTRAINT uq_estacion_anh UNIQUE (codigo_anh),
    CONSTRAINT ck_estacion_lat CHECK (latitud IS NULL OR latitud BETWEEN -90 AND 90),
    CONSTRAINT ck_estacion_lon CHECK (longitud IS NULL OR longitud BETWEEN -180 AND 180),
    CONSTRAINT ck_estacion_estado CHECK (estado IN ('ACTIVO','INACTIVO'))
);

CREATE TABLE Distribucion_combustible (
    id_distribucion      NUMBER GENERATED ALWAYS AS IDENTITY,   -- tambien sirve como lote
    id_planta            NUMBER NOT NULL,
    id_estacion          NUMBER NOT NULL,
    id_tipo_combustible  NUMBER NOT NULL,
    fecha_salida         TIMESTAMP,
    fecha_llegada        TIMESTAMP,
    litros_enviados      NUMBER(12,2),
    estado               VARCHAR2(20) DEFAULT 'EN_TRANSITO' NOT NULL,
    CONSTRAINT pk_distribucion PRIMARY KEY (id_distribucion),
    CONSTRAINT fk_dist_planta FOREIGN KEY (id_planta)
        REFERENCES Planta_Refineria (id_planta),
    CONSTRAINT fk_dist_estacion FOREIGN KEY (id_estacion)
        REFERENCES Estacion_servicio (id_estacion),
    CONSTRAINT fk_dist_tipo_comb FOREIGN KEY (id_tipo_combustible)
        REFERENCES Tipo_Combustible (id_tipo_combustible),
    CONSTRAINT ck_dist_litros CHECK (litros_enviados IS NULL OR litros_enviados > 0),
    CONSTRAINT ck_dist_fechas CHECK (fecha_llegada IS NULL OR fecha_salida IS NULL
                                     OR fecha_llegada >= fecha_salida),
    CONSTRAINT ck_dist_estado CHECK (estado IN ('EN_TRANSITO','ENTREGADO','CANCELADO'))
);

CREATE TABLE Inventario_Estacion (
    id_inventario        NUMBER GENERATED ALWAYS AS IDENTITY,
    id_estacion          NUMBER NOT NULL,
    id_tipo_combustible  NUMBER NOT NULL,
    fecha                DATE NOT NULL,
    existencia_inicial   NUMBER(12,2) NOT NULL,
    litros_recibidos     NUMBER(12,2) DEFAULT 0 NOT NULL,
    litros_vendidos      NUMBER(12,2) DEFAULT 0 NOT NULL,
    saldo                NUMBER(12,2) NOT NULL,   -- inicial + recibidos - vendidos
    CONSTRAINT pk_inventario PRIMARY KEY (id_inventario),
    CONSTRAINT uq_inventario_dia UNIQUE (id_estacion, id_tipo_combustible, fecha),
    CONSTRAINT fk_inv_estacion FOREIGN KEY (id_estacion)
        REFERENCES Estacion_servicio (id_estacion),
    CONSTRAINT fk_inv_tipo_comb FOREIGN KEY (id_tipo_combustible)
        REFERENCES Tipo_Combustible (id_tipo_combustible),
    CONSTRAINT ck_inv_valores CHECK (existencia_inicial >= 0 AND litros_recibidos >= 0
                                     AND litros_vendidos >= 0 AND saldo >= 0)
);

CREATE TABLE Reclamo_Calidad (
    id_reclamo       NUMBER GENERATED ALWAYS AS IDENTITY,
    id_estacion      NUMBER NOT NULL,
    id_distribucion  NUMBER,                  -- lote reclamado
    fecha            TIMESTAMP NOT NULL,
    descripcion      VARCHAR2(255),
    estado           VARCHAR2(20) DEFAULT 'ABIERTO' NOT NULL,
    CONSTRAINT pk_reclamo PRIMARY KEY (id_reclamo),
    CONSTRAINT fk_reclamo_estacion FOREIGN KEY (id_estacion)
        REFERENCES Estacion_servicio (id_estacion),
    CONSTRAINT fk_reclamo_distribucion FOREIGN KEY (id_distribucion)
        REFERENCES Distribucion_combustible (id_distribucion),
    CONSTRAINT ck_reclamo_estado CHECK (estado IN ('ABIERTO','EN_REVISION','CERRADO'))
);

-- 4. TRANSACCIONES Y CONTROL

-- id_asignacion debe ser una asignacion vigente.
-- Esa validacion se hace despues con un trigger 
CREATE TABLE Transaccion_carga (
    id_transaccion       NUMBER GENERATED ALWAYS AS IDENTITY,
    id_asignacion        NUMBER NOT NULL,
    id_estacion          NUMBER NOT NULL,
    id_tipo_combustible  NUMBER NOT NULL,
    fecha                TIMESTAMP NOT NULL,
    litros_cargados      NUMBER(10,2) NOT NULL,
    monto_total          NUMBER(12,2),
    estado_validacion    VARCHAR2(30) DEFAULT 'VALIDA' NOT NULL,
    observacion          VARCHAR2(255),
    CONSTRAINT pk_transaccion PRIMARY KEY (id_transaccion),
    CONSTRAINT fk_trx_asignacion FOREIGN KEY (id_asignacion)
        REFERENCES Conductor_Vehiculo (id_asignacion),
    CONSTRAINT fk_trx_estacion FOREIGN KEY (id_estacion)
        REFERENCES Estacion_servicio (id_estacion),
    CONSTRAINT fk_trx_tipo_comb FOREIGN KEY (id_tipo_combustible)
        REFERENCES Tipo_Combustible (id_tipo_combustible),
    CONSTRAINT ck_trx_litros CHECK (litros_cargados > 0),
    CONSTRAINT ck_trx_monto CHECK (monto_total IS NULL OR monto_total >= 0),
    CONSTRAINT ck_trx_estado CHECK (estado_validacion IN ('VALIDA','OBSERVADA','RECHAZADA'))
);

CREATE TABLE Regla_limite (
    id_regla              NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre_regla          VARCHAR2(100) NOT NULL,
    descripcion           VARCHAR2(255),
    volumen_max_litros    NUMBER(10,2),
    frecuencia_carga_max  NUMBER(5),
    periodo_horas         NUMBER(6),
    esta_activa           NUMBER(1) DEFAULT 1 NOT NULL,   -- 1 = activa, 0 = inactiva
    CONSTRAINT pk_regla PRIMARY KEY (id_regla),
    CONSTRAINT ck_regla_volumen CHECK (volumen_max_litros IS NULL OR volumen_max_litros > 0),
    CONSTRAINT ck_regla_frecuencia CHECK (frecuencia_carga_max IS NULL OR frecuencia_carga_max > 0),
    CONSTRAINT ck_regla_periodo CHECK (periodo_horas IS NULL OR periodo_horas > 0),
    CONSTRAINT ck_regla_activa CHECK (esta_activa IN (0,1))
);

-- El vehiculo se obtiene a traves de la transaccion (evita redundancia, 3FN)
CREATE TABLE Incumplimiento (
    id_incumplimiento  NUMBER GENERATED ALWAYS AS IDENTITY,
    id_regla           NUMBER NOT NULL,
    id_transaccion     NUMBER NOT NULL,
    fecha              TIMESTAMP NOT NULL,
    descripcion        VARCHAR2(255),
    estado             VARCHAR2(20) DEFAULT 'DETECTADO' NOT NULL,
    CONSTRAINT pk_incumplimiento PRIMARY KEY (id_incumplimiento),
    CONSTRAINT fk_inc_regla FOREIGN KEY (id_regla)
        REFERENCES Regla_limite (id_regla),
    CONSTRAINT fk_inc_transaccion FOREIGN KEY (id_transaccion)
        REFERENCES Transaccion_carga (id_transaccion),
    CONSTRAINT ck_inc_estado CHECK (estado IN ('DETECTADO','EN_REVISION','CONFIRMADO','DESCARTADO'))
);

CREATE TABLE Alerta (
    id_alerta          NUMBER GENERATED ALWAYS AS IDENTITY,
    id_incumplimiento  NUMBER NOT NULL,
    tipo_alerta        VARCHAR2(40) NOT NULL,
    fecha              TIMESTAMP NOT NULL,
    descripcion        VARCHAR2(255),
    nivel              VARCHAR2(20) DEFAULT 'MEDIO' NOT NULL,
    estado_atencion    VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    fecha_atencion     TIMESTAMP,
    CONSTRAINT pk_alerta PRIMARY KEY (id_alerta),
    CONSTRAINT fk_alerta_incumplimiento FOREIGN KEY (id_incumplimiento)
        REFERENCES Incumplimiento (id_incumplimiento),
    CONSTRAINT ck_alerta_nivel CHECK (nivel IN ('BAJO','MEDIO','ALTO','CRITICO')),
    CONSTRAINT ck_alerta_atencion CHECK (estado_atencion IN
        ('PENDIENTE','EN_ATENCION','RESUELTA','DESCARTADA'))
);

CREATE TABLE Cupo (
    id_cupo                 NUMBER GENERATED ALWAYS AS IDENTITY,
    id_vehiculo             NUMBER NOT NULL,
    cupo_disponible_litros  NUMBER(10,2),
    fecha_actualizada       TIMESTAMP,
    CONSTRAINT pk_cupo PRIMARY KEY (id_cupo),
    CONSTRAINT fk_cupo_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES Vehiculo (id_vehiculo),
    CONSTRAINT ck_cupo_litros CHECK (cupo_disponible_litros IS NULL OR cupo_disponible_litros >= 0)
);

CREATE TABLE Formulario_Bidones (
    id_formulario        NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre_solicitante   VARCHAR2(100) NOT NULL,
    ci_dni               VARCHAR2(20) NOT NULL,
    id_tipo_combustible  NUMBER NOT NULL,
    cantidad_litros      NUMBER(10,2) NOT NULL,
    motivo               VARCHAR2(255),
    fecha_solicitud      TIMESTAMP,
    id_estacion          NUMBER NOT NULL,
    estado               VARCHAR2(30) DEFAULT 'PENDIENTE' NOT NULL,
    observacion          VARCHAR2(255),
    CONSTRAINT pk_formulario PRIMARY KEY (id_formulario),
    CONSTRAINT fk_form_tipo_comb FOREIGN KEY (id_tipo_combustible)
        REFERENCES Tipo_Combustible (id_tipo_combustible),
    CONSTRAINT fk_form_estacion FOREIGN KEY (id_estacion)
        REFERENCES Estacion_servicio (id_estacion),
    CONSTRAINT ck_form_cantidad CHECK (cantidad_litros > 0),
    CONSTRAINT ck_form_estado CHECK (estado IN ('PENDIENTE','APROBADO','RECHAZADO','ENTREGADO'))
);

-- 5. SEGURIDAD Y AUDITORIA

CREATE TABLE Usuario_Sistema (
    id_usuario       NUMBER GENERATED ALWAYS AS IDENTITY,
    username         VARCHAR2(50) NOT NULL,
    password_hash    VARCHAR2(255) NOT NULL,   -- siempre hash, nunca texto plano
    nombre_completo  VARCHAR2(100),
    rol              VARCHAR2(30) NOT NULL,
    estado           VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT pk_usuario_sistema PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_username UNIQUE (username),
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('ADMINISTRADOR','OPERADOR','AUDITOR','SOLO_LECTURA')),
    CONSTRAINT ck_usuario_estado CHECK (estado IN ('ACTIVO','INACTIVO','BLOQUEADO'))
);

CREATE TABLE Auditoria_Log (
    id_log          NUMBER GENERATED ALWAYS AS IDENTITY,
    usuario         VARCHAR2(50) NOT NULL,     -- quien
    fecha           TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,   -- cuando
    tabla_afectada  VARCHAR2(50) NOT NULL,     -- que tabla
    operacion       VARCHAR2(10) NOT NULL,     -- que operacion
    id_registro     VARCHAR2(50),
    detalle         VARCHAR2(500),
    CONSTRAINT pk_auditoria_log PRIMARY KEY (id_log),
    CONSTRAINT ck_auditoria_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);

-- mostrar 19 tablas

SELECT table_name FROM user_tables ORDER BY table_name;
