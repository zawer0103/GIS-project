CREATE OR REPLACE FUNCTION public.cable_channels_coax_data_update() RETURNS trigger AS $cable_channels_coax_data_update$
--!!!!!!  использую для  замены оригинальной функции cable_channels_coax_data_update  !!!!!!!!!!!!! --
DECLARE 
  city name :=TG_TABLE_SCHEMA;
  geom_start_point_state boolean;
  geom_end_point_state boolean;
  geom_start_point_state_house boolean;
  geom_end_point_state_house boolean;
  BEGIN 
  IF  TG_OP = 'INSERT' THEN 
  --оригинальная функция cable_channels_coax_data_update () 
-----ниже моя вставка для упрощённого подхода к рисованию(можно вносить тип кабеля напр QR-540 и/или длина )
-- тут есть некий дисонанс: если мы пытаемя обновить поля в слое "для рисования" система не даёт их перезаписать и в слоях кабели_ВКП_для_рисования и в кабели_ВКП будут разные данные - это будет вносить сумятицу: в связи с чем есть идея: затирать данные в таблице кабели_ВКП_для_рисования (добавил ниже)
--все таблицы типа _cable_channel_coax_geom  поле cable_description (марка кабеля- по умолчанию нет этого поля в таблицах _cable_channel_coax_geom) и заменить в скриптах ниже cable_description  на cable_description !
-- нужно ещё будет подумать об исключениях RAISE EXCEPTION https://stackoverflow.com/questions/42890652/update-a-column-in-a-function-using-plpgsql
-- добавить во все таблицы _cable_channels_coax   в поле cable_type значение по умолчанию 'optic' !!!


            EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_short_type_description = '||city||'_cable_channel_coax_geom.cable_short_type_description
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.cable_short_type_description is NULL;
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_description = '||city||'_cable_channel_coax_geom.cable_description
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.cable_description is NULL; 
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              total_cable_length='||city||'_cable_channel_coax_geom.total_cable_length
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.total_cable_length is NULL;
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_type=DEFAULT
            WHERE  '||city||'_cable_channels_coax.cable_type is NULL and '||city||'_cable_channels_coax.cable_short_type_description is NOT NULL;'         USING NEW;
         EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_coax_geom
            SET
              cable_short_type_description = NULL,
              cable_description = NULL,
              total_cable_length = NULL
                        
            WHERE  '||city||'_cable_channel_coax_geom.cable_short_type_description is NOT NULL OR '||city||'_cable_channel_coax_geom.cable_description is NOT NULL OR '||city||'_cable_channel_coax_geom.total_cable_length is NOT NULL' USING NEW; /* затираем данные после сохранения вроде работает норм*/
        
----------------
---------ниже  вставка  привязки домов к концам кабеля  (подъезды обновляем отдельно)----------------
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_buildings WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_buildings.building_geom) <= 4.1 ' INTO geom_start_point_state_house USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_buildings WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_buildings.building_geom) <= 4.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_start_house_id = '||city||'_buildings.cubic_house_id,
                    cubic_start_street = '||city||'_buildings.cubic_street,
                    cubic_start_house_num = '||city||'_buildings.cubic_house
                  
                  FROM '||city||'.'||city||'_buildings
                  WHERE  (ST_Distance(ST_StartPoint($1.geom),'||city||'_buildings.building_geom) <= 4.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;

            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_end_house_id = '||city||'_buildings.cubic_house_id,
                    cubic_end_street = '||city||'_buildings.cubic_street,
                    cubic_end_house_num = '||city||'_buildings.cubic_house
                  
                  FROM '||city||'.'||city||'_buildings
                  WHERE  (ST_Distance(ST_EndPoint($1.geom),'||city||'_buildings.building_geom ) <= 4.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id)  ' USING NEW , city;

            END IF;
--------------------------ниже добавляем обновляем подъезды к концам кабеля --------
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_entrances WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_entrances.geom) <= 6.1 ' INTO geom_start_point_state_house USING NEW;
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_entrances WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_entrances.geom) <= 6.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_start_house_entrance_num = '||city||'_entrances.cubic_entrance_number
                  FROM '||city||'.'||city||'_entrances
                  WHERE  (ST_Distance(ST_StartPoint($1.geom),'||city||'_entrances.geom) <= 6.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;
             
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_end_house_entrance_num = '||city||'_entrances.cubic_entrance_number
                  FROM '||city||'.'||city||'_entrances
                  WHERE  (ST_Distance(ST_EndPoint($1.geom),'||city||'_entrances.geom ) <= 6.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id)  ' USING NEW , city;
                             
            END IF;
-------------------------

      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8 AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'') ' INTO geom_start_point_state USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8 AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'') ' INTO geom_end_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_start = '||city||'_ctv_topology.cubic_code,
              cubic_name_start = '||city||'_ctv_topology.cubic_name,
              cubic_coment_start = '||city||'_ctv_topology.cubic_coment,
              geom_start_point = '||city||'_ctv_topology.equipment_geom,
              geom_cable = ST_SetPoint($1.geom,0,'||city||'_ctv_topology.equipment_geom)
            FROM '||city||'.'||city||'_ctv_topology
            WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom),'||city||'_ctv_topology.equipment_geom) <= 2.8)) AND '||city||'_cable_channels_coax.table_id = $1.table_id AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'') ' USING NEW;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW;    
      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
        SET
          cubic_code_end = '||city||'_ctv_topology.cubic_code,
          cubic_name_end = '||city||'_ctv_topology.cubic_name,
          cubic_coment_end = '||city||'_ctv_topology.cubic_coment,
          geom_end_point = '||city||'_ctv_topology.equipment_geom,
          geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1,'||city||'_ctv_topology.equipment_geom)

        FROM '||city||'.'||city||'_ctv_topology
        WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8)) AND '||city||'_cable_channels_coax.table_id = $1.table_id AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'')  ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_end_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW; 
      END IF;
      
      RETURN NEW;
      
    ELSIF TG_OP = 'UPDATE' THEN 
