
khmelnitsky.khmelnitsky_buildings
cubic_date_building
cubic_date_building_eth
cubic_date_ct  - вот это и есть поле подключение дома

--------- выбрать 1 значение с  максимальной датой ----тут некрасиво получаетьс т.к. сравнение не по id----------

Select a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, a.cubic_date_building,a.cubic_date_building_eth,a.cubic_date_ct
FROM (select cubic_house_id, cubic_street, cubic_house, cubic_cnt, cubic_cnt_active_contr,cubic_date_building,cubic_date_building_eth,cubic_date_ct, to_date(cubic_date_ct,'DD Mon YYYY') as max_date_building from khmelnitsky.khmelnitsky_buildings) a
RIGHT JOIN (select  max(to_date(cubic_date_ct,'DD Mon YYYY')) as max_date from khmelnitsky.khmelnitsky_buildings) b  ON a.max_date_building=b.max_date

---вариант №2 без join  работает гуд, за исключением того, что у нас поле charvar и поэтому max(charvar) не адекватно сортирует, а для конвертации в дату нжуно более сложное писать///

Select a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, a.cubic_date_building,a.cubic_date_building_eth,a.cubic_date_ct FROM khmelnitsky.khmelnitsky_buildings a WHERE a.cubic_date_ct = (select  max(cubic_date_ct) FROM khmelnitsky.khmelnitsky_buildings)
--------------------OK

--------- выбрать ТОП 10 значения с  максимальной датой --------------
--- в принципе это универсальный случай LIMIT=1 и всё  


Select a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, a.cubic_date_building, a.cubic_date_building_eth, a.cubic_date_ct
FROM khmelnitsky.khmelnitsky_buildings a
RIGHT JOIN (select  cubic_house_id, (to_date(cubic_date_ct,'DD Mon YYYY')) as max_date from khmelnitsky.khmelnitsky_buildings where cubic_date_ct is NOT NULL  ORDER by max_date desc LIMIT 50) b  ON a.cubic_house_id=b.cubic_house_id ORDER by b.max_date desc


-----------------------------------------------------------------------

--------- выбрать ТОП 10 значения с  максимальным % подключений (квартир >30)--------------

Select a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, a.cubic_date_ct, a.cubic_house_type, b.procent 
FROM  khmelnitsky.khmelnitsky_buildings a 
RIGHT JOIN (SELECT cubic_house_id, COALESCE(ROUND(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2),0) as procent FROM khmelnitsky.khmelnitsky_buildings where cubic_cnt::int>30 ORDER BY procent DESC limit 50) b ON a.cubic_house_id=b.cubic_house_id ORDER by b.procent DESC


--------- выбрать ТОП 10 значения с  минимальным % подключений (квартир >30)-------------- без DESC
Select a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr,a.cubic_date_ct,a.cubic_house_type, b.procent 
FROM  khmelnitsky.khmelnitsky_buildings a 
RIGHT JOIN (SELECT cubic_house_id, COALESCE(ROUND(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2),0) as procent FROM khmelnitsky.khmelnitsky_buildings where cubic_cnt::int>30 ORDER BY procent  limit 50) b ON a.cubic_house_id=b.cubic_house_id ORDER by b.procent 

------------------------------------------
------------------------------------------


----- найти средний процент по районам:
SELECT cubic_hpname, avg_proc FROM 
  		(SELECT cubic_hpname, round(avg(cubic_cnt_active_contr::decimal/cubic_cnt::decimal),2) avg_proc  FROM khmelnitsky.khmelnitsky_buildings GROUP BY cubic_hpname) AVG_HP  order by cubic_hpname --ОК


----- найти кол-во домов по районам:
SELECT cubic_hpname, count(cubic_house_id)  FROM khmelnitsky.khmelnitsky_buildings GROUP BY cubic_hpname order by cubic_hpname   --OK



-------- выбрать ТОП  значения  где % абонентов выше среднего по району (cubic_hpname) b.avr_proc_hp
Select a.cubic_hpname, a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, (SELECT avg(cubic_cnt_active_contr::decimal/cubic_cnt::decimal)  FROM khmelnitsky.khmelnitsky_buildings as avg_procent where avg_procent.cubic_hpname=a.cubic_hpname) as avr_proc_hp FROM khmelnitsky.khmelnitsky_buildings As a
  WHERE (cubic_cnt_active_contr::decimal/cubic_cnt::decimal) > (SELECT avg(cubic_cnt_active_contr::decimal/cubic_cnt::decimal)  FROM khmelnitsky.khmelnitsky_buildings as avg_procent where avg_procent.cubic_hpname=a.cubic_hpname) order by a.cubic_hpname  LIMIT 100
------------что-то считает----



-------- выбрать ТОП  значения  где % абонентов выше среднего по району (cubic_hpname) b.avr_proc_hp

