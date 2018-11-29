

DROP table kiev.select_region;
DROP SEQUENCE kiev.select_region;
Create table  kiev.select_region   (id serial PRIMARY KEY,  sum_hp integer, sum_ktv integer, sum_atv integer, sum_eth integer,sum_docsis integer, sum_active_contr integer, geom geometry);  -- при создании таблиц нужно писать именно так ****id serial PRIMARY KEY****** иначе прийдёёться создавать последовательности вручную (рабочий пример ниже)
GRANT ALL ON kiev.select_region to simpleuser;
GRANT ALL ON select_region_id_seq to simpleuser;-- оказываетья права нужно давать не тольок таблицам но и последовательностям
GRANT ALL ON kiev.select_region to simplereader;
GRANT ALL ON select_region_id_seq to simplereader; -- работает как надо

Alter table kiev.select_region 
add column sum_houses integer, 
add column sum_house_amp integer, 
add column sum_trunk_amp integer, 
add column sum_node integer,
add column sum_opt integer,
add column sum_agg_switches integer, 
add column sum_acc_switches integer;

------CREATE UNIQUE INDEX kiev_select_region_id on kiev.select_region (id);  
/*
CREATE SEQUENCE  IF NOT EXISTS kiev.kiev_select_region_id start 1  OWNED BY kiev.select_region.id; -- команда работает созадёт последовательность
Alter table kiev.select_region  ALTER COLUMN id SET DEFAULT nextval('kiev.kiev_select_region_id');  -- присваеваем по дефолту значение последоватльности
Alter table kiev.select_region 
ADD CONSTRAINT id PRIMARY KEY USING INDEX kiev_select_region_id;
GRANT ALL ON kiev.kiev_select_region_id   to simpleuser; --- оказываетья права нужно давать не тольок таблицам но и последовательностям - иначе ничего нельзя делать причём GRANT SELECT  не помагает
 */


__________________________________________________________________________________________________________
----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION kiev.select_region() RETURNS trigger AS $select_region$ -- эта версия норм работает 
-- после реализации для всех городов нужно добаить а ночной апдейт
  city name :=TG_TABLE_SCHEMA;
  BEGIN 
  IF  TG_OP = 'INSERT' THEN 

  EXECUTE 'UPDATE kiev.select_region
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id, count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where  select_region.id=$1.id ; ' USING NEW; --  - работает нормально 

	RETURN NEW;
  END IF; 
  IF  TG_OP =  'UPDATE' THEN 
  		IF   ST_Equals(NEW.geom , OLD.geom)=TRUE  THEN EXECUTE '' USING NEW; RETURN NEW;
  		ELSIF   ST_Equals(NEW.geom , OLD.geom)=FALSE  THEN
     	EXECUTE 'UPDATE kiev.select_region
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id,count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where  select_region.id=tmp.id; ' USING NEW; -- только в таком варианте работает
		RETURN NEW;
		END IF; 
  END IF; 
  IF TG_OP = 'DELETE' THEN  EXECUTE '' USING OLD;
    RETURN OLD;
  END IF; 
END;
-----------------
  $select_region$ LANGUAGE plpgsql; 

CREATE TRIGGER select_region AFTER INSERT OR UPDATE OR DELETE ON kiev.select_region
    FOR EACH ROW EXECUTE PROCEDURE select_region(); 
-------------работает нормально нужно сохранить
-- нужно добавить count(cubic_house_id)
__________________________________________________________________________________________________________
----------------------------------------------------------------------------------------------------------

*******************************************************************************************************
SELECT agg.id, count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc ;  ---- это то что нужно
-------- ВОПРОС: засунуть это в триггер 
-- count(cubic_house_id)  тоже работает  - нужно добавить это поле 

ниже добавлю поиск по таблице оборудования КТВ kiev _ctv_topology

