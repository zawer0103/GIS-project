
CREATE OR REPLACE FUNCTION public.ctv_move_cable_geom() RETURNS trigger AS $ctv_move_cable_geom$ 



-- триггер на таблицы  _ctv_topology
--!логично установить тригер только на поле geom ? тут же только поле geom перезаписыветься !

DECLARE 
  city name :=TG_TABLE_SCHEMA;

  BEGIN 
       
    IF TG_OP = 'UPDATE' THEN 
----- обновляем оптику ВКП
             
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_air 
        SET  geom_cable=ST_SetPoint(geom_cable,0,$1.equipment_geom)   WHERE  cubic_code_start=$1.cubic_code ; 
        UPDATE '||city||'.'||city||'_cable_air  
        SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,$1.equipment_geom)   WHERE  cubic_code_end=$1.cubic_code ;                        
        '
            USING NEW;  --
           
-- обновляем ККЕ--

        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels 
        SET  geom_cable=ST_SetPoint(geom_cable,0,$1.equipment_geom)   WHERE  cubic_code_start=$1.cubic_code ; 
        UPDATE '||city||'.'||city||'_cable_channels  
        SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,$1.equipment_geom)   WHERE  cubic_code_end=$1.cubic_code ; 
                '
          USING NEW;  --
         RETURN NEW; --
-- вот єта часть больше не нужна
 /*------обновляем таблицу кабелей для малювання        
EXECUTE 'UPDATE '||city||'.'||city||'_cable_air_cable_geom air_geom
         SET geom = air.geom_cable FROM  '||city||'.'||city||'_cable_air air WHERE air_geom.table_id=air.table_id AND geom_cable IS NOT NULL AND geom IS NOT NULL AND st_equals(air_geom.geom,air.geom_cable) = FALSE ; --  вроде ок. зависает только на  ККЕ  _cable_channel_cable_geom не понятно что с ними не так наверно индексі
         UPDATE '||city||'.'||city||'_cable_channel_cable_geom cable_geom
           SET geom = cable.geom_cable FROM  '||city||'.'||city||'_cable_channels cable WHERE cable_geom.table_id=cable.table_id  AND geom_cable IS NOT NULL AND geom IS NOT NULL AND st_equals(cable_geom.geom,cable.geom_cable) = FALSE ; -- и на нём всё и зависает NOT NULL не помог st_equals не помог что странно !!!
         '
          USING NEW;  --
  */
          
      -- если подвинуть всё, то затупило жутко!!!  SET geom = geom_cable  - ЭТО ПРОБЛЕМА что оно делает? вызывает по кругу новый триггер или что?
      --- если подвинуь пару штук  в БЦ- всё ОК.  в Киеве - полный ТОРМОЗ. ЧТО НЕ ТАК? делаю откат на версию с tmp TABLE
      -- ХЗ що делать -- есть вариант созадть отдельные вьюшки для _ctv_topology  - оптика и коаксиал
------------------------------

      ------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE '' USING OLD;
      RETURN OLD; -- 
    END IF; 
END;
   --------------
   $ctv_move_cable_geom$ LANGUAGE plpgsql;

--CREATE TRIGGER ctv_move_cable_geom AFTER UPDATE OF equipment_geom ON kiev_ctv_topology FOR EACH ROW EXECUTE PROCEDURE ctv_move_cable_geom()
