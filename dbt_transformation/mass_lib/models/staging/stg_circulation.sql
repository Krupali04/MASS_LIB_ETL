{{ config(materialized='view') }}

-- Cleans and combines all six years of raw circulation data.
-- Should return 2,208 rows (369+369+369+367+367+367).
--
-- The six raw tables are NOT the same shape, so every column is listed by name:
--   * 2020 has no LIBRARY_POPULATION / LIBRARY_POPULATION_GROUP  (added in 2021)
--   * 2025 has no electronic collection usage column             (dropped in 2025)
--   * 2024 has Excel working notes baked into three column names
-- Missing columns are filled with NULL so all six branches line up.
--
-- QUOTED NAMES: when the files loaded, Snowflake uppercased most column names
-- but left five exactly as they were in Excel. Those need "double quotes" and
-- must match character-for-character - including the two spaces in
-- "Total  Circulation" and the two before "=L5" in the 2024 FTE column.

with all_years as (

    select
        '2020'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        cast(null as varchar)                         as library_population,
        cast(null as varchar)                         as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        TOTAL_CIRC_PER_FTE                            as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE"     as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        TOTAL_ELECTRONIC_COLLECTION_USAGE             as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2020') }}

    union all

    select
        '2021'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        LIBRARY_POPULATION                            as library_population,
        LIBRARY_POPULATION_GROUP                      as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        TOTAL_CIRC_PER_FTE                            as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE"     as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        TOTAL_ELECTRONIC_COLLECTION_USAGE             as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2021') }}

    union all

    select
        '2022'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        LIBRARY_POPULATION                            as library_population,
        LIBRARY_POPULATION_GROUP                      as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        TOTAL_CIRC_PER_FTE                            as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE"     as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        TOTAL_ELECTRONIC_COLLECTION_USAGE             as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2022') }}

    union all

    select
        '2023'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        LIBRARY_POPULATION                            as library_population,
        LIBRARY_POPULATION_GROUP                      as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        TOTAL_CIRC_PER_FTE                            as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE"     as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        TOTAL_ELECTRONIC_COLLECTION_USAGE             as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2023') }}

    union all

    select
        '2024'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        LIBRARY_POPULATION                            as library_population,
        LIBRARY_POPULATION_GROUP                      as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        "Total Circ per FTE =L5/(AG5/35)"             as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE  =L5/(AG5-AI5/35)"
                                                      as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        TOTAL_ELECTRONIC_COLLECTION_USAGE_C37_NOT_C4  as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2024') }}

    union all

    select
        '2025'                                            as fiscal_year,

        LOCATION                                      as location_raw,
        LIBRARY_NETWORK                               as network_code,
        MUNICIPAL_POPULATION                          as municipal_population,
        MUNICIPAL_POPULATION_GROUP                    as municipal_population_group,
        LIBRARY_POPULATION                            as library_population,
        LIBRARY_POPULATION_GROUP                      as library_population_group,
        TOTAL_CIRC_PER_CAPITA                         as circ_per_capita_published,
        TOTAL_CIRC_PER_HOUR_OPEN                      as circ_per_hour_open_published,
        TOTAL_CIRC_PER_FTE                            as circ_per_fte_published,
        "Total Circulation per Non-Custodial FTE"     as circ_per_noncustodial_fte_published,
        DIRECT_CIRC                                   as direct_circ,
        TOTAL_CIRC_ACTIVITY                           as total_circ_activity,
        cast(null as varchar)                         as electronic_collection_usage,
        ILL_RECEIVED                                  as ill_received,
        ILL_PROVIDED                                  as ill_provided,
        TOTAL_NONRESIDENT_CIRCULATION                 as nonresident_circ,
        TOTAL_PRINT_BOOKS_CIRCULATION                 as print_books_circ,
        "Total print periodicals, newspapers & other print serials circulation"
                                                      as print_serials_circ,
        TOTAL_PHYSICAL_AUDIO_CIRCULATION              as physical_audio_circ,
        TOTAL_PHYSICAL_VIDEO_CIRCULATION              as physical_video_circ,
        TOTAL_EBOOKS_CIRCULATION                      as ebook_circ,
        TOTAL_DOWNLOADABLE_AUDIO_CIRCULATION          as downloadable_audio_circ,
        TOTAL_DOWNLOADABLE_VIDEO_CIRCULATION          as downloadable_video_circ,
        TOTAL_MATERIALS_IN_ELECTRONIC_FORMAT_CIRCULATION
                                                      as electronic_format_circ,
        MATERIALS_IN_MICROFORMS_CIRCULATED            as microform_circ,
        "Miscellaneous (e.g. Museum Passes, ebook readers, game consoles, cake pans, kits, wireless hotspots, framed art prints)"
                                                      as misc_circ,
        "Total non-print circulation"                 as nonprint_circ,
        "Total  Circulation (Print + NonPrint)"       as total_circ_published
    from {{ source('source', 'circulation_data_2025') }}

)


-- Clean it up: text to numbers, split the location, tidy the network name.
select
    {{ to_num('fiscal_year') }}                          as fiscal_year,

    -- split "Abington - Abington Public Library" into two parts
    location_raw,
    split_part(location_raw, ' - ', 1)                   as town_name,
    split_part(location_raw, ' - ', 2)                   as library_name,

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

-- Drop the 5 summary rows in each file (Total, Avg, Max, Min, Median).
-- Every real library is "Town - Library Name". Summary rows have no " - ".
where location_raw like '% - %'