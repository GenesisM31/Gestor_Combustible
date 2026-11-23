SET LINESIZE 200 PAGESIZE 50
COLUMN dbusername FORMAT A15
COLUMN action_name FORMAT A18
COLUMN object_name FORMAT A22
COLUMN event_timestamp FORMAT A28

SELECT event_timestamp, dbusername, action_name, object_name, return_code
FROM   unified_audit_trail
ORDER  BY event_timestamp DESC
FETCH  FIRST 20 ROWS ONLY;

SELECT event_timestamp, dbusername, return_code
FROM   unified_audit_trail
WHERE  action_name = 'LOGON' AND return_code <> 0
ORDER  BY event_timestamp DESC;
