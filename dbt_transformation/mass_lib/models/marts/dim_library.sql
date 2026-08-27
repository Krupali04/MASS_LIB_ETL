{{ config(materialized='table') }}

-- One row per library. 372 rows.
--
-- This is the "who" table. It answers questions about a library itself -
-- what it's called, where it is, which network, is it still open - without
-- repeating that text on all six of its yearly rows.
--
-- Attributes are taken from the library's MOST RECENT year, because names,
-- networks and population groups change over time and you want today's answer.

with ranked as (

    select
        *,
        row_number() over (
            partition by library_id
            order by fiscal_year desc
        ) as recency_rank
    from {{ ref('int_circulation') }}

),

latest as (

    select * from ranked where recency_rank = 1

),

history as (

    select
        library_id,
        min(fiscal_year)  as first_year_reported,
        max(fiscal_year)  as last_year_reported,
        count(*)          as years_reported
    from {{ ref('int_circulation') }}
    group by 1

)

select
    l.library_id,

    -- current details
    l.canonical_location  as location,
    l.town_name,
    l.library_name,
    l.network_code,
    l.is_networked,
    l.municipal_population_group,
    l.library_population_group,
    l.municipal_population as latest_municipal_population,
    l.service_population   as latest_service_population,

    -- history
    h.first_year_reported,
    h.last_year_reported,
    h.years_reported,

    -- a library that stopped reporting before the final year has closed.
    -- W. Acton Citizens' and Northfield's Field Library both closed in 2023.
    case when h.last_year_reported = (select max(fiscal_year) from {{ ref('int_circulation') }})
         then true else false end as is_active,

    -- 15 towns have more than one library, which matters for per-capita
    count(*) over (partition by l.town_name) as libraries_in_town

from latest l
join history h on l.library_id = h.library_id