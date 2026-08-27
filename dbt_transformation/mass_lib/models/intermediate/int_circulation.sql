{{ config(materialized='view') }}

-- Adds two things staging deliberately left out:
--   1. a stable library_id that survives the 2023 renames
--   2. derived columns (things MBLC did not publish, that we calculate)
--
-- Still one row per library per year. Same 2,208 rows as staging.

with renamed as (

    select
        s.*,
        -- if this library was renamed later, use its current name instead.
        -- that way Goodwin Memorial (2020-2022) and Hadley Public (2023-2025)
        -- are recognised as the same library.
        coalesce(r.current_location, s.location_raw) as canonical_location
    from {{ ref('stg_circulation') }} s
    left join {{ ref('seed_library_renames') }} r
        on s.location_raw = r.old_location

)

select
    -- one ID per library, the same in every year
    {{ dbt_utils.generate_surrogate_key(['canonical_location']) }} as library_id,

    fiscal_year,
    canonical_location,
    location_raw            as location_as_published,
    split_part(canonical_location, ' - ', 1)  as town_name,
    split_part(canonical_location, ' - ', 2)  as library_name,
    network_code,
    is_networked,

    -- population
    municipal_population,
    library_population,
    -- 2020 has no library_population, so fall back to municipal
    coalesce(library_population, municipal_population) as service_population,
    municipal_population_group,
    library_population_group,

    -- ---------- published numbers (unchanged) ----------
    direct_circ,
    total_circ_activity,
    electronic_collection_usage,
    ill_received,
    ill_provided,
    nonresident_circ,
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
    total_circ_published,
    circ_per_capita_published,
    circ_per_hour_open_published,
    circ_per_fte_published,
    circ_per_noncustodial_fte_published,

    -- ---------- derived: format groups ----------
    coalesce(print_books_circ, 0) + coalesce(print_serials_circ, 0)
        as print_circ,

    coalesce(physical_audio_circ, 0) + coalesce(physical_video_circ, 0)
        as physical_media_circ,

    coalesce(ebook_circ, 0)
      + coalesce(downloadable_audio_circ, 0)
      + coalesce(downloadable_video_circ, 0)
      + coalesce(electronic_format_circ, 0)
        as digital_circ,

    -- ---------- derived: recovered hidden numbers ----------
    -- MBLC published ratios but not the denominators. Divide back to get them.
    -- e.g. circulation / (circulation per hour) = hours open
    round(total_circ_activity / nullif(circ_per_hour_open_published, 0), 1)
        as annual_hours_open,

    round(total_circ_activity / nullif(circ_per_fte_published, 0), 2)
        as staff_fte,

    round(total_circ_activity / nullif(circ_per_noncustodial_fte_published, 0), 2)
        as noncustodial_fte,

    -- ---------- derived: our own per-capita ----------
    -- MBLC changed the denominator in 2021 (municipal -> library population),
    -- so their published figure is not comparable across all six years.
    -- This one uses the same basis every year.
    round(
        total_circ_activity
        / nullif(coalesce(library_population, municipal_population), 0)
    , 2) as circ_per_capita_recomputed,

    -- ---------- derived: data quality ----------
    -- direct_circ should equal print books + non-print. Where it doesn't,
    -- the library didn't itemise everything it reported.
    direct_circ - (coalesce(print_books_circ, 0) + coalesce(nonprint_circ, 0))
        as reconciliation_gap

from renamed