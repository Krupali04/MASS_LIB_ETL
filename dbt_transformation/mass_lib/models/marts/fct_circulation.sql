{{ config(materialized='table') }}

-- One row per library per year per format. About 22,080 rows.
--
-- Same numbers as fct_library_year, reshaped from WIDE to LONG:
--
--   wide  ->  library | year | print_books | ebooks | dvds
--   long  ->  library | year | format      | circulation
--
-- Why bother? Charting a format mix is one GROUP BY instead of ten CASE
-- statements, and adding a new format later means adding a row here rather
-- than changing every chart.

{% set formats = [
    ('print_books',        'print',          'print_books_circ'),
    ('print_serials',      'print',          'print_serials_circ'),
    ('physical_audio',     'physical_media', 'physical_audio_circ'),
    ('physical_video',     'physical_media', 'physical_video_circ'),
    ('ebook',              'digital',        'ebook_circ'),
    ('downloadable_audio', 'digital',        'downloadable_audio_circ'),
    ('downloadable_video', 'digital',        'downloadable_video_circ'),
    ('electronic_format',  'digital',        'electronic_format_circ'),
    ('microform',          'other',          'microform_circ'),
    ('misc',               'other',          'misc_circ')
] %}

with unpivoted as (

{% for format_code, format_group, column_name in formats %}
    select
        library_id,
        fiscal_year,
        '{{ format_code }}'   as format_code,
        '{{ format_group }}'  as format_group,
        {{ column_name }}     as circulation
    from {{ ref('int_circulation') }}
    {%- if not loop.last %}

    union all
    {%- endif %}
{% endfor %}

)

select
    library_id,
    fiscal_year,
    format_code,
    format_group,
    circulation,

    -- NULL means the library did not report this format.
    -- 0 means it reported zero. Those are different things, so keep a flag.
    case when circulation is null then false else true end as is_reported

from unpivoted