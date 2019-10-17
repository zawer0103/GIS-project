CREATE OR REPLACE FUNCTION public.cable_air_data_update_new() RETURNS trigger AS $cable_air_data_update_new$ 

-- триггер нужно поставить только на GEOM  
-- триггер на таблицы [city]_cable_air

DECLARE 
  
  tbl_UPD text;
  tbl_ctv text;
  tbl_build text;
  tbl_entr text;
  tbl_box text;

  city name :=TG_TABLE_SCHEMA;
  geom_start_point_state boolean;
  geom_end_point_state boolean;
  geom_start_point_state_house boolean;
  geom_end_point_state_house boolean;
  BEGIN 

  tbl_UPD := city||'.'||city||'_cable_air';
  tbl_ctv:=  city||'.'||city||'_ctv_topology';
  tbl_build:= city||'.'||city||'_buildings_new_view';
  tbl_entr:= city||'.'||city||'_entrances';
  tbl_box:= city||'.'||city||'_box_splice';

  IF  TG_OP = 'INSERT' THEN NULL ;
  --у нас вообще нет INSERT и DELETE в эти таблицы. она сразу заполнена t_00001 ... t_02000 NULL
         
  ----------------------------------------------
    ELSIF TG_OP = 'UPDATE' THEN 
-- основные данные вставляються во вьюшке а тут мы будем только привызявать к домам, подъздам  боксам и ЛОУ
--тут везде по тексту в таблицах кабелей поле называеться geom_cable---
---------привязка домов к концам кабеля  (подъезды обновляем отдельно) ------

     IF NEW.geom_cable IS NOT NULL THEN  
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_StartPoint($1.geom_cable) , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_start_point_state_house USING NEW;
      EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_build||' WHERE ST_Distance(ST_EndPoint($1.geom_cable) , '||tbl_build||'.building_geom) <= 4.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_start_house_id = '||tbl_build||'.cubic_house_id,
                    cubic_start_street = COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),
                    cubic_start_house_num = COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num)
                  
                  FROM '||tbl_build||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom_cable),'||tbl_build||'.building_geom) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
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
                  WHERE  (ST_Distance(ST_EndPoint($1.geom_cable),'||tbl_build||'.building_geom ) <= 4.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;
            ELSE
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                    cubic_end_house_id = NULL,
                    cubic_end_street = NULL,
                    cubic_end_house_num = NULL
                                
                  WHERE  '||tbl_UPD||'.table_id = $1.table_id' USING NEW;    
            END IF;
        END IF;
         -- 
--------привязка подъездов к концам кабеля -------
             EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_StartPoint($1.geom_cable)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_start_point_state_house USING NEW;
            EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||tbl_entr||' WHERE ST_Distance(ST_EndPoint($1.geom_cable)  , '||tbl_entr||'.geom) <= 6.1 ' INTO geom_end_point_state_house USING NEW;
            IF geom_start_point_state_house = TRUE THEN
              EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_start_house_entrance_num = COALESCE('||tbl_entr||'.cubic_entrance_number,'||tbl_entr||'.openstreet_entrance_ref)
                  FROM '||tbl_entr||'
                  WHERE  (ST_Distance(ST_StartPoint($1.geom_cable) , '||tbl_entr||'.geom) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id) ' USING NEW;
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
                  WHERE  (ST_Distance(ST_EndPoint($1.geom_cable) , '||tbl_entr||'.geom ) <= 6.1 AND '||tbl_UPD||'.table_id = $1.table_id)  ' USING NEW , city;
                   ELSE 
                EXECUTE 'UPDATE '||tbl_UPD||'
                  SET
                  cubic_end_house_entrance_num = NULL
                  
                  WHERE   '||tbl_UPD||'.table_id = $1.table_id ' USING NEW;          
            END IF; -- ок
------------Привязка к ручным боксам и ЛОУ/ОП  должно быть одинаково  с функцией для ВКП----------------
--вот эта часть конфликтовала всё затирает NULL при изменении геометрии
-- добавил дополнительно  IF NEW.geom_cable IS NOT NULL THEN  - и это помогло 
   IF NEW.geom_cable IS NOT NULL THEN  
    EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom_cable)
              
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;
            
            UPDATE '||tbl_UPD||'
            SET
              cubic_code_start = '||tbl_ctv||'.cubic_code,
              cubic_name_start = '||tbl_ctv||'.cubic_name,
              cubic_coment_start = '||tbl_ctv||'.cubic_coment,
              geom_start_point = '||tbl_ctv||'.equipment_geom
            FROM '||tbl_ctv||'
            WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom , ST_StartPoint($1.geom_cable)) OR (ST_Distance(ST_StartPoint($1.geom_cable) , '||tbl_ctv||'.equipment_geom) <= 2.44)) AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN ( ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'');
            
            UPDATE '||tbl_UPD||'  
            SET
             cubic_code_start = '||tbl_box||'.mid,
              cubic_name_start = '||tbl_box||'.type,
              cubic_coment_start = '||tbl_box||'.location,
              geom_start_point = '||tbl_box||'.geom
             
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_StartPoint($1.geom_cable)) OR (ST_Distance(ST_StartPoint($1.geom_cable) , '||tbl_box||'.geom) <= 2.44)) AND '||tbl_UPD||'.table_id = $1.table_id 
             ' USING NEW; -- mid - это привязка к ручным боксам/муфтам
      
            EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_end_point = ST_EndPoint($1.geom_cable)
              
              WHERE  '||tbl_UPD||'.table_id = $1.table_id;

              UPDATE '||tbl_UPD||'
            SET
              cubic_code_end = '||tbl_ctv||'.cubic_code,
              cubic_name_end = '||tbl_ctv||'.cubic_name,
              cubic_coment_end = '||tbl_ctv||'.cubic_coment,
              geom_end_point = '||tbl_ctv||'.equipment_geom
              
            FROM '||tbl_ctv||'
            WHERE  (ST_Equals ('||tbl_ctv||'.equipment_geom ,ST_EndPoint($1.geom_cable)) OR (ST_Distance(ST_EndPoint($1.geom_cable)  , '||tbl_ctv||'.equipment_geom) <= 2.44)) AND '||tbl_UPD||'.table_id = $1.table_id AND '||tbl_ctv||'.cubic_name IN ( ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ;

             UPDATE '||tbl_UPD||'
            SET
             cubic_code_end = '||tbl_box||'.mid,
              cubic_name_end = '||tbl_box||'.type,
              cubic_coment_end = '||tbl_box||'.location,
              geom_end_point = '||tbl_box||'.geom
              
            FROM '||tbl_box||'
            WHERE  (ST_Equals ('||tbl_box||'.geom , ST_EndPoint($1.geom_cable)) OR (ST_Distance(ST_EndPoint($1.geom_cable) , '||tbl_box||'.geom) <= 2.44)) AND '||tbl_UPD||'.table_id = $1.table_id;
            
            ' USING NEW; 
        END IF;
            -- всё ок
        /*  !!! тут  мы определили уже конечную и начальную точку geom_end_point и geom_start_point
         ниже скрипт для перерисовки линий кабеля который привязываеться к боксу/ЛОУ но! запускает бесконечныйй цикл
                      EXECUTE ' UPDATE '||tbl_UPD||'
                  SET  geom_cable=ST_SetPoint(geom_cable,0,geom_start_point)   WHERE  '||tbl_UPD||'.table_id = $1.table_id ;  
                  UPDATE '||tbl_UPD||' 
                    SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,geom_end_point)   WHERE   '||tbl_UPD||'.table_id = $1.table_id ; '
        USING NEW; -- это работало только когда триггер был на таблицах geom// 
        -- вот этот кусочек скрипта переношу во вьюшку иначе бесконечный цикл
        -- проверил на вьюхе.  ок. 
        --если перенести во вьюшку ВСЁ не получиться, то что делать с теми, кто захочет пользоваться таблицей?
        -- поэтому будет два триггера/две функции - для тех кто захочет пользоваться таблицей
        */        
     
      RETURN NEW;   
        
----------------------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE NULL USING OLD;
      RETURN OLD; --  --у нас вообще нет INSERT и DELETE в эти таблицы. она сразу заполнена t_00001 ... t_02000 NULL
  END IF; 
END;
$cable_air_data_update_new$ LANGUAGE plpgsql;
