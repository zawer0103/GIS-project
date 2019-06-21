--CREATE TRIGGER cable_air_data_update_box_splice AFTER UPDATE or INSERT or DELETE ON ".$selectedCity.".".$selectedCity."_cable_air_cable_geom  FOR EACH ROW EXECUTE PROCEDURE  public.cable_air_data_update(); -- верменно отключаю триггеры cable_air_data_update   cable_air_data_update_box  
--попробовал на  черкасах

CREATE OR REPLACE FUNCTION public.cable_air_data_update() RETURNS trigger AS $cable_air_data_update$ 
DECLARE 
--тригер на таблицы _cable_air_cable_geom
-- использую для замены оригинальной функции public.cable_air_data_update()
-- триггер тот же что и был  cable_air_data_update

  city name :=TG_TABLE_SCHEMA;

  tbl_geom text;
  tbl_UPD text;
  tbl_ctv text;
  tbl_build text;
  tbl_entr text;
  tbl_box text;

  geom_start_point_state boolean;
  geom_end_point_state boolean;
  geom_start_point_state_house boolean;
  geom_end_point_state_house boolean;

  BEGIN 
  tbl_geom := city||'.'||city||'_cable_air_cable_geom';
  tbl_UPD := city||'.'||city||'_cable_air';
  tbl_ctv:=  city||'.'||city||'_ctv_topology';
  tbl_build:= city||'.'||city||'_buildings_new_view';
  tbl_entr:= city||'.'||city||'_entrances';
  tbl_box:= city||'.'||city||'_box_splice';
  --такие имена работают нормально

  IF  TG_OP = 'INSERT' THEN  
-----ниже моя вставка для упрощённого подхода к рисованию(можно вносить кол-во волокон и/или длина и/или тип кабеля/добавить)
-- если мы пытаемя обновить поля в слое "для рисования" система не даёт их перезаписать и в слоях кабели_ВКП_для_рисования и в кабели_ВКП будут разные данные - это будет вносить сумятицу: в связи с чем есть идея: затирать данные в таблице кабели_ВКП_для_рисования (добавил ниже)
--все таблицы типа _cable_air_cable_geom  поле cable_description и заменить в скриптах ниже cable_description  на cable_description !(сделано)
-- нужно ещё будет подумать об исключениях RAISE EXCEPTION https://stackoverflow.com/questions/42890652/update-a-column-in-a-function-using-plpgsql
-- добавить во все таблицы _cable_air   в поле cable_type значение по умолчанию 'optic' !!!

--мне этот подход на проверку cable_short_type_description is NULL   уже не нравиться: если кабель удалили а потом нарисовали то будут неверные длины, типы и т.п. удаляю это при инсертах

            EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cable_short_type_description = $1.cable_short_type_description,
              cable_description = $1.cable_description,
              total_cable_length=$1.total_cable_length
              WHERE  '||tbl_UPD||'.table_id = $1.table_id ;
              '         USING NEW;

         EXECUTE 'UPDATE '||tbl_geom||'
            SET
              cable_short_type_description = NULL,
              cable_description = NULL,
              total_cable_length = NULL
                        
            WHERE  '||tbl_geom||'.cable_short_type_description is NOT NULL OR '||tbl_geom||'.cable_description is NOT NULL OR '||tbl_geom||'.total_cable_length is NOT NULL' USING NEW; /* затираем данные после сохранения вроде работает норм*/

