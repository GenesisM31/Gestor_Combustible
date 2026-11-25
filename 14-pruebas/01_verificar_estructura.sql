SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON
COLUMN table_name FORMAT A28
COLUMN constraint_name FORMAT A34
COLUMN column_name FORMAT A26
COLUMN referencia FORMAT A26
COLUMN search_condition_vc FORMAT A60

PROMPT === 1. TABLAS CREADAS ===
SELECT COUNT(*) AS total_tablas FROM user_tables;
SELECT table_name FROM user_tables ORDER BY 1;

PROMPT === 2. RESTRICCIONES POR TIPO (P=PK, R=FK, U=UNIQUE, C=CHECK/NOT NULL) ===
SELECT constraint_type, COUNT(*) AS cantidad
FROM user_constraints GROUP BY constraint_type ORDER BY 1;

PROMPT === 3. TABLAS SIN CLAVE PRIMARIA (debe salir 0 filas) ===
SELECT table_name FROM user_tables
WHERE table_name NOT IN (SELECT table_name FROM user_constraints WHERE constraint_type = 'P');

PROMPT === 4. CLAVES FORANEAS Y A QUE TABLA APUNTAN ===
SELECT c.table_name, c.constraint_name, r.table_name AS referencia
FROM user_constraints c
JOIN user_constraints r ON r.constraint_name = c.r_constraint_name
WHERE c.constraint_type = 'R' ORDER BY 1, 2;

PROMPT === 5. CHECK DE NEGOCIO (sin los NOT NULL) ===
SELECT table_name, constraint_name, search_condition_vc
FROM user_constraints
WHERE constraint_type = 'C' AND search_condition_vc NOT LIKE '%IS NOT NULL'
ORDER BY 1, 2;

PROMPT === 6. COLUMNAS FK SIN INDICE (candidatas para 02_indices.sql) ===
SELECT c.table_name, cc.column_name
FROM user_constraints c
JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
WHERE c.constraint_type = 'R'
AND NOT EXISTS (SELECT 1 FROM user_ind_columns ic
                WHERE ic.table_name = cc.table_name
                AND ic.column_name = cc.column_name AND ic.column_position = 1)
ORDER BY 1, 2;

PROMPT === 7. OBJETOS INVALIDOS (debe salir 0 filas) ===
SELECT object_name, object_type FROM user_objects WHERE status <> 'VALID';
