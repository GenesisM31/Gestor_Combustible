SET MARKUP CSV ON QUOTE ON
SET FEEDBACK OFF
SET PAGESIZE 50000
SET LINESIZE 300
SELECT tc.table_name AS tabla,
       tc.column_name AS campo,
       tc.data_type AS tipo,
       CASE WHEN tc.data_type = 'NUMBER'
            THEN TO_CHAR(tc.data_precision) || CASE WHEN tc.data_scale > 0 THEN ',' || tc.data_scale END
            WHEN tc.data_type LIKE '%CHAR%' THEN TO_CHAR(tc.char_length)
            END AS tamano,
       CASE tc.nullable WHEN 'Y' THEN 'SI' ELSE 'NO' END AS permite_null,
       CASE WHEN pk.column_name IS NOT NULL THEN 'PK' END AS pk,
       fk.referencia AS fk_hacia,
       NULL AS descripcion
FROM user_tab_columns tc
LEFT JOIN (SELECT cc.table_name, cc.column_name
           FROM user_constraints c
           JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
           WHERE c.constraint_type = 'P') pk
       ON pk.table_name = tc.table_name AND pk.column_name = tc.column_name
LEFT JOIN (SELECT cc.table_name, cc.column_name, r.table_name AS referencia
           FROM user_constraints c
           JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
           JOIN user_constraints r ON r.constraint_name = c.r_constraint_name
           WHERE c.constraint_type = 'R') fk
       ON fk.table_name = tc.table_name AND fk.column_name = tc.column_name
ORDER BY tc.table_name, tc.column_id;