SELECT agg.id, count(agg.agg_cubic_code) as sum_equip  FROM kiev.kiev_ctv_topology, (select  r.id, b.cubic_code as  agg_cubic_code  from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптичний приймач', 'Оптический узел',  'Порт ОК', 'Кросс-муфта', 'Домовой узел', 'Магистральный узел') group by  r.id, b.cubic_code ) agg   where kiev_ctv_topology.cubic_code=agg.agg_cubic_code  group by agg.id order by id desc ; -- все узлы в этой выборки считает вопрос как выбрать те что нужно по типу

--
----- IN ('Оптичний приймач', 'Оптический узел',  'Порт ОК', 'Кросс-муфта', 'Домовой узел', 'Магистральный узел')
-- не понятно что с этим дальше делать может какой-то join или  union  добавить?

SELECT aggnode.id, aggsplice.id,  count(aggnode.cubic_name) as sum_node,  count(aggsplice.cubic_name) as sum_splice  
 FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптический узел') group by  r.id, b.cubic_code, b.cubic_name ) aggnode ON kiev_ctv_topology.cubic_code=aggnode.cubic_code  
   LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Кросс-муфта') group by  r.id, b.cubic_code, b.cubic_name ) aggsplice   ON   kiev_ctv_topology.cubic_code=aggsplice.cubic_code  
   group by aggnode.id, aggsplice.id order by aggnode.id desc;

что-то нихера так не работает: нужно ещё соединить эти таблицы INNER JOIN  по  aggnode.id = aggsplice.id 
надо всё переделать 
сделать  LEFT JOIN с тремя таблицами: select_region  SUM_aggnode    SUM_aggsplice   по коду ::
ON   select_region.id =aggnode.id  ON   select_region.id=aggsplice.id

---------------------------------------------------------

SELECT select_region.id, N.sum_node, S.sum_splice 
FROM kiev.select_region
 LEFT JOIN 
(SELECT aggnode.id, count(aggnode.cubic_name) as sum_node FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптический узел') group by  r.id, b.cubic_code, b.cubic_name ) aggnode ON kiev_ctv_topology.cubic_code=aggnode.cubic_code       group by aggnode.id order by aggnode.id desc) N  ON select_region.id=N.id
LEFT JOIN 
(SELECT  aggsplice.id,   count(aggsplice.cubic_name) as sum_splice  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Кросс-муфта') group by  r.id, b.cubic_code, b.cubic_name ) aggsplice   ON   kiev_ctv_topology.cubic_code=aggsplice.cubic_code    group by  aggsplice.id order by aggsplice.id desc) S  ON select_region.id=S.id
group by select_region.id, N.sum_node, S.sum_splice  order by select_region.id desc; --это делает то что нужно я не понял зачем просит group by для N.sum_node, S.sum_splice  

УПРОСТИМ названия:
----- IN ('Оптичний приймач', 'Оптический узел',  'Порт ОК', 'Кросс-муфта', 'Домовой узел', 'Магистральный узел')

SELECT select_region.id, N.sum as sum_node, O.sum as sum_opt,  T.sum as sum_trunk_amp, D.sum as sum_house_amp -- менять нужно тут и в внизу в group by
FROM kiev.select_region
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптический узел') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) N  ON select_region.id=N.id
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптичний приймач') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) O  ON select_region.id=O.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Магистральный узел') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) T  ON select_region.id=T.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Домовой узел') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) D  ON select_region.id=D.id
group by select_region.id, N.sum,O.sum , T.sum, D.sum   order by select_region.id desc; -- проверил работает ОК  
-- можно сделать аналогично для свичей
-------------------------------------------------
--вытягиваем данные по свичам:

SELECT select_region.id, A.sum as sum_agg_switches, C.sum as sum_acc_switches -- менять нужно тут и в внизу в group by
FROM kiev.select_region
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN ('agr') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) A  ON select_region.id=A.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN ('acc','sbagr') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) C  ON select_region.id=C.id
group by select_region.id, A.sum, C.sum  order by select_region.id desc;

---------------------------------------------
-- пробую запихнуть в триггер ниже
__________________________________________________________________________________________________________
----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION kiev.select_region() RETURNS trigger AS $select_region$ --проверил работает норм
-- после реализации для всех городов нужно добаить а ночной апдейт
DECLARE 
  city name :=TG_TABLE_SCHEMA;
  BEGIN 
  IF  TG_OP = 'INSERT' THEN 

  EXECUTE '-- данные из домов
  			UPDATE kiev.select_region 
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id, count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where  select_region.id=$1.id ;


