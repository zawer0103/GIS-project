CREATE OR REPLACE FUNCTION public.cable_channels_channels_add_pits() RETURNS trigger AS $cable_channels_channels_add_pits$

DECLARE 
  city name :=TG_TABLE_SCHEMA;
  geom_start_point_state boolean;
  geom_end_point_state boolean;
BEGIN 
  IF  TG_OP = 'INSERT' THEN  -- запустил на киеве - конкретно с этим проблем нет -- почему трабл при всавке колодца?

              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    pit_1= '||city||'_cable_channel_pits.pit_number,
                    pit_1_geom = '||city||'_cable_channel_pits.geom,
                    pit_id_1= '||city||'_cable_channel_pits.pit_id,
                    she_n_1 = '||city||'_cable_channel_pits.pit_district
                  
                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  (ST_Distance(ST_StartPoint($1.channel_geom),'||city||'_cable_channel_pits.geom) <= 2.0 AND '||city||'_cable_channels_channels.id = $1.id) ' USING NEW;

              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    pit_2= '||city||'_cable_channel_pits.pit_number,
                    pit_2_geom = '||city||'_cable_channel_pits.geom,
                    pit_id_2= '||city||'_cable_channel_pits.pit_id

                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  (ST_Distance(ST_EndPoint($1.channel_geom),'||city||'_cable_channel_pits.geom) <= 2.0 AND '||city||'_cable_channels_channels.id = $1.id) ' USING NEW; --проверил норм 

                  EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    channel_geom = ST_MakeLine(pit_1_geom, pit_2_geom),
                    map_distance = round( CAST(st_distance(pit_1_geom, pit_2_geom) as numeric),2)
                    WHERE  '||city||'_cable_channels_channels.id = $1.id ' USING NEW; -- рисуем линию заново с привязкой к колодцам--проверил норм

              RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN  -- по идее при попытке изменить канал ККЕ, нужно перепривязываться к новым колодцам. 
  ---но делать сделать тоже что и при insert невозможно - включаеться бесконечный цикл. что делать пока не понятно
  -- по-хорошему канал ККЕ нужно удалить и нарисовать заново. об этом должно быть сказано в инструкции
                
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN 
    EXECUTE '' USING OLD;
    RETURN OLD;

-------------------------
  END IF; 
END;
   --------------
   $cable_channels_channels_add_pits$ LANGUAGE plpgsql;

/*CREATE TRIGGER cable_channels_channels_add_pits AFTER INSERT OR UPDATE OR DELETE ON fastiv.fastiv_cable_channels_channels
    FOR EACH ROW EXECUTE PROCEDURE cable_channels_channels_add_pits(); -- если сделать тригер before то нихрена не работает*/