Select a.cubic_hpname, a.cubic_house_id, a.cubic_street, a.cubic_house, a.cubic_cnt, a.cubic_cnt_active_contr, round(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2) avg_proc_house, AVG_HP.avg_proc_HP  FROM khmelnitsky.khmelnitsky_buildings As a 
  
  LEFT JOIN (SELECT cubic_hpname, round(avg(cubic_cnt_active_contr::decimal/cubic_cnt::decimal),2) avg_proc_HP  FROM khmelnitsky.khmelnitsky_buildings GROUP BY cubic_hpname Having cubic_hpname is NOT NULL) AVG_HP ON a.cubic_hpname=AVG_HP.cubic_hpname 

  WHERE round(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2)> (SELECT  avg_proc FROM 
  		(SELECT cubic_hpname, round(avg(cubic_cnt_active_contr::decimal/cubic_cnt::decimal),2) avg_proc  FROM khmelnitsky.khmelnitsky_buildings GROUP BY cubic_hpname) AVG_HP WHERE  AVG_HP.cubic_hpname=a.cubic_hpname order by cubic_hpname) order by a.cubic_hpname    limit 100
  ------------что-то считает----


---- кол-во домов в каждом раойне где %>0.7  и дома >20кв
  Select a.cubic_hpname, count (*) as sum_house FROM khmelnitsky.khmelnitsky_buildings As a  WHERE round(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2)>0.7 and a.cubic_cnt::decimal>20
  Group By a.cubic_hpname
 	HAVING cubic_hpname!='Не задан'   ---OK   хороший пример. выбираем. считаем сумму и фильтраци в группе (HAVING)


---- сумма квартир и абонентов в домах с >50% и группировкой по районам
 Select a.cubic_hpname, sum(cubic_cnt::decimal) as sum_cubic_cnt, sum(cubic_cnt_active_contr::decimal) as sum_cubic_cnt_active_contr FROM khmelnitsky.khmelnitsky_buildings As a  WHERE round(cubic_cnt_active_contr::decimal/cubic_cnt::decimal,2)>0.5 and a.cubic_cnt::decimal>10
  Group By  a.cubic_hpname
 	HAVING cubic_hpname!='Не задан' 




---сколько аварий по дому на основе гибридов , т.е. выбираем дом, right join гибриды с группировкой по кол-ву аварийных гибридов в пределах дома
---	khmelnitsky_hybrids_log_alarm_month  house_id  можно даже было бы вьюшку сделать, но она ж не будет обновлять

SELECT c.cubic_house_id, c.adress, c.sum_alarm FROM
	(Select  a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, COUNT(b.mac) as sum_alarm FROM khmelnitsky.khmelnitsky_buildings As a
	RIGHT JOIN khmelnitsky.khmelnitsky_hybrids_log_alarm_month b  ON a.cubic_house_id=b.house_id 
	GROUP by a.cubic_house_id, a.cubic_street, a.cubic_house) c 
WHERE c.sum_alarm >5 order by c.sum_alarm desc


---  НИЖЕ тоже самое с использованием  HAVING --фильтрация в сформированой группе

	Select  a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, COUNT(b.mac) as sum_alarm FROM khmelnitsky.khmelnitsky_buildings As a
	RIGHT JOIN khmelnitsky.khmelnitsky_hybrids_log_alarm_month b  ON a.cubic_house_id=b.house_id 
	GROUP by a.cubic_house_id, a.cubic_street, a.cubic_house
	HAVING COUNT(b.mac) >5 order by COUNT(b.mac) desc


cubic_cnt_docsis


------------------есть оптич кабель (ККЕ) а  договоров НЕТ
SELECT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
where  ST_Intersects(ST_StartPoint(g.geom), a.building_geom) and  a.cubic_cnt_active_contr='0'
UNION SELECT a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type, a.cubic_cnt_active_contr,a.cubic_cnt_docsis, a.cubic_comm  FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channel_cable_geom as g
where  ST_Intersects(ST_EndPoint(g.geom), a.building_geom) and  a.cubic_cnt_active_contr='0' ---------работает быстро 6 секунд

--------------------------------есть оптич кабель (ККЕ) а  договоров НЕТ
SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr,a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description_fact FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channels as g
where  ST_Intersects(ST_StartPoint(g.geom_cable), a.building_geom) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
UNION SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type, a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description_fact  FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_channels as g
where  ST_Intersects(ST_EndPoint(g.geom_cable), a.building_geom) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
order BY cubic_house_type, adress -- работает быстро 6 секунд


kiev_cable_air  geom_cable  cable_type  cable_description

SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type,a.cubic_cnt_active_contr,a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_air as g 
where  ST_Intersects(ST_StartPoint(g.geom_cable), a.building_geom) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
UNION SELECT DISTINCT ON (a.cubic_house_id) a.cubic_house_id, a.cubic_street||' '|| a.cubic_house as adress, a.cubic_network_type, a.cubic_house_type, a.cubic_cnt_active_contr, a.cubic_cnt_docsis, a.cubic_comm, g.cable_type, g.cable_description  FROM  kiev.kiev_buildings as a,  kiev.kiev_cable_air as g
where  ST_Intersects(ST_EndPoint(g.geom_cable), a.building_geom) and  (a.cubic_cnt_active_contr='0' or a.cubic_cnt_docsis='0') 
order BY cubic_house_type, adress --air  - почти всё - это транзит