-- Prints a stable, diffable description of the schema of database `sentinel`.
-- Used by scripts/compare_to_reference.sh to prove the weekly build ends at the same schema as the original project.
SELECT 'COLUMN' kind, table_name, ordinal_position pos, column_name, column_type, is_nullable,
       IFNULL(column_default,'<NULL>') col_default, extra, IFNULL(collation_name,'') coll
FROM information_schema.columns WHERE table_schema='sentinel' ORDER BY table_name, ordinal_position;
SELECT 'CONSTRAINT' kind, table_name, constraint_name, constraint_type
FROM information_schema.table_constraints WHERE table_schema='sentinel' ORDER BY table_name, constraint_name;
SELECT 'FK' kind, k.table_name, k.constraint_name, k.column_name, k.referenced_table_name, k.referenced_column_name, r.delete_rule, r.update_rule
FROM information_schema.key_column_usage k
JOIN information_schema.referential_constraints r ON r.constraint_schema=k.constraint_schema AND r.constraint_name=k.constraint_name
WHERE k.table_schema='sentinel' ORDER BY k.table_name, k.constraint_name, k.ordinal_position;
SELECT 'CHECK' kind, tc.table_name, cc.constraint_name, cc.check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc ON tc.constraint_schema=cc.constraint_schema AND tc.constraint_name=cc.constraint_name
WHERE cc.constraint_schema='sentinel' ORDER BY tc.table_name, cc.constraint_name;
SELECT 'INDEX' kind, table_name, index_name, seq_in_index, column_name, non_unique
FROM information_schema.statistics WHERE table_schema='sentinel' ORDER BY table_name, index_name, seq_in_index;
SELECT 'ROUTINE' kind, routine_type, routine_name FROM information_schema.routines WHERE routine_schema='sentinel' ORDER BY 2,3;
SELECT 'VIEW' kind, table_name FROM information_schema.views WHERE table_schema='sentinel' ORDER BY 2;
SELECT 'TRIGGER' kind, trigger_name, event_object_table, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema='sentinel' ORDER BY 2;
SELECT 'EVENT' kind, event_name FROM information_schema.events WHERE event_schema='sentinel' ORDER BY 2;
