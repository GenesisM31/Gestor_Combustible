-- Ejecutar como COMB_OWNER (dueño de las tablas) despues del DDL.
-- Principio de minimo privilegio:
--   rol_app_comb     : leer, insertar y actualizar; NUNCA borrar
--   rol_lectura_comb : solo leer (no ve usuarios ni auditoria)
--   auditor_comb     : solo lee la bitacora de auditoria
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    IF t.table_name = 'AUDITORIA_LOG' THEN
      NULL;  -- la app no la toca; la llena un trigger
    ELSIF t.table_name = 'USUARIO_SISTEMA' THEN
      EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE ON ' || t.table_name || ' TO rol_app_comb';
    ELSIF t.table_name IN ('TIPO_COMBUSTIBLE','CATEGORIA_VEHICULO',
                           'REGLA_LIMITE','PLANTA_REFINERIA') THEN
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO rol_app_comb';
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO rol_lectura_comb';
    ELSE
      EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE ON ' || t.table_name || ' TO rol_app_comb';
      EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO rol_lectura_comb';
    END IF;
  END LOOP;
END;
/
GRANT SELECT ON Auditoria_Log TO auditor_comb;