--ниже берём данные из топологии КТВ
  			UPDATE kiev.select_region  
            SET
            sum_node=tmp.sum_node,
            sum_opt=tmp.sum_opt, 
            sum_trunk_amp=tmp.sum_trunk_amp,
            sum_house_amp=tmp.sum_house_amp

            FROM (SELECT select_region.id, N.sum as sum_node, O.sum as sum_opt,  T.sum as sum_trunk_amp, D.sum as sum_house_amp -- менять нужно тут и в внизу в group by
FROM kiev.select_region
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптический узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) N  ON select_region.id=N.id
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптичний приймач'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) O  ON select_region.id=O.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Магистральный узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) T  ON select_region.id=T.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Домовой узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) D  ON select_region.id=D.id
group by select_region.id, N.sum,O.sum , T.sum, D.sum   order by select_region.id desc) tmp 
             where  select_region.id=$1.id ;

-- ниже берём данные по свичам на сети (_switches_working)
			UPDATE kiev.select_region  
            SET
            sum_agg_switches=tmp.sum_agg_switches,
            sum_acc_switches=tmp.sum_acc_switches
FROM  (SELECT select_region.id, A.sum as sum_agg_switches, C.sum as sum_acc_switches -- менять нужно тут и в внизу в group by
FROM kiev.select_region
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''agr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) A  ON select_region.id=A.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''acc'',''sbagr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) C  ON select_region.id=C.id
group by select_region.id, A.sum, C.sum  order by select_region.id desc) tmp 
             where  select_region.id=$1.id ;
              ' USING NEW; -- пока чистый INSERT - работает нормально что делать с UPDATE непонятно. 

	RETURN NEW;
  END IF; 
  IF  TG_OP =  'UPDATE' THEN 
  		IF   ST_Equals(NEW.geom , OLD.geom)=TRUE  THEN EXECUTE '' USING NEW; RETURN NEW;
  		ELSIF   ST_Equals(NEW.geom , OLD.geom)=FALSE  THEN  -- сюда нужно отдельно добавить всё с  тригера обновления домов
     	EXECUTE '--- данные из домов
     		UPDATE kiev.select_region  
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id,count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp 
             where  select_region.id=tmp.id;

        --- данные из тпологии КТВ
     	UPDATE kiev.select_region  
            SET
            sum_node=tmp.sum_node,
            sum_opt=tmp.sum_opt,
            sum_trunk_amp=tmp.sum_trunk_amp,
            sum_house_amp=tmp.sum_house_amp

            FROM (SELECT select_region.id, N.sum as sum_node, O.sum as sum_opt,  T.sum as sum_trunk_amp, D.sum as sum_house_amp -- менять нужно тут и в внизу в group by
FROM kiev.select_region
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптический узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) N  ON select_region.id=N.id
 LEFT JOIN 
(SELECT agg.id, count(agg.cubic_name) as sum FROM kiev.kiev_ctv_topology
 LEFT JOIN  (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Оптичний приймач'') group by  r.id, b.cubic_code, b.cubic_name ) agg ON kiev_ctv_topology.cubic_code=agg.cubic_code       group by agg.id order by agg.id desc) O  ON select_region.id=O.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Магистральный узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) T  ON select_region.id=T.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.cubic_name) as sum  
 FROM kiev.kiev_ctv_topology
    LEFT JOIN   (select  r.id, b.cubic_code, b.cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN (''Домовой узел'') group by  r.id, b.cubic_code, b.cubic_name ) agg   ON   kiev_ctv_topology.cubic_code=agg.cubic_code    group by  agg.id order by agg.id desc) D  ON select_region.id=D.id
group by select_region.id, N.sum,O.sum , T.sum, D.sum   order by select_region.id desc) tmp 
             where  select_region.id=tmp.id; 

 -- ниже берём данные по свичам на сети (_switches_working)
			UPDATE kiev.select_region  
            SET
            sum_agg_switches=tmp.sum_agg_switches,
            sum_acc_switches=tmp.sum_acc_switches
FROM  (SELECT select_region.id, A.sum as sum_agg_switches, C.sum as sum_acc_switches -- менять нужно тут и в внизу в group by
FROM kiev.select_region
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''agr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) A  ON select_region.id=A.id
LEFT JOIN 
(SELECT  agg.id,   count(agg.switch_role) as sum  
 FROM kiev.kiev_switches_working
    LEFT JOIN   (select  r.id, b.switch_id, b.switch_role   from kiev.select_region R,  kiev.kiev_switches_working B  where  ST_Intersects(B.switches_geom, R.geom) AND b.switch_role  IN (''acc'',''sbagr'') group by  r.id, b.switch_id, b.switch_role ) agg   ON   kiev_switches_working.switch_id=agg.switch_id    group by  agg.id order by agg.id desc) C  ON select_region.id=C.id