----------------
---------ниже  вставка  привязки домов к концам кабеля  (подъезды обновляем отдельно)----------------
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_start_point_state_house USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_start_house_id = '||tbl_build||'.cubic_house_id,
                    cubic_start_street = COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),
                    cubic_start_house_num =  COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num)
                  
                  FROM '||tbl_build||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom) , '||tbl_build||'.building_geom) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW; -- почему тут ST_Distance а не intersect ?

            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_end_house_id = '||tbl_build||'.cubic_house_id,
                    cubic_end_street = COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),
                    cubic_end_house_num = COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num)
                  
                  FROM '||tbl_build||'
                  WHERE  (ST_Distance(ST_EndPoint($1.geom) , '||tbl_build||'.building_geom ) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;

            END IF;
--------------------------ниже добавляем обновляем подъезды к концам кабеля --------
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_start_point_state_house USING NEW;
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_start_house_entrance_num = COALESCE('||tbl_entr||'.cubic_entrance_number,'||tbl_entr||'.openstreet_entrance_ref)
                  FROM '||tbl_entr||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom) , '||tbl_entr||'.geom) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
             
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_end_house_entrance_num = COALESCE('||tbl_entr||'.cubic_entrance_number,'||tbl_entr||'.openstreet_entrance_ref)
                  FROM '||tbl_entr||'
                  WHERE  (ST_Distance(ST_EndPoint($1.geom) , '||tbl_entr||'.geom ) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;
                             
            END IF;
-------------------------вот тут устанавливается геометрию с учётом привязки к equipment_geom (к ЛОУ)---думаю отключить сделать geom_cable=geom_cable

      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_ctv||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4 AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_start_point_state USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_ctv||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4 AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_end_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = '||tbl_ctv||'.cubic_code,
              cubic_name_start = '||tbl_ctv||'.cubic_name,
              cubic_coment_start = '||tbl_ctv||'.cubic_coment,
              geom_start_point = '||tbl_ctv||'.equipment_geom,
              --geom_cable = ST_SetPoint($1.geom,0 , '||tbl_ctv||'.equipment_geom)
              geom_cable = $1.geom
            FROM '||tbl_ctv||'
            WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom) , '||tbl_ctv||'.equipment_geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' USING NEW;
      ELSE
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;
            
            UPDATE '||tbl_UPD||'  
            SET
             cubic_code_start = '||tbl_box||'.mid,
              cubic_name_start = '||tbl_box||'.type,
              cubic_coment_start = '||tbl_box||'.location,
              geom_start_point = '||tbl_box||'.geom,
              geom_cable = $1.geom
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom) , '||tbl_box||'.geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id 
            ' USING NEW; --mid - это начало вставки данных из таблицы боксов   

      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||tbl_UPD||'
        SET
          cubic_code_end = '||tbl_ctv||'.cubic_code,
          cubic_name_end = '||tbl_ctv||'.cubic_name,
          cubic_coment_end = '||tbl_ctv||'.cubic_coment,
          geom_end_point = '||tbl_ctv||'.equipment_geom,
          --geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1 , '||tbl_ctv||'.equipment_geom)
          geom_cable = $1.geom
        FROM '||tbl_ctv||'
        WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')  ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_end_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;

             UPDATE '||tbl_UPD||'
            SET
             cubic_code_end = '||tbl_box||'.mid,
              cubic_name_end = '||tbl_box||'.type,
              cubic_coment_end = '||tbl_box||'.location,
              geom_end_point = '||tbl_box||'.geom,
              geom_cable = $1.geom
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) , '||tbl_box||'.geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id 

            ' USING NEW; --mid - это начало вставки данных из таблицы боксов 
            ----------  
      END IF;
      
      RETURN NEW;

------------------
      
    ELSIF TG_OP = 'UPDATE' THEN 
-----ниже  вставка --это новый упрощённый подход к рисованию кабелей
-- тут есть некий дисонанс: если мы пытаемя обновить поля в слое "для рисования" система не даёт их перезаписать и в слоях кабели_ВКП_для_рисования и в кабели_ВКП будут разные данные - это будет вносить сумятицу: в связи с чем есть идея: затирать данные в таблице кабели_ВКП_для_рисования (скрипт добавли ниже)
          EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cable_short_type_description = $1.cable_short_type_description
           WHERE  '||tbl_UPD||'.table_id = $1.table_id and '||tbl_UPD||'.cable_short_type_description is NULL;

            UPDATE '||tbl_UPD||'
            SET
              cable_description = $1.cable_description
           WHERE  '||tbl_UPD||'.table_id = $1.table_id and '||tbl_UPD||'.cable_description is NULL;

            UPDATE '||tbl_UPD||'
            SET
              total_cable_length=$1.total_cable_length
            WHERE  '||tbl_UPD||'.table_id = $1.table_id and '||tbl_UPD||'.total_cable_length is NULL;   ' USING NEW;
            
            EXECUTE 'UPDATE '||tbl_geom||'
            SET
              cable_short_type_description = NULL,
              cable_description = NULL,
              total_cable_length = NULL
                        
            WHERE  '||tbl_geom||'.cable_short_type_description is NOT NULL OR '||tbl_geom||'.cable_description is NOT NULL OR '||tbl_geom||'.total_cable_length is NOT NULL' USING NEW; /*  затераем данные в cable_air_cable_geom после сохранения вроде работает норм*/
       
