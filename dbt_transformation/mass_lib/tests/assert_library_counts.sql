-- Checks that every year has the number of libraries we expect.
--
-- Why this matters: each raw file has 5 summary rows at the top (Total, Avg,
-- Max, Min, Median). The staging model drops them with a " - " filter. If that
-- filter ever breaks, those rows come back - and they hold statewide totals, so
-- they will not look like junk. They will look like one enormous library and
-- quietly inflate every number you calculate.
--
-- 369 for 2020-2022, then 367 from 2023 (two libraries closed, three renamed).
--
-- A dbt test passes when it returns ZERO rows.

with expected as (

    select 2020 as fiscal_year, 369 as expected_count
    union all select 2021, 369
    union all select 2022, 369
    union all select 2023, 367
    union all select 2024, 367
    union all select 2025, 367

),

actual as (

    select
        fiscal_year,
        count(*) as actual_count
    from {{ ref('stg_circulation') }}
    group by 1

)

select
    e.fiscal_year,
    e.expected_count,
    a.actual_count
from expected e
left join actual a on e.fiscal_year = a.fiscal_year
where a.actual_count is distinct from e.expected_count