-----ниже  вставка --это новый упрощённый подход к рисованию кабелей
-- тут есть некий дисонанс: если мы пытаемя обновить поля в слое "для рисования" система не даёт их перезаписать и в слоях кабели_ВКП_для_рисования и в кабели_ВКП будут разные данные - это будет вносить сумятицу: в связи с чем есть идея: затирать данные в таблице кабели_ВКП_для_рисования (скрипт добавил ниже)
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_short_type_description = '||city||'_cable_channel_coax_geom.cable_short_type_description
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.cable_short_type_description is NULL;
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_description = '||city||'_cable_channel_coax_geom.cable_description
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.cable_description is NULL; 
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              total_cable_length='||city||'_cable_channel_coax_geom.total_cable_length
            FROM '||city||'.'||city||'_cable_channel_coax_geom
            WHERE  '||city||'_cable_channels_coax.table_id = '||city||'_cable_channel_coax_geom.table_id and '||city||'_cable_channels_coax.total_cable_length is NULL; 
            UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cable_type=DEFAULT
            WHERE  '||city||'_cable_channels_coax.cable_type is NULL and '||city||'_cable_channels_coax.cable_short_type_description is NOT NULL;'        USING NEW;
            EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_coax_geom
            SET
              cable_short_type_description = NULL,
              cable_description = NULL,
              total_cable_length = NULL
                        
            WHERE  '||city||'_cable_channel_coax_geom.cable_short_type_description is NOT NULL OR '||city||'_cable_channel_coax_geom.cable_description is NOT NULL OR '||city||'_cable_channel_coax_geom.total_cable_length is NOT NULL' USING NEW; /*  затераем данные в cable_air_cable_geom после сохранения вроде работает норм*/
       
