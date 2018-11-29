
CREATE OR REPLACE FUNCTION public.select_region() RETURNS trigger AS $select_region$ -- делаем одну функцию для всех схем
-- после реализации для всех городов нужно добаить а ночной апдейт
DECLARE 
  city name :=TG_TABLE_SCHEMA;
  BEGIN 
  IF  TG_OP = 'INSERT' THEN 
--вылез глюк: если нарисовать сразу несколько зон и сохранить то поля заполняются неправильно (все одинаково в этот момент)
  EXECUTE '-- ниже берём данные из домов
  			UPDATE '||city||'.'||city||'_select_region 
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id, count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM '||city||'.'||city||'_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where '||city||'_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where '||city||'_select_region.id=tmp.id ; -- может тут не нужен это $1 ?  =tmp.id  так нормально работает


--ниже берём данные из топологии КТВ
  			UPDATE '||city||'.'||city||'_select_region  
            SET
            sum_node=tmp.sum_node,
            sum_opt=tmp.sum_opt, 
            sum_trunk_amp=tmp.sum_trunk_amp,
            sum_house_amp=tmp.sum_house_amp

            FROM (SELECT '||city||'_select_region.id, N.sum as sum_node, O.sum as sum_opt,  T.sum as sum_trunk_amp, D.sum as sum_house_amp -- менять нужно тут и в внизу в group by
FROM '||city||'.'||city||'_select_region
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM '||city||'.'||city||'_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптический узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON '||city||'_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) N  ON '||city||'_select_region.id=N.id
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM '||city||'.'||city||'_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптичний приймач'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON '||city||'_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) O  ON '||city||'_select_region.id=O.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM '||city||'.'||city||'_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Магистральный узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   '||city||'_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) T  ON '||city||'_select_region.id=T.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM '||city||'.'||city||'_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Домовой узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   '||city||'_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) D  ON '||city||'_select_region.id=D.id
group by '||city||'_select_region.id, N.sum,O.sum , T.sum, D.sum   order by '||city||'_select_region.id desc) tmp 
             where '||city||'_select_region.id=$1.id ;

-- ниже берём данные по свичам на сети (_switches_working)
			UPDATE '||city||'.'||city||'_select_region  
            SET
            sum_agg_switches=tmp.sum_agg_switches,
            sum_acc_switches=tmp.sum_acc_switches
FROM  (SELECT '||city||'_select_region.id, A.sum as sum_agg_switches, C.sum as sum_acc_switches -- менять нужно тут и в внизу в group by
FROM '||city||'.'||city||'_select_region
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM '||city||'.'||city||'_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''agr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   '||city||'_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) A  ON '||city||'_select_region.id=A.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM '||city||'.'||city||'_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''acc'',''sbagr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   '||city||'_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) C  ON '||city||'_select_region.id=C.id
group by '||city||'_select_region.id, A.sum, C.sum  order by '||city||'_select_region.id desc) tmp 
             where '||city||'_select_region.id=$1.id ;
              ' USING NEW; -- пока чистый INSERT - работает нормально что делать с UPDATE непонятно. 

	RETURN NEW;
  END IF; 
  IF  TG_OP =  'UPDATE' THEN 
  		IF   ST_Equals(NEW.geom , OLD.geom)=TRUE  THEN EXECUTE '' USING NEW; RETURN NEW;
  	ELSIF   ST_Equals(NEW.geom , OLD.geom)=FALSE  THEN  -- сюда нужно отдельно добавить всё с  тригера обновления домов
    --- данные из домов -- не обновляються ------coalesce ничего не дал --не обновляеться елси результат NULL
    -- пришлось добавить вручную обнуления
    
     	EXECUTE '
      UPDATE '||city||'.'||city||'_select_region  
            SET

            sum_hp = NULL,
            sum_ktv= NULL,
            sum_atv= NULL,
            sum_eth= NULL,
            sum_docsis= NULL,
            sum_active_contr= NULL,
            sum_houses= NULL;

     		UPDATE '||city||'.'||city||'_select_region  
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            
            FROM (SELECT agg.id,count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM '||city||'.'||city||'_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where '||city||'_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where '||city||'_select_region.id=tmp.id;

        --- данные из тпологии КТВ -- заполняються нормально
     	UPDATE '||city||'.'||city||'_select_region  
            SET
            sum_node=tmp.sum_node,
            sum_opt=tmp.sum_opt,
            sum_trunk_amp=tmp.sum_trunk_amp,
            sum_house_amp=tmp.sum_house_amp

            FROM (SELECT '||city||'_select_region.id, N.sum as sum_node, O.sum as sum_opt,  T.sum as sum_trunk_amp, D.sum as sum_house_amp -- менять нужно тут и в внизу в group by
FROM '||city||'.'||city||'_select_region
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM '||city||'.'||city||'_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптический узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON '||city||'_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) N  ON '||city||'_select_region.id=N.id
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM '||city||'.'||city||'_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптичний приймач'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON '||city||'_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) O  ON '||city||'_select_region.id=O.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM '||city||'.'||city||'_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Магистральный узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   '||city||'_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) T  ON '||city||'_select_region.id=T.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM '||city||'.'||city||'_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Домовой узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   '||city||'_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) D  ON '||city||'_select_region.id=D.id
group by '||city||'_select_region.id, N.sum,O.sum , T.sum, D.sum   order by '||city||'_select_region.id desc) tmp 
             where '||city||'_select_region.id=tmp.id; 

 -- ниже берём данные по свичам на сети (_switches_working) -- заполняються нормально
			UPDATE '||city||'.'||city||'_select_region  
            SET
            sum_agg_switches=tmp.sum_agg_switches,
            sum_acc_switches=tmp.sum_acc_switches
FROM  (SELECT '||city||'_select_region.id, A.sum as sum_agg_switches, C.sum as sum_acc_switches -- менять нужно тут и в внизу в group by
FROM '||city||'.'||city||'_select_region
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM '||city||'.'||city||'_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''agr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   '||city||'_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) A  ON '||city||'_select_region.id=A.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM '||city||'.'||city||'_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from '||city||'.'||city||'_select_region R,  '||city||'.'||city||'_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''acc'',''sbagr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   '||city||'_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) C  ON '||city||'_select_region.id=C.id
group by '||city||'_select_region.id, A.sum, C.sum  order by '||city||'_select_region.id desc) tmp 
             where '||city||'_select_region.id=tmp.id ;' USING NEW; -- только в таком варианте работает
		RETURN NEW;
		END IF; 
  END IF; 
  IF TG_OP = 'DELETE' THEN  EXECUTE '' USING OLD;
    RETURN OLD;
  END IF; 
END;
-----------------
  $select_region$ LANGUAGE plpgsql; 