------------------------------
---------ниже  вставка  привязки домов к концам кабеля  (подъезды обновляем отдельно)---------------
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_start_point_state_house USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_start_house_id = '||tbl_build||'.cubic_house_id,
                    cubic_start_street = COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),
                    cubic_start_house_num =  COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num)
                  
                  FROM '||tbl_build||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom) , '||tbl_build||'.building_geom) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
            ELSE
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_start_house_id = NULL,
                    cubic_start_street = NULL,
                    cubic_start_house_num = NULL
                                
                  WHERE  '||tbl_UPD||'.table_id = $1.table_id' USING NEW;    
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_end_house_id = '||tbl_build||'.cubic_house_id,
                    cubic_end_street = COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),
                    cubic_end_house_num = COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num)
                  
                  FROM '||tbl_build||'
                  WHERE  (ST_Distance(ST_EndPoint($1.geom) , '||tbl_build||'.building_geom ) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;
            ELSE
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_end_house_id = NULL,
                    cubic_end_street = NULL,
                    cubic_end_house_num = NULL
                                
                  WHERE  '||tbl_UPD||'.table_id = $1.table_id' USING NEW;    
            END IF;
--------добавляем обновление полей подъездов к концам кабеля -------
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_start_point_state_house USING NEW;
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_start_house_entrance_num = COALESCE('||tbl_entr||'.cubic_entrance_number,'||tbl_entr||'.openstreet_entrance_ref)
                  FROM '||tbl_entr||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom) , '||tbl_entr||'.geom) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
                  ELSE 
                EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_start_house_entrance_num = NULL
                  
                  WHERE   ('||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
            END IF;
            IF geom_end_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_end_house_entrance_num = COALESCE('||tbl_entr||'.cubic_entrance_number,'||tbl_entr||'.openstreet_entrance_ref)
                  FROM '||tbl_entr||'
                  WHERE  (ST_Distance(ST_EndPoint($1.geom) , '||tbl_entr||'.geom ) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;
                   ELSE 
                EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_end_house_entrance_num = NULL
                  
                  WHERE   '||tbl_UPD||'.table_id = $1.table_id ' USING NEW;          
            END IF;
-------------------------------------------------------------------------
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_ctv||' WHERE ST_Distance(ST_StartPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4 AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')' INTO geom_start_point_state USING NEW;
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_ctv||' WHERE ST_Distance(ST_EndPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4 AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')' INTO geom_end_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = '||tbl_ctv||'.cubic_code,
              cubic_name_start = '||tbl_ctv||'.cubic_name,
              cubic_coment_start = '||tbl_ctv||'.cubic_coment,
              geom_start_point = '||tbl_ctv||'.equipment_geom,
              --geom_cable = ST_SetPoint($1.geom,0 , '||tbl_ctv||'.equipment_geom)
              geom_cable = $1.geom
            FROM '||tbl_ctv||'
            WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom) , '||tbl_ctv||'.equipment_geom) <= 1.4))   AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')  ' USING NEW; 
      ELSE
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;
            
            UPDATE '||tbl_UPD||'  
            SET
             cubic_code_start = '||tbl_box||'.mid,
              cubic_name_start = '||tbl_box||'.type,
              cubic_coment_start = '||tbl_box||'.location,
              geom_start_point = '||tbl_box||'.geom,
              geom_cable = $1.geom
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom) , '||tbl_box||'.geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id 
            ' USING NEW; --mid - это начало вставки данных из таблицы боксов -- привязка вроде как работает норм. теперь нужно добавить триггер (типа  ctv_move_cable_geom ()) на таблицу ящиков: передвижение ящиков вызыввает перерисовку привязаного кабеля   
      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||tbl_UPD||'
        SET
          cubic_code_end = '||tbl_ctv||'.cubic_code,
          cubic_name_end = '||tbl_ctv||'.cubic_name,
          cubic_coment_end = '||tbl_ctv||'.cubic_coment,
          geom_end_point = '||tbl_ctv||'.equipment_geom,
          --geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1 , '||tbl_ctv||'.equipment_geom)
          geom_cable = $1.geom
        FROM '||tbl_ctv||'
        WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom)  , '||tbl_ctv||'.equipment_geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')  ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_end_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;
            
            UPDATE '||tbl_UPD||'  
            SET
             cubic_code_end = '||tbl_box||'.mid,
              cubic_name_end = '||tbl_box||'.type,
              cubic_coment_end = '||tbl_box||'.location,
              geom_end_point = '||tbl_box||'.geom,
              geom_cable = $1.geom
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) , '||tbl_box||'.geom) <= 1.4)) AND '||tbl_UPD||'.table_id = $1.table_id 
            ' USING NEW; --mid - это начало вставки данных из таблицы боксов  
      END IF;
      
      RETURN NEW;
      ------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE 'UPDATE '||tbl_UPD||' 
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
          cubic_start_house_entrance_num = NULL,
          cubic_end_house_entrance_num = NULL,
          cubic_end_house_num = NULL

        WHERE '||tbl_UPD||'.table_id = $1.table_id' USING OLD;
      RETURN OLD; -- 
  END IF; 
END;
$cable_air_data_update$ LANGUAGE plpgsql;