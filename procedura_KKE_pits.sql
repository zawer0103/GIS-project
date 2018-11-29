CREATE OR REPLACE FUNCTION public.cable_KKE_pits() RETURNS trigger AS $cable_KKE_pits$

DECLARE 
  city name :=TG_TABLE_SCHEMA;

BEGIN 
  IF  TG_OP = 'INSERT' THEN 
  
       --  привязка к колодцам улиц и микрорайонов
       -- pit_district - єто адрес ПГС берём из таблиц  _coverage поле notes (почему-то не во во всех городах оно заполнено)
       --поле microdistrict берём из таблиц _microdistricts
       --поле district берём из таблиц _microdistricts
       --улицы записываем только если поле пустое, т.к. многие нужно исправлять вручную
       --нужно добавить set archive_link = 'https://".$server_address."/qgis-ck/tmp/archive/".$selectedCity."/topology/pits/'||pit_id||'/';";

       -- !!!! на фастове всё работает замечательно. КИЕВ - завис намертво при попытке вставить колодец!!!
       -- !!! очень медленно работают все геометрические функции типа ST_
        /*EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              district = '||city||'_microdistricts.district,  
              microdistrict = '||city||'_microdistricts.micro_district
            FROM '||city||'.'||city||'_microdistricts
            WHERE   ST_DWithin('||city||'_microdistricts.coverage_geom, $1.geom, 0) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; --  ST_DWithin сохраняет 15 секунд -- добавил индекс для microdistricts.coverage_geom стало 10 секунд*/
          
           /* EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              district = '||city||'_microdistricts.district,  
              microdistrict = '||city||'_microdistricts.micro_district
            FROM '||city||'.'||city||'_microdistricts
            WHERE   ST_Contains('||city||'_microdistricts.coverage_geom, $1.geom ) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; -- только такой вариант  работает правильно*/
            -- ST_Contains  сохраняет 10 секунд -- ничё не изменилось  --- Getting intersections the faster way https://postgis.net/2014/03/14/tip_intersection_faster/ 
  /*    EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
         SET
              district = '||city||'_microdistricts.district,  
              microdistrict = '||city||'_microdistricts.micro_district
          FROM '||city||'.'||city||'_microdistricts
          WHERE   ST_Intersects('||city||'_microdistricts.coverage_geom, $1.geom ) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; ---- сохраняет 8 сек в киеве
      */
/* это тоже придётся отключить т.к. в киеве всё долго
   EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
         SET
              district = '||city||'_microdistricts.district,  
              microdistrict = '||city||'_microdistricts.micro_district
          FROM '||city||'.'||city||'_microdistricts
          WHERE   ST_Intersects('||city||'_microdistricts.coverage_geom, $1.geom ) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; ---
*/
    -- есть ещё предложение ST_CoveredBy -- эта функция вообще ничего не находит  https://postgis.net/2014/03/14/tip_intersection_faster/
 --!!!!!!!! кстати надо попробовать WHEN  вместо WHERE как в этой ссылке

    -- тоже самое делает ST_Intersection  - возращат геометрию (если нет персечения - то пустую), поэтому нужно ST_IsEmpty -- сохраняет 9 сек в киеве. WHERE   Not ST_IsEmpty(ST_Intersection('||city||'_microdistricts.coverage_geom, $1.geom )) 
           
          /*
            EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              pit_district = '||city||'_coverage.notes  
            FROM '||city||'.'||city||'_coverage
            WHERE   ST_Contains('||city||'_coverage.geom_area, $1.geom ) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; -- ок
          */
