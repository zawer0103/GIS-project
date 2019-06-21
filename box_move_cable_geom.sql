--CREATE TRIGGER box_splice_move_cable_geom AFTER UPDATE or DELETE ON   '||city||'.'||city||'_box_splice FOR EACH ROW EXECUTE PROCEDURE  public.box_move_cable_geom(); -- это см в PHP

CREATE OR REPLACE FUNCTION public.box_move_cable_geom() RETURNS trigger AS $box_move_cable_geom$ 
-- триггер на таблицы ящиков  _box_splice
--логично установить тригер только на поле geom ? тут же только поле geom перезаписыветься !
-- на INSERT триггер вообще не нужен. а на DELETE по-хорошему нужно подтереть данные, только вот они могут быть от таблиц _ctv поэтому лучше ничего не делать
DECLARE 
  city name :=TG_TABLE_SCHEMA;

  BEGIN 
       
    IF TG_OP = 'UPDATE' THEN 
----- обновляем оптику ВКП
             
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_air 
        SET  geom_cable=ST_SetPoint(geom_cable,0,$1.geom)   WHERE  cubic_code_start=$1.mid ; 
        UPDATE '||city||'.'||city||'_cable_air  
        SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,$1.geom)   WHERE  cubic_code_end=$1.mid ; 
        
                    
        '
            USING NEW;  --
           
-- обновляем ККЕ--

        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels 
        SET  geom_cable=ST_SetPoint(geom_cable,0,$1.geom)   WHERE  cubic_code_start=$1.mid ; 
        UPDATE '||city||'.'||city||'_cable_channels  
        SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,$1.geom)   WHERE  cubic_code_end=$1.mid ; 
        
        '
          USING NEW;  --
         

 ------обновляем таблицу кабелей для малювання      
EXECUTE 'UPDATE '||city||'.'||city||'_cable_air_cable_geom air_geom
         SET geom = air.geom_cable FROM  '||city||'.'||city||'_cable_air air WHERE air_geom.table_id=air.table_id AND geom_cable IS NOT NULL AND geom IS NOT NULL AND st_equals(air_geom.geom,air.geom_cable) = FALSE ; --  
         UPDATE '||city||'.'||city||'_cable_channel_cable_geom cable_geom
           SET geom = cable.geom_cable FROM  '||city||'.'||city||'_cable_channels cable WHERE cable_geom.table_id=cable.table_id  AND geom_cable IS NOT NULL AND geom IS NOT NULL AND st_equals(cable_geom.geom,cable.geom_cable) = FALSE ; -- 
         '
          USING NEW;  --
          RETURN NEW; --

      -- если подвинуть всё, то затупило жутко!!!  
      --- если подвинуь пару штук  всё ОК. 
      -- в Киеве - полный ТОРМОЗ. -- как всегда  проблема с индексами на таблице _cable_channels пришлось вручную править 
------------------------------

      ------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE '' USING OLD;
      RETURN OLD; -- 
    END IF; 
END;
   --------------
   $box_move_cable_geom$ LANGUAGE plpgsql;