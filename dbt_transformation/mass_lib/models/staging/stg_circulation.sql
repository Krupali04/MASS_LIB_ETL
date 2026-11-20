{{ config(materialized='view') }}

-- Cleans and combines all six years of raw circulation data.
-- Should return 2,208 rows (369+369+369+367+367+367).
--
-- This used to be ~150 lines of per-year column lists, because the six
-- Snowflake tables each had different column names. The CSVs are now
-- generated with one identical header, so a plain "select *" union works
-- and every year is handled the same way.

{% set years = [2020, 2021, 2022, 2023, 2024, 2025] %}


-- STEP 1: stack the six year tables.
-- If a future year has different columns this fails loudly, which is correct.
with all_years as (

{% for year in years %}
    select * from {{ source('source', 'circulation_' ~ year) }}
    {%- if not loop.last %}
    union all
    {%- endif %}
{% endfor %}

)


-- STEP 2: clean it up.
select
    {{ to_num('fiscal_year') }}                          as fiscal_year,

    -- split "Abington - Abington Public Library" into two parts.
    -- BigQuery split() returns an array, so we index into it.
    -- On Snowflake this was split_part(location_raw, ' - ', 1).
    location_raw,
    split(location_raw, ' - ')[safe_offset(0)]           as town_name,
    split(location_raw, ' - ')[safe_offset(1)]           as library_name,

    -- upper() fixes MASSCAT vs MassCat, which differ between years
    upper(trim(network_code))                            as network_code,
    case when upper(trim(network_code)) = 'NOT A NETWORK'
         then false else true end                        as is_networked,

    {{ to_num('municipal_population') }}                 as municipal_population,
    trim(municipal_population_group)                     as municipal_population_group,
    {{ to_num('library_population') }}                   as library_population,
    trim(library_population_group)                       as library_population_group,

    -- ratios MBLC already calculated. keep as-is, do not recalculate.
    {{ to_dec('circ_per_capita_published') }}            as circ_per_capita_published,
    {{ to_dec('circ_per_hour_open_published') }}         as circ_per_hour_open_published,
    {{ to_dec('circ_per_fte_published') }}               as circ_per_fte_published,
    {{ to_dec('circ_per_noncustodial_fte_published') }}  as circ_per_noncustodial_fte_published,

    -- the two headline numbers
    {{ to_num('direct_circ') }}                          as direct_circ,
    {{ to_num('total_circ_activity') }}                  as total_circ_activity,
    {{ to_num('electronic_collection_usage') }}          as electronic_collection_usage,

    -- borrowing between libraries
    {{ to_num('ill_received') }}                         as ill_received,
    {{ to_num('ill_provided') }}                         as ill_provided,
    {{ to_num('nonresident_circ') }}                     as nonresident_circ,

    -- what type of item was borrowed
    {{ to_num('print_books_circ') }}                     as print_books_circ,
    {{ to_num('print_serials_circ') }}                   as print_serials_circ,
    {{ to_num('physical_audio_circ') }}                  as physical_audio_circ,
    {{ to_num('physical_video_circ') }}                  as physical_video_circ,
    {{ to_num('ebook_circ') }}                           as ebook_circ,
    {{ to_num('downloadable_audio_circ') }}              as downloadable_audio_circ,
    {{ to_num('downloadable_video_circ') }}              as downloadable_video_circ,
    {{ to_num('electronic_format_circ') }}               as electronic_format_circ,
    {{ to_num('microform_circ') }}                       as microform_circ,
    {{ to_num('misc_circ') }}                            as misc_circ,

    -- totals MBLC already calculated
    {{ to_num('nonprint_circ') }}                        as nonprint_circ,
    {{ to_num('total_circ_published') }}                 as total_circ_published

from all_years

-- STEP 3: drop the 5 summary rows in each file (Total, Avg, Max, Min, Median).
-- Every real library is "Town - Library Name". Summary rows have no " - ".
where location_raw like '% - %'