{# Turns a raw text column into a number.
   - trims spaces
   - turns 'No data' into NULL
   - removes thousands separators like 368,661
   - returns NULL instead of failing if the value is junk #}

{% macro to_num(col) -%}
    try_to_number(
        replace(
            nullif(nullif(trim({{ col }}), ''), 'No data'),
        ',', '')
    )
{%- endmacro %}


{# Same thing, but keeps decimals (for the per-capita / per-hour ratios) #}

{% macro to_dec(col) -%}
    try_to_decimal(
        replace(
            nullif(nullif(trim({{ col }}), ''), 'No data'),
        ',', ''),
        38, 6
    )
{%- endmacro %}