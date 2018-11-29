------------------есть оптич кабель (ККЕ) а  договоров НЕТ
SELECT DISTINCT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
where  (ST_Intersects(ST_StartPoint(g.geom), a.building_geom) or ST_Intersects(ST_EndPoint(g.geom), a.building_geom)) and  a.cubic_cnt_active_contr='0'
 ---------работает быстро 6 секунд

--------------------------------есть оптич кабель (ККЕ) а  договоров НЕТ
SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr,a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description_fact FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channels as g  where  (ST_Intersects(ST_StartPoint(g.geom_cable), a.building_geom) OR  ST_Intersects(ST_EndPoint(g.geom_cable), a.building_geom)) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
order BY cubic_house_id,cubic_house_type, adress -- работает быстро 3 секунд


kiev_cable_air  geom_cable  cable_type  cable_description

SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr,a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_air as g where   (ST_Intersects(ST_StartPoint(g.geom_cable), a.building_geom) OR  ST_Intersects(ST_EndPoint(g.geom_cable), a.building_geom)) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
order BY cubic_house_id, adress --air  - почти всё - это транзит

--------------------------------------------------------------
добавлю выборку : есть кабель но нет ЛОУ или ОП
----------------------------------------------
SELECT DISTINCT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
where  (ST_Intersects(ST_StartPoint(g.geom), a.building_geom) or ST_Intersects(ST_EndPoint(g.geom), a.building_geom)) and  a.cubic_house_id NOT IN (SELECT distinct cubic_house_id FROM  kiev.kiev_ctv_topology where cubic_name IN ('Оптический узел', 'Оптичний приймач', 'Кросс-муфта'))    ---  формально всё исчет правильно но у нас муфты привязаны не к тем домам, которые указаны  всего 105домов - фактически с неверно указаніми кодами!!!

---так что тоже нужно поиграться  ST_Intersects муфт и домов ниже НИЧЕГо не вішло
-----------------------------------------------------------------------------------------------------

SELECT  DISTINCT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
where  (ST_Intersects(ST_StartPoint(g.geom), a.building_geom) or ST_Intersects(ST_EndPoint(g.geom), a.building_geom))  as KK
 -- дома с концами кабелей


SELECT distinct d.cubic_house_id FROM  kiev.kiev_buildings as d, kiev.kiev_ctv_topology as t where  cubic_name NOT IN ('Оптический узел', 'Оптичний приймач', 'Кросс-муфта')  and ST_Intersects(t.equipment_geom, d.building_geom) 	--  дома с муфтами и ЛОУ




 SELECT  DISTINCT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g where  (ST_Intersects(ST_StartPoint(g.geom), a.building_geom) or ST_Intersects(ST_EndPoint(g.geom), a.building_geom))  AND
 -- 1065 домов  с концами кабелей
cubic_house_id  NOT IN
(SELECT distinct b.cubic_house_id FROM  kiev.kiev_buildings as b, kiev.kiev_ctv_topology as t where  ST_Intersects(t.equipment_geom, b.building_geom) AND t.cubic_name IN ('Оптический узел', 'Оптичний приймач', 'Кросс-муфта') )   --1722 дома с ЛОУ или муфтами а в суме ничего НЕ НАХОДИТ почему??! 


1435587815 -раскової

 SELECT kk.cubic_house_id,kk.adress  FROM 
 (SELECT  a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
  where  ST_Intersects(ST_StartPoint(g.geom), a.building_geom) or ST_Intersects(ST_EndPoint(g.geom), a.building_geom) ) as KK
 -- 1065 домов  с концами кабелей

INNER JOIN (SELECT distinct b.cubic_house_id FROM  kiev.kiev_buildings as b, kiev.kiev_ctv_topology as t where  ST_Intersects(t.equipment_geom, b.building_geom) AND t.cubic_name NOT IN ('Оптический узел', 'Оптичний приймач', 'Кросс-муфта') ) as NN ON NN.cubic_house_id=KK.cubic_house_id
--- херня какая то  есть дома в которых вообще нет узлов и вторая таблица пустая а значит пересечений нет вообще. п


-------- ЛОУ привязаные к ВОК ККЕ --- 
SELECT  a.cubic_code, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_coment FROM  kiev.kiev_ctv_topology as a,  kiev.kiev_cable_channel_cable_geom as g
where  a.cubic_name IN ('Оптический узел', 'Оптичний приймач')  and (
	ST_Intersects(ST_StartPoint(g.geom), ST_Buffer(a.equipment_geom,1))
 or ST_Intersects(ST_EndPoint(g.geom), ST_Buffer(a.equipment_geom,1))
 )   --- Час виконання: 461,797.232 мсек  = 8минут


-------- ЛОУ привязаные к ВОК ККЕ --- вариант два : без конечных точек - нормально ищет нашло 395
SELECT  a.cubic_code, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_coment FROM  kiev.kiev_ctv_topology as a,  kiev.kiev_cable_channel_cable_geom as g
where  a.cubic_name IN ('Оптический узел', 'Оптичний приймач')  and 
	ST_Intersects(g.geom, ST_Buffer(a.equipment_geom,5)) 
   --- Час виконання: 227,369.526 мсек

-------- ЛОУ привязаные к ВОК ККЕ+AIR
   SELECT  a.cubic_code, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_coment FROM  kiev.kiev_ctv_topology as a,   (SELECT geom FROM kiev.kiev_cable_channel_cable_geom UNION SELECT geom FROM kiev.kiev_cable_air_cable_geom)   as g
where  a.cubic_name IN ('Оптический узел', 'Оптичний приймач')  and 
	ST_Intersects(g.geom, ST_Buffer(a.equipment_geom,5)) --1270 запис(и/╕в) Час виконання: 389,677.304 мсек

-------- ищем ЛОУ НЕ привязаные к ВОК ККЕ+AIR

SELECT t2.* FROM 
(SELECT  a.cubic_pgs_addr, a.cubic_code, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_coment FROM  kiev.kiev_ctv_topology as a
where  a.cubic_name IN ('Оптический узел', 'Оптичний приймач') ) as t2 --1947штук

WHERE t2.cubic_code NOT IN
	(SELECT  a.cubic_code FROM  kiev.kiev_ctv_topology as a,   (SELECT geom FROM kiev.kiev_cable_channel_cable_geom UNION SELECT geom FROM kiev.kiev_cable_air_cable_geom)   as g
where  a.cubic_name IN ('Оптический узел', 'Оптичний приймач')  and 
	ST_Intersects(g.geom, ST_Buffer(a.equipment_geom,10)) 
	)  order by t2.cubic_pgs_addr, t2.adress

-------------840 запис(и/╕в)  Час виконання: 384,631.693 мсек