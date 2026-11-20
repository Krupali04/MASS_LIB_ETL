"""xlsx -> BigQuery-safe CSV. Identical snake_case header on all six files."""
import csv, re, sys
from pathlib import Path
import pandas as pd

CANONICAL = {
 "location":"location_raw","library_network":"network_code",
 "municipal_population":"municipal_population","municipal_population_group":"municipal_population_group",
 "library_population":"library_population","library_population_group":"library_population_group",
 "total_circ_per_capita":"circ_per_capita_published","total_circ_per_hour_open":"circ_per_hour_open_published",
 "total_circ_per_fte":"circ_per_fte_published",
 "total_circulation_per_non_custodial_fte":"circ_per_noncustodial_fte_published",
 "direct_circ":"direct_circ","total_circ_activity":"total_circ_activity",
 "total_electronic_collection_usage":"electronic_collection_usage",
 "ill_received":"ill_received","ill_provided":"ill_provided",
 "total_nonresident_circulation":"nonresident_circ",
 "total_print_books_circulation":"print_books_circ",
 "total_print_periodicals_newspapers_other_print_serials_circulation":"print_serials_circ",
 "total_physical_audio_circulation":"physical_audio_circ",
 "total_physical_video_circulation":"physical_video_circ",
 "total_ebooks_circulation":"ebook_circ",
 "total_downloadable_audio_circulation":"downloadable_audio_circ",
 "total_downloadable_video_circulation":"downloadable_video_circ",
 "total_materials_in_electronic_format_circulation":"electronic_format_circ",
 "materials_in_microforms_circulated":"microform_circ","miscellaneous":"misc_circ",
 "total_non_print_circulation":"nonprint_circ",
 "total_circulation_print_nonprint":"total_circ_published",
}
OUT = ["location_raw","network_code","municipal_population","municipal_population_group",
 "library_population","library_population_group","circ_per_capita_published",
 "circ_per_hour_open_published","circ_per_fte_published","circ_per_noncustodial_fte_published",
 "direct_circ","total_circ_activity","electronic_collection_usage","ill_received","ill_provided",
 "nonresident_circ","print_books_circ","print_serials_circ","physical_audio_circ",
 "physical_video_circ","ebook_circ","downloadable_audio_circ","downloadable_video_circ",
 "electronic_format_circ","microform_circ","misc_circ","nonprint_circ","total_circ_published"]

def slug(h):
    s = str(h).split("=",1)[0]
    s = re.sub(r"\bc\d+\s+not\s+c\d+\b"," ",s,flags=re.I)
    s = re.sub(r"\(\s*e\.?\s*g\.?[^)]*\)?"," ",s,flags=re.I).lower()
    return re.sub(r"_+","_",re.sub(r"[^a-z0-9]+","_",s)).strip("_")

src, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
for p in sorted(src.glob("*.xlsx")):
    yr = p.name[:4]
    df = pd.read_excel(p, dtype=object).dropna(how="all").dropna(how="all", axis=1)
    ren, bad = {}, []
    for c in df.columns:
        k = slug(c)
        if k in CANONICAL: ren[c] = CANONICAL[k]
        else: bad.append((c,k))
    if bad:
        sys.exit(f"[{yr}] unmapped: {bad}")
    df = df.rename(columns=ren)
    for c in OUT:
        if c not in df.columns: df[c] = None
    df = df[OUT]
    df.insert(0,"fiscal_year",yr)
    f = out / f"circulation_{yr}.csv"
    df.to_csv(f, index=False, quoting=csv.QUOTE_MINIMAL, lineterminator="\n", encoding="utf-8")
    libs = df.location_raw.astype(str).str.contains(" - ", regex=False).sum()
    print(f"  {f.name}  {len(df)} rows ({libs} libraries + {len(df)-libs} summary)")