/*
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              pit_district = '||city||'_coverage.notes  
            FROM '||city||'.'||city||'_coverage
            WHERE   ST_Intersects( '||city||'_coverage.geom_area, $1.geom  ) AND '||city||'_cable_channel_pits.id = $1.id' USING NEW; -- в сумме с предыдущим запросом  ST_Intersects сохраняет 15 сек в киеве. причём если в персечении ничего нет  - то делает гораздо быстрее...  
*/
/*
---- печалько. в процедуры  пихать заполнение полей колодцев нельзя т.к. все геометриеские операции типа ST_   на большом кол-ве обектов выполняються ОЧЕНь медленно.
-- нужно опять пихать в ночной update, только НУЖНО провертиь чтоб он не обнвлял номера колодцев и геометрию  - иначе он запустит процедуру UPDATE и начнёт обновлять все кабельные каналы и зависнет...
*/
/*
  EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              street = '||city||'_roads.name                       
            FROM '||city||'.'||city||'_roads
            WHERE    ST_Intersects('||city||'_roads.geom,ST_Buffer($1.geom, 60,2)) AND '||city||'_cable_channel_pits.id = $1.id '  USING NEW;-- вместе с предыдущими запросами сохраняет 40 сек.
*/
/*
             EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              street = '||city||'_roads.name                       
            FROM '||city||'.'||city||'_roads
            WHERE   ST_Distance('||city||'_roads.geom, $1.geom) <= 30 AND '||city||'_cable_channel_pits.id = $1.id AND '||city||'_cable_channel_pits.street is NULL'  USING NEW;


            EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              street = '||city||'_buildings.cubic_street                       
            FROM '||city||'.'||city||'_buildings
            WHERE   ST_Distance('||city||'_buildings.building_geom, $1.geom) <=50 AND '||city||'_cable_channel_pits.id = $1.id AND '||city||'_cable_channel_pits.street is NULL'  USING NEW;

            EXECUTE 'UPDATE '||city||'.'||city||'_cable_channel_pits
            SET
              street = '||city||'_roads.name        
            FROM '||city||'.'||city||'_roads
            WHERE   ST_DWithin('||city||'_roads.geom, $1.geom , 100) AND '||city||'_cable_channel_pits.id = $1.id AND '||city||'_cable_channel_pits.street is NULL'  USING NEW;

*/ --закомитчу улицы может будте быстрее --всё равно тупит, но уже работае гораздо быстрее что делать?! ST_Contains ТУПИТ?
   
          RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN 
     --тут скрипт перепривязываем кабельные каналы к своим колодцам (как в cubic-auto-update строка 303) 
     --  подозреваю что именно это стало конфликтовать с ночным cubic-auto_update.php (строка 249)- обновляет все колодцы. и это вызывает процеру 
             IF (ST_Equals(NEW.geom , OLD.geom)=TRUE AND (NEW.pit_number!=OLD.pit_number OR NEW.pit_number IS NULL OR OLD.pit_number IS NULL)) THEN    
             -- добавил проверку по номеру колодца. больше то ничего мы и не меняем. -- так стало быстрее.
             ----добавил проверку  IF NULL
             EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    pit_1= '||city||'_cable_channel_pits.pit_number

                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  '||city||'_cable_channel_pits.pit_id = '||city||'_cable_channels_channels.pit_id_1 ;
                  UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    pit_2= '||city||'_cable_channel_pits.pit_number

                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  '||city||'_cable_channel_pits.pit_id = '||city||'_cable_channels_channels.pit_id_2' USING NEW; RETURN NEW;  --

            ELSIF   (ST_Equals(NEW.geom , OLD.geom)=TRUE AND NEW.pit_number=OLD.pit_number) THEN EXECUTE '' USING NEW; RETURN NEW;

             ELSIF   ST_Equals(NEW.geom , OLD.geom)=FALSE  THEN                                  

              EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                   
                    pit_1_geom = '||city||'_cable_channel_pits.geom
                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  '||city||'_cable_channel_pits.pit_id = '||city||'_cable_channels_channels.pit_id_1;

                  UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                 
                    pit_2_geom = '||city||'_cable_channel_pits.geom
                  FROM '||city||'.'||city||'_cable_channel_pits
                  WHERE  '||city||'_cable_channel_pits.pit_id = '||city||'_cable_channels_channels.pit_id_2 ' USING NEW; -- любые другие комбинации дают неожиданный результат - привязывает куда попало


                  EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels_channels
                  SET
                    channel_geom = ST_MakeLine(pit_1_geom, pit_2_geom),
                    map_distance = round( CAST(st_distance(pit_1_geom, pit_2_geom) as numeric),2),                  
                     temp_1=now() '  USING NEW; -- рисуем линию заново с привязкой к колодцам-- что-то непонято без WHERE  '||city||'_cable_channels_channels.id = $1.id  оно обновляет всю таблицу или только там где были изменения ?-- надо тестить на киеве -- протестил перезаписывает всё . сегодня не шустро. уже 60 сек/ что произошло? -- после обеда опять шустренько
/*      есть колонка "temp_1"  при изменении можно пихать туда temp_1=now()  - да убеждаемся что перезаписывает всё --какое добавить WHERE или ещё что-то чтобы обновляло только то что измнилось??!   */
# непонятно что случилось но в киеве теперь это зависает на  час. раньше было 15сек. вручную перстроил индексацию - всё полетело. что за чертовщина
            RETURN NEW; END IF;
    
    
    ELSIF TG_OP = 'DELETE' THEN 
    EXECUTE '' USING OLD;
    RETURN OLD;
  END IF; 
END;---
   --------------
  $cable_KKE_pits$ LANGUAGE plpgsql;

/*CREATE TRIGGER cable_KKE_pits AFTER INSERT OR UPDATE OR DELETE ON kiev.kiev_cable_channel_pits
    FOR EACH ROW EXECUTE PROCEDURE cable_KKE_pits(); -- если сделать тригер before то нихрена не работает*/