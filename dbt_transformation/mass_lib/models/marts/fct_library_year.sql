{{ config(materialized='table') }}

-- One row per library per year. 2,208 rows.
--
-- This is the "what happened" table - only numbers, plus the keys needed to
-- join back to dim_library. Names and towns live in dim_library, not here.

select
    -- keys
    library_id,
    fiscal_year,

    -- population (kept here because it changes every year)
    municipal_population,
    library_population,
    service_population,

    -- ---------- headline volumes ----------
    direct_circ,
    total_circ_activity,
    total_circ_published,
    electronic_collection_usage,

    -- ---------- resource sharing ----------
    ill_received,
    ill_provided,
    ill_provided - ill_received        as net_ill,
    nonresident_circ,

    -- ---------- by material type ----------
    print_books_circ,
    print_serials_circ,
    physical_audio_circ,
    physical_video_circ,
    ebook_circ,
    downloadable_audio_circ,
    downloadable_video_circ,
    electronic_format_circ,
    microform_circ,
    misc_circ,
    nonprint_circ,

    -- ---------- format groups ----------
    print_circ,
    physical_media_circ,
    digital_circ,

    -- ---------- capacity (recovered, not published) ----------
    annual_hours_open,
    round(annual_hours_open / 52, 1)   as weekly_hours_open,
    staff_fte,
    noncustodial_fte,
    round(staff_fte - noncustodial_fte, 2) as custodial_fte,

    -- ---------- rates ----------
    circ_per_capita_published,
    circ_per_capita_recomputed,
    circ_per_hour_open_published,
    circ_per_fte_published,
    circ_per_noncustodial_fte_published,

    -- share of circulation that is digital
    round(digital_circ / nullif(total_circ_activity, 0), 4)
        as digital_share,

    -- how much a library leans on other libraries' collections
    round(ill_received / nullif(direct_circ, 0), 4)
        as ill_intensity,

    -- share of borrowers from out of town
    round(nonresident_circ / nullif(direct_circ, 0), 4)
        as nonresident_share,

    -- ---------- data quality ----------
    reconciliation_gap,
    case when direct_circ is null then false else true end as is_reported

from {{ ref('int_circulation') }}