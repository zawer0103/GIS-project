
DECLARE 
  city name :=TG_TABLE_SCHEMA;
  geom_start_point_state boolean;
  geom_end_point_state boolean;
BEGIN 
    IF  TG_OP = 'INSERT' THEN  

EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_start_point_state USING NEW;
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_End_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_start = '||city||'_ctv_topology.cubic_code,
              cubic_name_start = '||city||'_ctv_topology.cubic_name,
              cubic_coment_start = '||city||'_ctv_topology.cubic_coment,
              geom_start_point = '||city||'_ctv_topology.equipment_geom,
              geom_cable = ST_SetPoint($1.geom,0,'||city||'_ctv_topology.equipment_geom)
            FROM '||city||'.'||city||'_ctv_topology
            WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom),'||city||'_ctv_topology.equipment_geom) <= 2.8))   AND '||city||'_cable_channels.table_id = $1.table_id  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' USING NEW;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels.table_id = $1.table_id' USING NEW;    
      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
        SET
          cubic_code_end = '||city||'_ctv_topology.cubic_code,
          cubic_name_end = '||city||'_ctv_topology.cubic_name,
          cubic_coment_end = '||city||'_ctv_topology.cubic_coment,
          geom_end_point = '||city||'_ctv_topology.equipment_geom,
          geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1,'||city||'_ctv_topology.equipment_geom)

        FROM '||city||'.'||city||'_ctv_topology
        WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8)) AND '||city||'_cable_channels.table_id = $1.table_id  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')
        ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_start_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels.table_id = $1.table_id' USING NEW; 
      END IF;
      
      RETURN NEW;
      
    ELSIF TG_OP = 'UPDATE' THEN 
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_StartPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_start_point_state USING NEW;
    EXECUTE 'SELECT CASE WHEN count(*) > 0 THEN TRUE ELSE FALSE END FROM '||city||'.'||city||'_ctv_topology WHERE ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' INTO geom_End_point_state USING NEW;
      IF geom_start_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_start = '||city||'_ctv_topology.cubic_code,
              cubic_name_start = '||city||'_ctv_topology.cubic_name,
              cubic_coment_start = '||city||'_ctv_topology.cubic_coment,
              geom_start_point = '||city||'_ctv_topology.equipment_geom,
              geom_cable = ST_SetPoint($1.geom,0,'||city||'_ctv_topology.equipment_geom)
            FROM '||city||'.'||city||'_ctv_topology
            WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom , ST_StartPoint($1.geom)) OR (ST_Distance(ST_StartPoint($1.geom),'||city||'_ctv_topology.equipment_geom) <= 2.8))   AND '||city||'_cable_channels.table_id = $1.table_id  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'') ' USING NEW;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_start = NULL,
              cubic_name_start = NULL,
              cubic_coment_start = NULL,
              geom_start_point = ST_StartPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels.table_id = $1.table_id' USING NEW;    
      END IF;
      IF geom_end_point_state = TRUE THEN
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
        SET
          cubic_code_end = '||city||'_ctv_topology.cubic_code,
          cubic_name_end = '||city||'_ctv_topology.cubic_name,
          cubic_coment_end = '||city||'_ctv_topology.cubic_coment,
          geom_end_point = '||city||'_ctv_topology.equipment_geom,
          geom_cable = ST_SetPoint($1.geom,ST_NPoints($1.geom)-1,'||city||'_ctv_topology.equipment_geom)

        FROM '||city||'.'||city||'_ctv_topology
        WHERE  (ST_Equals('||city||'_ctv_topology.equipment_geom ,ST_EndPoint($1.geom)) OR (ST_Distance(ST_EndPoint($1.geom) ,'||city||'_ctv_topology.equipment_geom) <= 2.8)) AND '||city||'_cable_channels.table_id = $1.table_id  AND '||city||'_ctv_topology.cubic_name IN (''Магістральна ГС'', ''Магістральний оптичний вузол'', ''Магистральный распределительный узел'', ''Оптичний приймач'', ''Оптический узел'', ''Кросс-муфта'')
        ' USING NEW , city;
      ELSE
        EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels
            SET
              cubic_code_end = NULL,
              cubic_name_end = NULL,
              cubic_coment_end = NULL,
              geom_start_point = ST_EndPoint($1.geom),
              geom_cable = $1.geom
            
            WHERE  '||city||'_cable_channels.table_id = $1.table_id' USING NEW; 
      END IF;
      
      RETURN NEW;
      
    ELSIF TG_OP = 'DELETE' THEN 
      
      EXECUTE 'UPDATE '||city||'.'||city||'_cable_channels 
        SET  
          geom_cable =NULL,
          geom_end_point = NULL,
          geom_start_point = NULL,
          cubic_code_start = NULL,
          cubic_name_start = NULL,
          cubic_coment_start = NULL,
          cubic_code_end = NULL,
          cubic_name_end = NULL,
          cubic_coment_end = NULL
        WHERE '||city||'_cable_channels.table_id = $1.table_id;
        ' USING OLD;
      RETURN OLD;
    END IF; 
  END;