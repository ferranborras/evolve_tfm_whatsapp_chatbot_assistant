"""
Agrega y analiza las métricas de rendimiento del scraping semanal de TikTok/Reels almacenadas 
en la tabla `tiktok_trends`. Actúa como el motor de recuperación de datos (RAG) para el agente 
de generación de ideas, sintetizando el volumen de datos brutos en insights estructurados.

MÉTRICAS Y SALIDAS CALCULADAS:
1. top_hashtags (JSONB):
   - Extrae los hashtags de las publicaciones.
   - Calcula el volumen total de menciones y el crecimiento promedio (`avg_growth`) por etiqueta.
   - Devuelve las etiquetas con mayor impacto para la selección contextual del LLM.

2. top_time_slots (JSONB):
   - Agrupa las publicaciones por día de la semana y franja horaria a partir de `created_at_local`.
   - Identifica los momentos de publicación con mayor densidad de vídeos virales/interacción.

3. top_videos (JSONB):
   - Filtra y selecciona los 15-20 vídeos con mayor `growth_score`.
   - Proporciona al LLM los patrones de conceptos, ganchos (hooks) y formatos con mejor rendimiento.

RETORNO:
Un registro con 3 objetos JSONB (`top_hashtags`, `top_time_slots`, `top_videos`) listo para 
ser inyectado como contexto directo en el prompt del agente dentro de n8n.
"""
CREATE OR REPLACE FUNCTION get_weekly_insights()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'top_videos', (
      SELECT json_agg(v) 
      FROM (
        SELECT
          id,
          description,
          hashtags,
          music_name,
          video_url,
          play_count,
          like_count,
          growth_score,
          created_at_local
        FROM tiktok_trends
        WHERE created_at > now() - interval '7 days'
        ORDER BY growth_score DESC
        LIMIT 10
      ) v
    ),
    'top_hashtags', (
      SELECT json_agg(h) 
      FROM (
        SELECT
          hashtag,
          COUNT(*) as frequency,
          ROUND(AVG(growth_score)) as avg_growth
        FROM
          tiktok_trends,
          jsonb_array_elements_text(hashtags::jsonb) as hashtag
        WHERE created_at > now() - interval '7 days'
        GROUP BY hashtag
        ORDER BY frequency DESC, avg_growth DESC
        LIMIT 10
      ) h
    ),
    'top_time_slots', (
      SELECT json_agg(t) 
      FROM (
        SELECT
          EXTRACT(DOW FROM created_at_local) AS day_of_week,
          EXTRACT(HOUR FROM created_at_local) AS hour_of_day,
          COUNT(*) AS video_count,
          ROUND(AVG(growth_score)) AS avg_growth
        FROM tiktok_trends
        GROUP BY day_of_week, hour_of_day
        HAVING COUNT(*) >= 2
        ORDER BY avg_growth DESC
        LIMIT 10
      ) t
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;