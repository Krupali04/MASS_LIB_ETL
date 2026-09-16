{{ config(materialized='table') }}

-- One row per fiscal year. 6 rows.
--
-- Why this exists: without it, each fact table carries its own fiscal_year
-- column and Tableau treats them as two unrelated fields. A year filter on a
-- dashboard would control one chart and be ignored by the other.
--
-- It also carries the schema-drift notes as real columns, so a caveat can
-- appear in a tooltip instead of living in a README nobody opens.

with years as (

    select
        fiscal_year,
        count(*)                     as libraries_reported,
        sum(total_circ_activity)     as statewide_circ_activity,
        sum(direct_circ)             as statewide_direct_circ
    from {{ ref('fct_library_year') }}
    group by 1

)

select
    fiscal_year,
    'FY' || fiscal_year              as fiscal_year_label,

    libraries_reported,
    statewide_circ_activity,
    statewide_direct_circ,

    -- MBLC divided by municipal population in 2020 and library population
    -- from 2021. Their published per-capita is not comparable across years.
    case when fiscal_year = 2020 then 'municipal' else 'library' end
        as percapita_denominator_basis,

    -- In 2025 "Total Circulation (Print + NonPrint)" stopped equalling
    -- print + non-print and started equalling direct circ + periodicals.
    case when fiscal_year = 2025 then 'direct_plus_periodicals'
         else 'print_plus_nonprint' end
        as total_circ_derivation,

    -- Columns that do not exist in every year
    case when fiscal_year >= 2021 then true else false end
        as has_library_population,
    case when fiscal_year <= 2024 then true else false end
        as has_electronic_collection_usage,

    -- FY2020 runs Jul 2019 - Jun 2020, so it includes the pandemic closure.
    -- Any 2020 comparison mixes recovery with trend.
    case when fiscal_year = 2020 then true else false end
        as is_covid_affected,

    case when fiscal_year = 2020 then 'Includes ~3.5 months of pandemic closure'
         when fiscal_year = 2021 then 'Library population column introduced; per-capita denominator changed'
         when fiscal_year = 2023 then 'Three libraries renamed, two closed'
         when fiscal_year = 2025 then 'Electronic collection usage dropped; total circulation derivation changed'
         else null end
        as data_note

from years
order by fiscal_year