group by select_region.id, A.sum, C.sum  order by select_region.id desc) tmp 
             where  select_region.id=tmp.id ;' USING NEW; -- только в таком варианте работает
		RETURN NEW;
		END IF; 
  END IF; 
  IF TG_OP = 'DELETE' THEN  EXECUTE '' USING OLD;
    RETURN OLD;
  END IF; 
END;
-----------------
  $select_region$ LANGUAGE plpgsql; 

CREATE TRIGGER select_region AFTER INSERT OR UPDATE OR DELETE ON kiev.select_region
    FOR EACH ROW EXECUTE PROCEDURE select_region(); 
------------- нужно проверить

__________________________________________________________________________________________________________
----------------------------------------------------------------------------------------------------------

--------------------------------------------------
---- ниже тупое решение в лоб и оно работает!
SELECT agg.id,  count(agg.agg_cubic_name) as sum_opt   FROM kiev.kiev_ctv_topology, (select  r.id, b.cubic_code as  agg_cubic_code, b.cubic_name as  agg_cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптичний приймач') group by  r.id, b.cubic_code, b.cubic_name ) agg   where kiev_ctv_topology.cubic_code=agg.agg_cubic_code  group by agg.id order by id desc ;

SELECT agg.id,  count(agg.agg_cubic_name) as sum_node   FROM kiev.kiev_ctv_topology, (select  r.id, b.cubic_code as  agg_cubic_code, b.cubic_name as  agg_cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Оптический узел') group by  r.id, b.cubic_code, b.cubic_name ) agg   where kiev_ctv_topology.cubic_code=agg.agg_cubic_code  group by agg.id order by id desc ;

SELECT agg.id,  count(agg.agg_cubic_name) as sum_splice  FROM kiev.kiev_ctv_topology, (select  r.id, b.cubic_code as  agg_cubic_code, b.cubic_name as  agg_cubic_name   from kiev.select_region R,  kiev.kiev_ctv_topology B  where  ST_Intersects(B.equipment_geom, R.geom) AND b.cubic_name  IN ('Кросс-муфта') group by  r.id, b.cubic_code, b.cubic_name ) agg   where kiev_ctv_topology.cubic_code=agg.agg_cubic_code  group by agg.id order by id desc ;


*******************************************************************************************************  

UPDATE kiev.select_region
            SET
            sum_hp = tmp.sum_hp,
            sum_ktv=tmp.sum_ktv,
            sum_atv=tmp.sum_atv,
            sum_eth=tmp.sum_eth,
            sum_docsis= tmp.sum_docsis,
            sum_active_contr=tmp.sum_active_contr,
            sum_houses=tmp.sum_houses

            FROM (SELECT agg.id, count(agg.agg_cubic_house_id) as sum_houses, sum(cubic_cnt::integer) as sum_hp, sum(cubic_cnt_docsis::integer) as sum_docsis, sum(cubic_cnt_ktv::integer) as sum_ktv, sum(cubic_cnt_atv::integer) as sum_atv, sum(cubic_cnt_eth::integer) as sum_eth, sum(cubic_cnt_active_contr::integer) as sum_active_contr  FROM kiev.kiev_buildings, (select  r.id, b.cubic_house_id as  agg_cubic_house_id   from kiev.select_region R,  kiev.kiev_buildings B  where  ST_Intersects(B.building_geom, R.geom)  group by  r.id, b.cubic_house_id ) agg   where kiev_buildings.cubic_house_id=agg.agg_cubic_house_id  group by agg.id order by id desc) tmp   where  select_region.id=tmp.id ; -- делает то что нужно
-------- ВОПРОС: засунуть это в триггер 
***************************************************************************


////////////////////////////////

select id, max(total_intersected) as "total intersected", st_area(st_union(geom)) as area   
from 
  (select a.id as id, array_agg(b.id) as b_int, 
          sum(case when st_intersects(a.geom, b.geom)='t' then 1 else 0 end) as total_intersected, 
          array_agg(b.geom) as geom 
  from 
    circles a, circles b 
  where  st_intersects(a.geom, b.geom)  group by a.id) agg 

where id=any(b_int) group by id, geom order by max(total_intersected) desc;

//////////////////////////////

