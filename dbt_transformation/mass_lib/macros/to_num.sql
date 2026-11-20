{# Turns a raw text column into a number.
   - trims spaces
   - turns 'No data' and empty string into NULL
   - removes thousands separators like 368,661
   - safe_cast returns NULL instead of erroring on junk

   BigQuery version. On Snowflake these were try_to_number / try_to_decimal.
   This is the only file that knows which warehouse we are on - which is why
   the migration touched six lines instead of every model. #}

{% macro to_num(col) -%}
    safe_cast(
        replace(
            nullif(nullif(trim({{ col }}), ''), 'No data'),
        ',', '') as int64
    )
{%- endmacro %}


{# Same thing, but keeps decimals (for the per-capita / per-hour ratios) #}

{% macro to_dec(col) -%}
    safe_cast(
        replace(
            nullif(nullif(trim({{ col }}), ''), 'No data'),
        ',', '') as numeric
    )
{%- endmacro %}
