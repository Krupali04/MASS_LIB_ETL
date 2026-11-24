# Massachusetts Library Data Portal

An interactive dashboard showing how Massachusetts's public libraries were used from **2020 to 2025**, based on the yearly reports every public library files with the Massachusetts Board of Library Commissioners (MBLC).

## What the dashboard shows

The dashboard has six sections, each answering one question.

1. **Overview.** Libraries lent **72.6 million items** in 2025, up 11% on the year before. Borrowing has grown every year since the 2020–21 pandemic closures. Boston, Cambridge and Newton are the busiest libraries.
2. **What people borrow.** Digital borrowing (ebooks, audiobooks, streaming) has **doubled** since 2020 and is now a third of all loans. Printed books grew too, while DVDs and CDs fell by more than a third.
3. **Sharing between libraries.** Libraries sent each other **6.7 million items** in 2025. Some mostly give, others mostly borrow.
4. **Networks.** Libraries in a regional network lend **nearly seven times** as much per resident as independent ones.
5. **Underserved and underused.** About half of libraries have low use. Most of them (144) are **short of staff, not short of visitors**.
6. **Town size.** Small towns borrow more per person: about **8 items a year**, against 3 in large cities.

You can filter by year, network, town size or library, and click any library to highlight it in every chart.

*Figures are for the default view: all libraries, with "all years" averaged or totalled.*

## How the data was prepared

- **Collected** six yearly Excel reports from MBLC, covering about 370 libraries a year.
- **Standardised** them with **Python**, because column names and layouts changed from year to year.
- **Stored** them in **Google BigQuery** and cleaned and combined them with **dbt**:
  - removed statewide summary rows that would otherwise look like one giant library
  - kept "No data" as blank, not zero
  - linked libraries that were renamed
  - flagged one population typo in the source data
- **Recovered** each library's staffing and opening hours from the ratios MBLC publishes. These power the underserved vs underused analysis.
- **Recalculated** "items per resident" the same way for every year, because the state changed its method in 2021. The state's original figures are kept alongside.
- **Checked** automatically that each year has the right number of libraries (369 for 2020–22, 367 for 2023–25 after two closures) and no stray summary rows.
- **Built** the dashboard with **Observable Framework** and **Observable Plot**.

**Tools:** Excel · Python · Google BigQuery · dbt · Observable Framework and Observable Plot · Git

## Project layout

```
convert.py                     Excel reports → clean CSVs
dbt_transformation/mass_lib/   cleaning, combining and testing (dbt)
library-viz/                   the dashboard (Observable Framework)
```

The raw MBLC spreadsheets are not included in this repository. They are published by the Massachusetts Board of Library Commissioners.

## Run the dashboard locally

Requires Node.js 18 or later.

```bash
cd library-viz
npm install
npm run dev
```

Then open the address shown in the terminal (usually http://127.0.0.1:3000).
