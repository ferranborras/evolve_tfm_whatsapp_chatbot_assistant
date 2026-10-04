"""
Crea una copia de seguridad de cada tabla con el contenido de cada una en el instante.
"""
DROP TABLE IF EXISTS users_backup;
CREATE TABLE users_backup AS 
SELECT * FROM users;

DROP TABLE IF EXISTS chat_messages_backup;
CREATE TABLE chat_messages_backup AS 
SELECT * FROM chat_messages;

DROP TABLE IF EXISTS tiktok_trends_backup;
CREATE TABLE tiktok_trends_backup AS 
SELECT * FROM tiktok_trends;

DROP TABLE IF EXISTS weekly_ideas_backup;
CREATE TABLE weekly_ideas_backup AS 
SELECT * FROM weekly_ideas;

DROP TABLE IF EXISTS whatsapp_logs_backup;
CREATE TABLE whatsapp_logs_backup AS 
SELECT * FROM whatsapp_logs;


"""
Recupera la información de las copias de seguridad.
"""
CREATE OR REPLACE FUNCTION restore_all_tables_from_backup()
RETURNS void AS $$
DECLARE
    r RECORD;
    target_table TEXT;
    backup_table TEXT;
BEGIN
    -- Recorremos todas las tablas que terminen en '_backup' dentro del esquema público
    FOR r IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
          AND table_type = 'BASE TABLE'
          AND table_name LIKE '%\_backup' ESCAPE '\'
    LOOP
        backup_table := r.table_name;
        -- Obtenemos el nombre de la tabla destino quitando el sufijo '_backup'
        target_table := substring(backup_table FROM 1 FOR length(backup_table) - 7);

        -- Comprobamos si la tabla de destino existe antes de intentar la restauración
        IF EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
              AND table_name = target_table
        ) THEN
            RAISE NOTICE 'Restaurando % desde %...', target_table, backup_table;

            -- 1. Vaciamos la tabla de destino y sus dependencias (CASCADE)
            EXECUTE format('TRUNCATE TABLE %I CASCADE;', target_table);

            -- 2. Copiamos todos los datos de vuelta desde la tabla de backup
            EXECUTE format('INSERT INTO %I SELECT * FROM %I;', target_table, backup_table);
        ELSE
            RAISE WARNING 'La tabla de destino % no existe. Omitiendo %...', target_table, backup_table;
        END IF;
    END LOOP;
    
    RAISE NOTICE '¡Restauración completada con éxito!';
END;
$$ LANGUAGE plpgsql;