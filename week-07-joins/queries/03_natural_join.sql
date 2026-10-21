-- Week 7 — NATURAL JOIN: joins on every column that has the same name in both tables (no ON clause)
-- Convenient and dangerous: if someone later adds a same-named column, the join silently changes meaning.
USE sentinel;

-- merchants and merchant_categories share exactly one column name (category_id), so this is safe:
SELECT merchant_name, category_name
FROM merchants NATURAL JOIN merchant_categories
ORDER BY merchant_id
LIMIT 5;
-- identical to:  FROM merchants m JOIN merchant_categories mc ON mc.category_id = m.category_id

-- The pitfall: merchants and locations share THREE column names (city, latitude, longitude).
-- A NATURAL JOIN would require all three to match at once, and merchant coordinates have a random offset, so:
SELECT COUNT(*) AS rows_from_natural_join_with_locations FROM merchants NATURAL JOIN locations;   -- 0 rows
-- What you probably meant:
SELECT COUNT(*) AS rows_joined_on_city_only FROM merchants m JOIN locations l ON l.city = m.city;

-- JOIN ... USING (col) is the safe middle ground: name the shared column explicitly
SELECT merchant_name, category_name FROM merchants JOIN merchant_categories USING (category_id) ORDER BY merchant_id LIMIT 3;
