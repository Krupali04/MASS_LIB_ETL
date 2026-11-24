# Massachusetts public library circulation

Analytics pipeline over six years of statutory reports filed by every public
library in Massachusetts with the Board of Library Commissioners (MBLC).
Excel → BigQuery → dbt → Observable Framework.

## Layout

```
Library_project/
├── raw_data/xlsx/                 six source workbooks, FY2020-FY2025 (git-ignored, not pushed)
├── raw_data/csv/                  cleaned CSVs, generated — do not hand-edit (git-ignored)
├── convert.py                     xlsx → BigQuery-safe CSV
├── dbt_transformation/mass_lib/   the dbt project (dbt_project.yml lives here)
└── library-viz/                   Observable Framework site
```

Run dbt from `dbt_transformation/mass_lib`. `profiles.yml` sits in the project
folder, so every command needs `--profiles-dir .`.

## Warehouse

| | |
|---|---|
| Platform | BigQuery, `US` multi-region |
| Auth | service account key at `~/.gcp/dbt-key.json`, never in the repo |
| Raw dataset | `source` — six tables `circulation_2020` … `circulation_2025`, all columns `STRING` |
| dbt output | `dbt_krupali_staging`, `dbt_krupali_intermediate`, `dbt_krupali_marts` |

Everything lands as `STRING` on purpose. FY2025 encodes missing values as the
literal text `No data`, so type inference would make those columns VARCHAR in
one year and INTEGER in the others and the union would fail. Casting happens in
dbt where it is tested.

## Models

```
source.circulation_20xx  (6 tables)
        ↓
stg_circulation          view   2,208 rows   union + cast + drop summary rows
        ↓
int_circulation          view   2,208 rows   stable library_id + derived columns
        ↓
dim_library    table       372 rows
dim_year       table         6 rows
fct_library_year            table    2,208 rows
fct_circulation             table   22,080 rows
```

`dim_year` depends on `fct_library_year`, not the other way round — it aggregates
statewide totals per year. Don't "fix" that edge.

Star schema: both facts join to both dimensions. `fct_circulation`
needs **both** `library_id` and `fiscal_year` to join correctly; on
`library_id` alone it fans out 6×.

## Source data quirks — all real, none worked around by accident

**Five summary rows per file.** Every raw table carries Total / Avg / Max / Min /
Median rows above the data. They hold statewide figures, so if they leak through
they look like one enormous library rather than obvious junk.

The filter is `where location_raw like '% - %'` — every real library is
`Town - Library Name` and no summary row contains that separator. **Do not
replace this with a label match.** The labels drift: FY2021 says "Average",
FY2022 says "Average / Minimum / Maximum". A label filter leaks one junk row
into 2021 and three into 2022. `tests/assert_library_counts.sql` guards this.

**Expected row counts, asserted in tests:** 369 / 369 / 369 / 367 / 367 / 367.
The drop at FY2023 is real — two libraries closed.

**`No data` is NULL, never zero.** 91 cells in FY2025; four libraries carry it
across every measure. Coerced to zero, those four read as a collapse to nothing
and bend the statewide trend.

**Column drift across years.** FY2020 has no `library_population`. FY2025 has no
`electronic_collection_usage`. FY2024 had Excel working formulas left in three
headers. `convert.py` normalises all of this and **raises on any header it does
not recognise** — that is deliberate, so a new column in FY2026 stops the
pipeline instead of vanishing silently.

**Three renames and two closures in FY2023.** `seeds/seed_library_renames.csv`
maps old names to current ones; `int_circulation` coalesces through it so
Goodwin Memorial (FY2020-22) and Hadley Public (FY2023-25) share one
`library_id`. The two closures are not in the seed — they genuinely stopped
reporting, which is correct.

**`MASSCAT` and `MassCat` both appear.** `upper()` in staging collapses them. An
`accepted_values` test catches regression.

**Known bad row:** Needham's municipal population is typed as `225` in the source
(real figure ~32,000), giving a per-capita of ~2,062. Charts filter it with
`circ_per_capita_recomputed < 100`. It is an MBLC data entry error, not ours —
do not "correct" the value in the pipeline.

## The two columns that make this project distinctive

`weekly_hours_open` and `staff_fte` **do not exist in the published files.** MBLC
publishes ratios but not their denominators, so they are recovered by dividing
back:

```
total_circ_activity / circ_per_hour_open_published  = annual hours open
total_circ_activity / circ_per_fte_published        = staff FTE
```

Confirmed by a formula MBLC left in an FY2024 header: `=L5/(AG5/35)`, where
column L is `Total Circ Activity`. Sanity check: median lands at ~31 open hours a
week and ~7 FTE.

These power the only analysis nobody else working with this dataset can do —
telling a library that is *under-open* apart from one that is *underused*.

## Published figures are never overwritten

`circ_per_capita_published` is kept verbatim alongside
`circ_per_capita_recomputed`. MBLC changed the per-capita denominator in FY2021
from municipal to library population, so their own figure is not comparable
across the six years. Keep both so the difference can be explained rather than
silently corrected. `dim_year.percapita_denominator_basis` records which basis
each year used.

Same principle everywhere: a source number stays as published, ours sits beside
it with a `_recomputed` suffix.

## BigQuery dialect notes

The project was migrated from Snowflake. If porting more SQL:

| Snowflake | BigQuery |
|---|---|
| `try_to_number(x)` | `safe_cast(x as int64)` |
| `try_to_decimal(x,38,6)` | `safe_cast(x as numeric)` |
| `split_part(x,' - ',1)` | `split(x,' - ')[safe_offset(0)]` |
| `'FY' \|\| year` | `concat('FY', cast(year as string))` |

All casting lives in `macros/to_num.sql` — the only file that knows which
warehouse this is. Keep it that way.

## Visualisation

`library-viz/` is an Observable Framework site reading two CSVs exported from
the marts into `src/data/`. Data is baked in at build time; the site never
queries BigQuery at runtime.

Palette has five colours with fixed meanings across every chart: sage = print,
clay = CDs and DVDs, blue = digital, sand = passes and kits, plum = anything
about sharing between libraries. **A colour never changes meaning between
charts.** Every figure caption states what one mark represents.

## Commands

```bash
# regenerate CSVs from the workbooks (fails loudly on an unknown column)
python convert.py raw_data/xlsx raw_data/csv

# build and test everything, in dependency order
cd dbt_transformation/mass_lib
dbt build --profiles-dir .

# the site
cd library-viz && npm run dev
```

`dbt build` is preferred over `dbt run` + `dbt test`: it stops at the first
failing test instead of building marts on top of broken staging.

## Verification after any change

```sql
select fiscal_year, count(*)
from `dbt_krupali_marts.fct_library_year`
group by 1 order by 1;
-- 369, 369, 369, 367, 367, 367
```

Format totals, if the numbers need checking against a known-good state:
FY2020 print = 28,344,059 · FY2025 digital = 19,288,008.