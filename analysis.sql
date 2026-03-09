-- Intel Sustainability Impact Analysis
-- This file contains core SQL queries used to evaluate Intel's device repurposing program.

--------------------------------------------------
-- 1. Prepare joined dataset with device age and age buckets
--------------------------------------------------

SELECT
    *,
    2024 - d.model_year AS device_age,
    CASE
        WHEN 2024 - d.model_year <= 3 THEN 'newer'
        WHEN 2024 - d.model_year > 3
             AND 2024 - d.model_year <= 6 THEN 'mid-age'
        ELSE 'older'
    END AS device_age_bucket
FROM intel.device_data AS d
INNER JOIN intel.impact_data AS i
    ON d.device_id = i.device_id
ORDER BY d.model_year ASC;

--------------------------------------------------
-- 2. Overall program impact summary
--------------------------------------------------

WITH joined_data AS (
    SELECT
        *,
        2024 - d.model_year AS device_age,
        CASE
            WHEN 2024 - d.model_year <= 3 THEN 'newer'
            WHEN 2024 - d.model_year > 3
                 AND 2024 - d.model_year <= 6 THEN 'mid-age'
            ELSE 'older'
        END AS device_age_bucket
    FROM intel.device_data AS d
    INNER JOIN intel.impact_data AS i
        ON d.device_id = i.device_id
)
SELECT
    COUNT(*) AS total_devices,
    AVG(device_age) AS avg_device_age,
    AVG(energy_savings_yr) AS avg_energy_savings_kwh,
    SUM(co2_saved_kg_yr) / 1000 AS total_co2_saved_tons
FROM joined_data;

--------------------------------------------------
-- 3. Sustainability impact by device type
--------------------------------------------------

WITH joined_data AS (
    SELECT
        d.device_type,
        2024 - d.model_year AS device_age,
        i.energy_savings_yr,
        i.co2_saved_kg_yr
    FROM intel.device_data AS d
    INNER JOIN intel.impact_data AS i
        ON d.device_id = i.device_id
)
SELECT
    device_type,
    COUNT(*) AS total_devices,
    AVG(energy_savings_yr) AS avg_energy_savings_kwh,
    AVG(co2_saved_kg_yr) / 1000 AS avg_co2_saved_tons
FROM joined_data
GROUP BY device_type;

--------------------------------------------------
-- 4. Sustainability impact by region
--------------------------------------------------

WITH joined_data AS (
    SELECT
        i.region,
        i.energy_savings_yr,
        i.co2_saved_kg_yr
    FROM intel.device_data AS d
    INNER JOIN intel.impact_data AS i
        ON d.device_id = i.device_id
)
SELECT
    region,
    COUNT(*) AS total_devices,
    AVG(energy_savings_yr) AS avg_energy_savings_kwh,
    AVG(co2_saved_kg_yr) / 1000 AS avg_co2_saved_tons
FROM joined_data
GROUP BY region
ORDER BY region;

--------------------------------------------------
-- 5. Device type contribution to energy savings and CO2 reduction by region
--------------------------------------------------

WITH joined_data AS (
    SELECT
        i.region,
        d.device_type,
        i.energy_savings_yr,
        i.co2_saved_kg_yr
    FROM intel.device_data AS d
    INNER JOIN intel.impact_data AS i
        ON d.device_id = i.device_id
),
region_totals AS (
    SELECT
        region,
        SUM(energy_savings_yr) AS total_region_energy,
        SUM(co2_saved_kg_yr) AS total_region_co2
    FROM joined_data
    GROUP BY region
)
SELECT
    j.region,
    j.device_type,
    COUNT(*) AS total_devices,
    SUM(j.energy_savings_yr) AS total_energy_savings,
    SUM(j.co2_saved_kg_yr) / 1000 AS total_co2_saved_tons,
    (SUM(j.energy_savings_yr) / r.total_region_energy) * 100 AS pct_energy_in_region,
    (SUM(j.co2_saved_kg_yr) / r.total_region_co2) * 100 AS pct_co2_in_region
FROM joined_data AS j
JOIN region_totals AS r
    ON j.region = r.region
GROUP BY
    j.region,
    j.device_type,
    r.total_region_energy,
    r.total_region_co2
ORDER BY
    j.region,
    j.device_type;