------------------------------
---------ниже  вставка  привязки домов к концам кабеля  (подъезды обновляем отдельно)---------------
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_buildings WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_buildings.building_geom) <= 4.1 ' INTO geom_start_point_state_house USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_buildings WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_buildings.building_geom) <= 4.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_start_house_id = '||city||'_buildings.cubic_house_id,
                    cubic_start_street = '||city||'_buildings.cubic_street,
                    cubic_start_house_num = '||city||'_buildings.cubic_house
                  
                  FROM '||city||'.'||city||'_buildings
                  WHERE  (ST_Distance(ST_StartPoint($1.geom),'||city||'_buildings.building_geom) <= 4.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;
            ELSE
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_start_house_id = NULL,
                    cubic_start_street = NULL,
                    cubic_start_house_num = NULL
                                
                  WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW;    
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_end_house_id = '||city||'_buildings.cubic_house_id,
                    cubic_end_street = '||city||'_buildings.cubic_street,
                    cubic_end_house_num = '||city||'_buildings.cubic_house
                  
                  FROM '||city||'.'||city||'_buildings
                  WHERE  (ST_Distance(ST_EndPoint($1.geom),'||city||'_buildings.building_geom ) <= 4.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id)  ' USING NEW , city;
            ELSE
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                    cubic_end_house_id = NULL,
                    cubic_end_street = NULL,
                    cubic_end_house_num = NULL
                                
                  WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW;    
            END IF;
--------добавляем обновление полей подъездов к концам кабеля -------
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_entrances WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_entrances.geom) <= 6.1 ' INTO geom_start_point_state_house USING NEW;
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_entrances WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_entrances.geom) <= 6.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_start_house_entrance_num = '||city||'_entrances.cubic_entrance_number
                  FROM '||city||'.'||city||'_entrances
                  WHERE  (ST_Distance(ST_StartPoint($1.geom),'||city||'_entrances.geom) <= 6.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;
                  ELSE 
                EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_start_house_entrance_num = NULL
                  
                  WHERE  ('||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_end_house_entrance_num = '||city||'_entrances.cubic_entrance_number
                  FROM '||city||'.'||city||'_entrances
                  WHERE  (ST_Distance(ST_EndPoint($1.geom),'||city||'_entrances.geom ) <= 6.1 AND '||city||'_cable_channels_coax.table_id = $1.table_id)  ' USING NEW , city;
                   ELSE 
                EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
                  SET
                  cubic_end_house_entrance_num = NULL
                  
                  WHERE  ('||city||'_cable_channels_coax.table_id = $1.table_id) ' USING NEW;          
            END IF;
-------------------------------------------------------------------------
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8 AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'')' INTO geom_start_point_state USING NEW;
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8 AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'')' INTO geom_end_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_start = '||city||'_ctv_topology.cubic_code,
              cubic_name_start = '||city||'_ctv_topology.cubic_name,
              cubic_coment_start = '||city||'_ctv_topology.cubic_coment,
              geom_start_point = '||city||'_ctv_topology.equipment_geom,
              geom_cable = ST_SetPoint($1.geom,0,'||city||'_ctv_topology.equipment_geom)
            FROM '||city||'.'||city||'_ctv_topology
            WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom),'||city||'_ctv_topology.equipment_geom) <= 2.8))   AND '||city||'_cable_channels_coax.table_id = $1.table_id AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'')  ' USING NEW;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW;    
      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
        SET
          cubic_code_end = '||city||'_ctv_topology.cubic_code,
          cubic_name_end = '||city||'_ctv_topology.cubic_name,
          cubic_coment_end = '||city||'_ctv_topology.cubic_coment,
          geom_end_point = '||city||'_ctv_topology.equipment_geom,
          geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1,'||city||'_ctv_topology.equipment_geom)

        FROM '||city||'.'||city||'_ctv_topology
        WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8)) AND '||city||'_cable_channels_coax.table_id = $1.table_id AND '||city||'_ctv_topology.cubic_name IN (''Домовой узел'', ''Магистральный узел'', ''Ответвитель магистральный'',''Порт ОК'')  ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_end_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels_coax.table_id = $1.table_id' USING NEW; 
      END IF;
      
      RETURN NEW;
      ------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_coax 
        SET  
          geom_cable =NULL,
          geom_end_point = NULL,
          geom_start_point = NULL,
          cubic_code_start = NULL,
          cubic_name_start = NULL,
          cubic_coment_start = NULL,
          cubic_code_end = NULL,
          cubic_name_end = NULL,
          cubic_coment_end = NULL,
          cubic_end_house_id = NULL,
          cubic_start_house_id = NULL,
          cubic_start_street = NULL,
          cubic_start_house_num = NULL,
          cubic_end_street = NULL,
          cubic_end_house_num = NULL
          
        WHERE '||city||'_cable_channels_coax.table_id = $1.table_id' USING OLD;
      RETURN OLD; --  стоит подтирать и адрес и геометрию  после удаления кабелей
  END IF; 
END;
   --------------
   $cable_channels_coax_data_update$ LANGUAGE plpgsql;

/*CREATE TRIGGER cable_KKE_house_id AFTER INSERT OR UPDATE OR DELETE ON fastiv.fastiv_cable_channel_coax_geom
    FOR EACH ROW EXECUTE PROCEDURE cable_KKE_house_id(); -- если сделать тригер before то нихрена не работает*/
    --[city]_cable_channel_coax_geom (0шт) --- лажа какая-то лишняя буква s - нужно поудалаять со всех таблиц и к ним даже процедуры привязаны   
    --ERROR:  column fastiv_cable_channel_coax_geom.cable_description does not exist