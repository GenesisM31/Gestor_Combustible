-- Ejecutar como SYS en FREEPDB1.
-- Uso: @01_usuarios_roles.sql <owner> <admin> <app> <auditor> <lectura>
SET VERIFY OFF
CREATE PROFILE perfil_combustible LIMIT
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LOCK_TIME    1/24
  PASSWORD_LIFE_TIME    90
  PASSWORD_REUSE_MAX    5
  PASSWORD_GRACE_TIME   7
  IDLE_TIME             30;

CREATE ROLE rol_admin_comb;
GRANT CREATE SESSION, CREATE USER, ALTER USER, DROP USER,
      CREATE ROLE, CREATE PROFILE, ALTER PROFILE TO rol_admin_comb;

CREATE ROLE rol_app_comb;
GRANT CREATE SESSION TO rol_app_comb;

CREATE ROLE rol_lectura_comb;
GRANT CREATE SESSION TO rol_lectura_comb;

CREATE USER comb_owner IDENTIFIED BY "&1"
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users PROFILE perfil_combustible;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE MATERIALIZED VIEW,
      CREATE SYNONYM TO comb_owner;

CREATE USER admin_comb IDENTIFIED BY "&2" PROFILE perfil_combustible;
GRANT rol_admin_comb TO admin_comb;

CREATE USER app_comb IDENTIFIED BY "&3" PROFILE perfil_combustible;
GRANT rol_app_comb TO app_comb;

CREATE USER auditor_comb IDENTIFIED BY "&4" PROFILE perfil_combustible;
GRANT CREATE SESSION TO auditor_comb;
GRANT AUDIT_VIEWER TO auditor_comb;

CREATE USER lectura_comb IDENTIFIED BY "&5" PROFILE perfil_combustible;
GRANT rol_lectura_comb TO lectura_comb;
