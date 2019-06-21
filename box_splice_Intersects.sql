CREATE OR REPLACE FUNCTION public.box_splice_Intersects() RETURNS trigger AS $box_splice_Intersects$ 
DECLARE 
--тригер на таблицы _box_splice
  city name :=TG_TABLE_SCHEMA;

  
  tbl_UPD text;
  tbl_distr text;
  tbl_build text;
  tbl_entr text;

  BEGIN 
  
  tbl_UPD:= city||'.'||city||'_box_splice';
  tbl_distr:= city||'.'||city||'_microdistricts';
  tbl_build:= city||'.'||city||'_buildings_new_view';
  tbl_entr:= city||'.'||city||'_entrances';
  --такие имена работают нормально '||tbl_build||'

  IF  TG_OP = 'INSERT' THEN  

                EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              micro_district = '||tbl_distr||'.micro_district,
              coverage_zone = '||tbl_distr||'.district
              FROM '||tbl_distr||'
              WHERE  ST_Intersects('||tbl_distr||'.coverage_geom,$1.geom) AND '||tbl_UPD||'.id=$1.id;'   USING NEW;  
              /* без вот этого хитрого '||tbl_UPD||'.id=$1.id оно будет всю таблицу перписыывать!!! */   

             EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              adress = Concat(COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),'' '',COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num))
              
              FROM '||tbl_build||'
              WHERE  ST_Intersects('||tbl_build||'.building_geom,$1.geom) AND '||tbl_UPD||'.id=$1.id ;'      USING NEW; 


               EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              entrance = '||tbl_entr||'.openstreet_entrance_ref
              FROM '||tbl_entr||'
              WHERE  ST_Distance('||tbl_entr||'.geom,$1.geom)<8 AND '||tbl_UPD||'.id=$1.id;'   USING NEW;

              /* без вот этого хитрого '||tbl_UPD||'.id=$1.id оно будет всю таблицу перписыывать!!! */   
              RETURN NEW;    /*  эту часть протестил. всё ок.    */
       
------------------
      /* без вот этого хитрого  IF ST_Equals(NEW.geom , OLD.geom)=FALSE AND NEW.id=OLD.id THEN  а потом '||tbl_UPD||'.id=$1.id оно будет всю таблицу перписыывать!!! */ 
      /*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! это отличное решение нужно на все тупые триггеры записать !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

    ELSIF TG_OP = 'UPDATE' THEN 
              IF ST_Equals(NEW.geom , OLD.geom)=FALSE AND NEW.id=OLD.id THEN

        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              micro_district = '||tbl_distr||'.micro_district,
              coverage_zone = '||tbl_distr||'.district
              FROM '||tbl_distr||'
              WHERE  ST_Intersects('||tbl_distr||'.coverage_geom,$1.geom) AND '||tbl_UPD||'.id=$1.id;'   USING NEW;  
              /* в  блоке UPDATE всё-равно всю таблицу перписывает!!! чё делать? */  
        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              adress = Concat(COALESCE('||tbl_build||'.cubic_street,'||tbl_build||'.osm_street),'' '',COALESCE('||tbl_build||'.cubic_house, '||tbl_build||'.osm_house_num))
              
              FROM '||tbl_build||'
              WHERE  ST_Intersects('||tbl_build||'.building_geom,$1.geom) AND '||tbl_UPD||'.id=$1.id ;'      USING NEW; 


        EXECUTE 'UPDATE '||tbl_UPD||'
            SET
              entrance = '||tbl_entr||'.openstreet_entrance_ref
              FROM '||tbl_entr||'
              WHERE  ST_Distance('||tbl_entr||'.geom,$1.geom)<8 AND '||tbl_UPD||'.id=$1.id;'   USING NEW;

              END IF; 

            RETURN NEW; /*  эту часть протестил. всё ок.    */
       
      ------------------------------- 
    ELSIF TG_OP = 'DELETE' THEN 
          EXECUTE '' USING OLD;
      RETURN OLD; -- 
  END IF; 
END;
$box_splice_Intersects$ LANGUAGE plpgsql;