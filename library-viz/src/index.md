---
title: Massachusetts library dashboard
theme: air
style: dashboard.css
toc: false
sidebar: false
pager: false
---

```js
// ---------------------------------------------------------------
// Data: exported from the BigQuery marts (dataset `marts`).
//   library_year.csv        ← fct_library_year joined to dim_library
//   circulation_format.csv  ← fct_circulation
//   years.csv               ← dim_year (per-year data notes)
// ---------------------------------------------------------------
const raw = FileAttachment("data/library_year.csv").csv({typed: true});
const formatsRaw = FileAttachment("data/circulation_format.csv").csv({typed: true});
const yearsMeta = FileAttachment("data/years.csv").csv({typed: true});
```

```js
// ================= constants =================
// Editorial library palette: warm charcoal ink on ivory paper, forest / burgundy / antique gold accents.
const C = {
  ink: "#2A2723", inkSoft: "#5E584E", inkFaint: "#8C8576", grid: "#E9E2D2", rule: "#CFC5B0", paper: "#FBF9F4", vellum: "#EFE8DA",
  forest: "#2F5D50", forestDeep: "#1D3D34", forestLight: "#C9D8CF", forestMid: "#4F7D6F", teal: "#4E8C82",
  gold: "#C0954F", goldDeep: "#8A6A35", burgundy: "#8E3B46", burgundyDeep: "#6E2A34", slate: "#5D6F8E", sage: "#8FA678",
  neutral: "#EFE8DA", barBg: "#E3EADF"
};
const memberColor = {"In network": C.forest, "Not in network": C.gold};
const members = ["In network", "Not in network"];

const years = [...new Set(raw.map((d) => d.fiscal_year))].sort((a, b) => a - b);
const firstYear = years[0], lastYear = years.at(-1);
const noteOf = new Map(yearsMeta.map((d) => [d.fiscal_year, d.data_note || null]));

// Population size groups are bins of service_population (library population,
// or municipal population in FY2020 when library population wasn't reported).
const popGroups = ["Under 5k", "5k–15k", "15k–35k", "35k–75k", "75k+"];
const popGroupOf = (p) => p == null ? null
  : p < 5000 ? popGroups[0] : p < 15000 ? popGroups[1] : p < 35000 ? popGroups[2] : p < 75000 ? popGroups[3] : popGroups[4];

const networkLabel = {
  "C/WMARS": "C/W MARS", "SAILS": "SAILS", "MLN": "Minuteman (MLN)", "MVLC": "Merrimack Valley (MVLC)",
  "CLAMS": "CLAMS", "OCLN": "Old Colony (OCLN)", "NOBLE": "NOBLE", "MASSCAT": "MassCat",
  "MBLN": "Metro Boston (MBLN)", "NOT A NETWORK": "Not in a network"
};

// Format categories from fct_circulation.format_code
const catOf = {
  print_books: "Print books", print_serials: "Magazines & newspapers",
  physical_audio: "Audio on disc", physical_video: "Video on disc",
  ebook: "E-content", downloadable_audio: "E-content", downloadable_video: "E-content", electronic_format: "E-content",
  microform: "Other", misc: "Other"
};
const cats = ["Print books", "Magazines & newspapers", "Audio on disc", "Video on disc", "E-content", "Other"];
const catColor = {
  "Print books": C.forest, "Magazines & newspapers": C.slate, "Audio on disc": C.gold,
  "Video on disc": C.burgundy, "E-content": C.teal, "Other": C.sage
};
const catHelp = {
  "Print books": "Printed books", "Magazines & newspapers": "Print serials",
  "Audio on disc": "Music CDs and audiobooks on CD", "Video on disc": "DVDs and Blu-ray",
  "E-content": "Ebooks, downloadable audio and video, other electronic formats",
  "Other": "Microform and miscellaneous items (kits, passes, devices)"
};

// ================= icons (inline SVG, stroke = currentColor) =================
const ICONS = {
  overview: '<rect x="3" y="3" width="7.5" height="7.5" rx="2"/><rect x="13.5" y="3" width="7.5" height="7.5" rx="2"/><rect x="3" y="13.5" width="7.5" height="7.5" rx="2"/><rect x="13.5" y="13.5" width="7.5" height="7.5" rx="2"/>',
  formats: '<path d="M4 19.5V5a2 2 0 0 1 2-2h13v15H6a2 2 0 0 0-2 2 2 2 0 0 0 2 2h13"/><path d="M8 7h7"/>',
  sharing: '<path d="M4 8h14l-3.5-3.5"/><path d="M20 16H6l3.5 3.5"/>',
  networks: '<circle cx="12" cy="5" r="2.5"/><circle cx="5" cy="19" r="2.5"/><circle cx="19" cy="19" r="2.5"/><path d="M12 7.5v4l-5.2 5.6M12 11.5l5.2 5.6"/>',
  access: '<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.8"/>',
  size: '<path d="M3 21V10l5-3.5 5 3.5v11"/><path d="M13 21v-8h8v8"/><path d="M2 21h20M7 13h2M7 17h2M16 17h2"/>',
  book: '<path d="M2 5.5C4.5 4 8 4 11 5.5v14C8 18 4.5 18 2 19.5z"/><path d="M22 5.5C19.5 4 16 4 13 5.5v14c3-1.5 6.5-1.5 9 0z"/>',
  person: '<circle cx="12" cy="8" r="3.8"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
  out: '<path d="M7 17 17 7"/><path d="M9 7h8v8"/>',
  in: '<path d="M17 7 7 17"/><path d="M15 17H7V9"/>',
  library: '<path d="M2.5 9.5 12 4l9.5 5.5"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8M3 20.5h18"/>',
  up: '<path d="M4 17 10 11l4 4 6-7"/><path d="M15 8h5v5"/>',
  down: '<path d="M4 7l6 6 4-4 6 7"/><path d="M15 16h5v-5"/>',
  star: '<path d="m12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
  alert: '<path d="M12 3 2.5 20h19z"/><path d="M12 10v4M12 17.2v.1"/>',
  check: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.7 2.7L16.5 9.5"/>'
};
const ico = (name) => {
  const span = document.createElement("span");
  span.className = "ico";
  span.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true">${ICONS[name] ?? ""}</svg>`;
  return span;
};

// ================= helpers =================
const has = (v) => v != null && !Number.isNaN(v);
function ratio(data, num, den, scale = 1) {
  let n = 0, d = 0, k = 0;
  for (const r of data) {
    const a = num(r), b = den(r);
    if (has(a) && has(b) && b > 0) { n += a; d += b; k++; }
  }
  return k ? (n / d) * scale : null;
}
function sumReported(data, key) {
  const rep = data.filter((d) => has(d[key]));
  return rep.length ? d3.sum(rep, (d) => d[key]) : null;
}
function fmtNum(v, digits = 1) {
  if (!has(v)) return "No data";
  const a = Math.abs(v);
  if (a >= 1e9) return (v / 1e9).toFixed(digits) + "B";
  if (a >= 1e6) return (v / 1e6).toFixed(digits) + "M";
  if (a >= 1e4) return (v / 1e3).toFixed(digits) + "K";
  if (a >= 100) return d3.format(",.0f")(v);
  return d3.format(",.2~f")(v);
}
const fmtRate = (v) => has(v) ? d3.format(",.1f")(v) : "No data";
const fmtPct = (v) => has(v) ? d3.format(".1%")(v) : "No data";
const fmtPct0 = (v) => has(v) ? d3.format(".0%")(v) : "n/a";
const fmtChg = (v) => has(v) ? (v > 0 ? "+" : "") + d3.format(".1%")(v) : "n/a";
const fy = (y) => `FY${y}`;
const noteLine = (y) => noteOf.get(y) ? `\nNote: ${noteOf.get(y)}` : "";
const trunc = (s, n = 26) => s && s.length > n ? s.slice(0, n - 1) + "…" : s;
const jitter = (id) => parseInt(String(id).slice(0, 8), 16) / 0xffffffff - 0.5;

const plotStyle = {fontFamily: "Inter, system-ui, sans-serif", fontSize: "12px", color: C.inkSoft, background: "transparent", overflow: "visible"};
const gridY = () => Plot.gridY({stroke: C.grid, strokeOpacity: 1});
const gridX = () => Plot.gridX({stroke: C.grid, strokeOpacity: 1});

// Legends are built in JS: Framework markdown can't interpolate inside attribute values.
const legend = (items) => html`<div class="legend">${items.map(([label, color, opacity = 1, help = ""]) =>
  html`<span title=${help}><i style=${{background: color, opacity}}></i>${label}</span>`)}</div>`;
const memberLegend = () => legend(members.map((m) => [m, memberColor[m]]));
const empty = (msg = "No libraries match these filters.") => html`<div class="empty">${msg}</div>`;

function onPick(chart, fn) {
  chart.addEventListener("click", () => { if (chart.value) fn(chart.value); });
  return chart;
}
```

```js
// ================= one row per library per year =================
// Needham's municipal population is typed as 225 in the MBLC source (real ~32,000),
// so per-capita figures for that row are dropped (same rule as the rest of the site).
const rows = raw.map((d) => {
  const networked = d.network_code !== "NOT A NETWORK";
  return {
    ...d,
    library_id: String(d.library_id),
    networked,
    member: networked ? "In network" : "Not in network",
    network: networkLabel[d.network_code] ?? d.network_code,
    pop_group: popGroupOf(d.service_population),
    pcOk: !has(d.circ_per_capita_recomputed) || d.circ_per_capita_recomputed < 100
  };
});
const networkCodes = [...new Set(rows.map((d) => d.network_code))].filter((c) => c !== "NOT A NETWORK").sort();
const libraryNames = [...new Set(rows.map((d) => d.library_name))].sort();
```

```js
// ================= tabs + filter inputs =================
// [key, label, section number, catalogue subject line]
const TABS = [
  ["overview", "Overview", "1", "General summary"],
  ["formats", "What people borrow", "2", "Collections by format"],
  ["sharing", "Sharing between libraries", "3", "Interlibrary loan"],
  ["networks", "Networks", "4", "Library networks"],
  ["access", "Underserved & underused", "5", "Access & resources"],
  ["size", "Town size", "6", "Communities by population"]
];
const tabMeta = new Map(TABS.map(([key, label, roman, subject]) => [key, {label, roman, subject}]));

function tabBar(items) {
  const keys = items.map((d) => d[0]);
  const fromHash = location.hash.slice(1);
  let value = keys.includes(fromHash) ? fromHash : keys[0];
  const buttons = items.map(([key, label, roman]) => {
    const b = html`<button type="button" role="tab"><span class="num">${roman}</span><span>${label}</span></button>`;
    b.dataset.key = key;
    return b;
  });
  const root = html`<nav class="tabs" role="tablist">${buttons}</nav>`;
  const paint = () => buttons.forEach((b) => b.setAttribute("aria-selected", String(b.dataset.key === value)));
  buttons.forEach((b) => (b.onclick = () => {
    if (b.dataset.key === value) return;
    value = b.dataset.key;
    paint();
    history.replaceState(null, "", "#" + value);
    root.dispatchEvent(new Event("input", {bubbles: true}));
  }));
  Object.defineProperty(root, "value", {get: () => value, set: (v) => { value = v; paint(); }});
  paint();
  return root;
}

function multiSelect(options, {label, format = String} = {}) {
  const boxes = options.map((o) => Object.assign(html`<input type="checkbox">`, {__v: o}));
  const summary = html`<summary>All networks</summary>`;
  const clear = html`<button type="button" class="ms-clear">Clear selection</button>`;
  const details = html`<details class="ms">${summary}<div class="ms-menu">${boxes.map((b, i) => html`<label class="ms-opt">${b}<span>${format(options[i])}</span></label>`)}${clear}</div></details>`;
  const root = html`<div class="ms-wrap"><span class="ms-label">${label}</span>${details}</div>`;
  const update = () => {
    const v = root.value;
    summary.textContent = v.length === 0 ? "All networks" : v.length === 1 ? format(v[0]) : `${v.length} networks`;
  };
  Object.defineProperty(root, "value", {
    get: () => boxes.filter((b) => b.checked).map((b) => b.__v),
    set: (v) => { boxes.forEach((b) => (b.checked = v.includes(b.__v))); update(); }
  });
  root.addEventListener("input", update);
  clear.onclick = () => { root.value = []; root.dispatchEvent(new Event("input", {bubbles: true})); };
  document.addEventListener("click", (e) => { if (!details.contains(e.target)) details.open = false; });
  return root;
}

const tabInput = tabBar(TABS);
const yearInput = Inputs.select(["All years", ...years], {label: "Year", value: "All years", format: (y) => typeof y === "number" ? fy(y) : y});
const memberInput = Inputs.radio(["All", "In network", "Not in network"], {value: "All"});
const networkInput = multiSelect(networkCodes, {label: "Network", format: (c) => networkLabel[c] ?? c});
const popInput = Inputs.select(["All sizes", ...popGroups], {label: "Town size", value: "All sizes"});
const searchInput = Inputs.text({placeholder: "Search a library or town…", datalist: libraryNames, autocomplete: "off"});

// segmented toggles used inside cards
const catModeInput = Inputs.radio(["Items", "% share"], {value: "Items"});
const illModeInput = Inputs.radio(["Per library", "Total"], {value: "Per library"});
const netMetricInput = Inputs.radio(["Circulation", "Sharing"], {value: "Circulation"});
```

```js
const tab = Generators.input(tabInput);
```

```js
const year = Generators.input(yearInput);
```

```js
const member = Generators.input(memberInput);
```

```js
const nets = Generators.input(networkInput);
```

```js
const popGroup = Generators.input(popInput);
```

```js
const search = Generators.input(searchInput);
```

```js
const catMode = Generators.input(catModeInput);
```

```js
const illMode = Generators.input(illModeInput);
```

```js
const netMetric = Generators.input(netMetricInput);
```

```js
// ================= cross-highlight state =================
// {kind: "library", key: library_id, label} or {kind: "network", key: network_code, label}
const highlight = Mutable(null);
const setHighlight = (h) => {
  const cur = highlight.value;
  highlight.value = h && cur && h.kind === cur.kind && h.key === cur.key ? null : h;
};
const forceHighlight = (h) => { highlight.value = h; };
```

```js
const resetButton = html`<button class="reset" type="button">Reset</button>`;
resetButton.onclick = () => {
  for (const [el, v] of [[yearInput, "All years"], [memberInput, "All"], [networkInput, []], [popInput, "All sizes"], [searchInput, ""]]) {
    el.value = v;
    el.dispatchEvent(new Event("input", {bubbles: true}));
  }
  forceHighlight(null);
};
```

```js
const isHi = (d) => highlight != null && (highlight.kind === "library" ? d.library_id === highlight.key : d.network_code === highlight.key);
const hiActive = highlight != null;
const hiChip = highlight
  ? html`<span class="chip" title=${highlight.label}>★ ${trunc(highlight.label, 20)}<button type="button" title="Clear highlight" onclick=${() => forceHighlight(null)}>×</button></span>`
  : html`<span></span>`;
```

```js
// ================= filtered data =================
const q = search.trim().toLowerCase();
const keep = (d) =>
  (member === "All" || d.member === member) &&
  (nets.length === 0 || nets.includes(d.network_code)) &&
  (popGroup === "All sizes" || d.pop_group === popGroup) &&
  (!q || `${d.library_name} ${d.town_name}`.toLowerCase().includes(q));

const fRows = rows.filter(keep);                              // all years, filtered
const isAll = year === "All years";
const focusYear = isAll ? lastYear : year;
const snapRows = isAll ? fRows : fRows.filter((d) => d.fiscal_year === year);
const snapLabel = isAll ? `FY${firstYear}–FY${lastYear}` : fy(year);
const snapRateLabel = isAll ? `average FY${firstYear}–FY${lastYear}` : fy(year);
const nShowing = new Set(snapRows.map((d) => d.library_id)).size;

// Collapse library-year rows to one row per library.
// For "All years", rates are pooled across years (sum ÷ sum) and volumes are totals.
function perLibrary(data) {
  return d3.groups(data, (d) => d.library_id).map(([id, v]) => {
    const last = d3.greatest(v, (d) => d.fiscal_year);
    const pop = d3.mean(v, (d) => d.service_population);
    const netRows = v.filter((d) => has(d.net_ill));
    return {
      library_id: id, library_name: last.library_name, town_name: last.town_name,
      network_code: last.network_code, network: last.network, member: last.member,
      pop, pop_group: popGroupOf(pop), years: v.length,
      circ: sumReported(v, "total_circ_activity"),
      circ_pc: ratio(v, (d) => d.pcOk ? d.total_circ_activity : null, (d) => d.service_population),
      fte_per_k: ratio(v, (d) => d.pcOk ? d.staff_fte : null, (d) => d.service_population, 1000),
      hours: d3.mean(v, (d) => d.weekly_hours_open),
      loaned: sumReported(v, "ill_provided"),
      received: sumReported(v, "ill_received"),
      net: netRows.length ? d3.sum(netRows, (d) => d.net_ill) : null,
      missing: v.filter((d) => !has(d.total_circ_activity)).length
    };
  });
}
const snapLibs = perLibrary(snapRows);
```

```js
// ================= yearly series (always FY2020–FY2025, filtered) =================
const yearly = years.map((y) => {
  const v = fRows.filter((d) => d.fiscal_year === y);
  return {
    year: y,
    circ: sumReported(v, "total_circ_activity"),
    pc: ratio(v, (d) => d.pcOk ? d.total_circ_activity : null, (d) => d.service_population),
    loaned: sumReported(v, "ill_provided"),
    received: sumReported(v, "ill_received"),
    libs: v.length,
    missingCirc: v.filter((d) => !has(d.total_circ_activity)).length
  };
});
const curY = yearly.find((d) => d.year === focusYear);
const prevY = yearly.find((d) => d.year === focusYear - 1);
const change = (key) => has(curY?.[key]) && has(prevY?.[key]) && prevY[key] !== 0 ? (curY[key] - prevY[key]) / prevY[key] : null;
```

```js
// ================= shared building blocks =================
function deltaPill(chg, vs) {
  if (!has(chg)) return html`<span class="pill flat">no ${vs} data</span>`;
  const cls = chg > 0.0005 ? "up" : chg < -0.0005 ? "down" : "flat";
  const arrow = cls === "up" ? "▲" : cls === "down" ? "▼" : "•";
  return html`<span class=${"pill " + cls}>${arrow} ${fmtChg(chg).replace("+", "")}</span>`;
}

// Overview KPIs are drawn as library catalogue cards, each with a Dewey-style call number
// (027.4 = public libraries, 025.6 = circulation & interlibrary loan).
const callNo = {circ: "027.4 · CIRC", pc: "027.4 · PER CAP", loaned: "025.6 · ILL OUT", received: "025.6 · ILL IN", libs: "027.4 · LIBR"};
function kpiCard({label, key, fmt, tone, help}, i = 0) {
  const v = curY?.[key];
  const series = yearly.filter((d) => has(d[key]));
  const color = {forest: C.forest, teal: C.teal, slate: C.slate, gold: C.gold, burgundy: C.burgundy}[tone] ?? C.forest;
  const spark = Plot.plot({
    width: 240, height: 38, margin: 4, style: plotStyle,
    x: {axis: null, domain: [firstYear, lastYear]}, y: {axis: null, zero: false, nice: false},
    marks: [
      Plot.areaY(series, {x: "year", y: key, fill: color, fillOpacity: 0.1, curve: "monotone-x"}),
      Plot.lineY(series, {x: "year", y: key, stroke: color, strokeWidth: 1.6, curve: "monotone-x"}),
      Plot.dot(series.filter((d) => d.year === focusYear), {x: "year", y: key, r: 3, fill: color, stroke: C.paper, strokeWidth: 1.5}),
      Plot.tip(series, Plot.pointerX({x: "year", y: key, title: (d) => `${fy(d.year)}: ${fmt(d[key])}${noteLine(d.year)}`}))
    ]
  });
  return html`<article class="card-cat" title=${help}>
    <div class="callno mono-label"><span>${callNo[key] ?? ""}</span><span>No. ${String(i + 1).padStart(2, "0")}</span></div>
    <div class="label">${label}</div>
    <div class="value">${fmt(v)}</div>
    <div class="meta">${deltaPill(change(key), fy(focusYear - 1))}<span>vs ${fy(focusYear - 1)}</span></div>
    <div class="spark">${spark}</div>
  </article>`;
}

// One entry in a tab's ledger strip of key numbers.
const toneClass = {teal: "forest", coral: "burgundy", peach: "gold", blue: "", lavender: "", forest: "forest", burgundy: "burgundy", gold: "gold"};
const stat = ({value, label, icon, tone = "", tag = ""}) =>
  html`<div class=${"entry tone-" + (toneClass[tone] ?? tone)}>
    <div class="mono-label">${ico(icon)}<span>${tag}</span></div>
    <div class="v">${value}</div><div class="l">${label}</div>
  </div>`;
const ledger = (...entries) => html`<div class="ledger">${entries}</div>`;

// Placeholder a figure cell fills in later (see "figure slots" below).
const slot = (name) => html`<div class="slot" data-slot=${name}></div>`;

// Replace an element's content without the page jumping: hold the current height
// until the new content (e.g. a resize() chart, which draws a frame later) has rendered.
function swapInPlace(host, node, hold = 600) {
  const h = host.offsetHeight;
  if (h) host.style.minHeight = h + "px";
  host.replaceChildren(node);
  clearTimeout(host._release);
  host._release = setTimeout(() => (host.style.minHeight = ""), hold);
}

// A numbered figure. `open: true` drops the panel box for a lighter editorial layout.
function card({fig = "", title, question, control = null, legendEl = null, chart, foot = null, span = 6, tall = false, clickable = false, open = false}) {
  return html`<figure class=${"panel span-" + span + (open ? " open" : "")}>
    <div class="panel-head"><div><div class="mono-label fig">Fig. ${fig}</div><h3>${title}</h3><p class="q">${question}</p></div>${control ?? ""}</div>
    ${legendEl ?? ""}
    <div class=${"chart" + (tall ? " tall" : "") + (clickable ? " clickable" : "")}>${chart}</div>
    ${foot ? html`<figcaption>${foot}</figcaption>` : ""}
  </figure>`;
}

// A tab page: chapter heading (folio + headline), key numbers, figures, reading notes.
function page({icon, headline, text, top, body, howto}) {
  const meta = tabMeta.get(icon);
  return html`<div class="view">
    <header class="chapter">
      <div class="folio"><span class="mono-label">Section</span><span class="roman">${meta.roman}</span><span class="mono-label">${meta.label}</span></div>
      <div class="body">
        <div class="mono-label kicker">Subject — ${meta.subject} · ${nShowing} libraries · ${snapLabel}</div>
        <h2>${headline}</h2>
        <p class="dek">${text}</p>
      </div>
    </header>
    ${top}
    <div class="grid12">${body}</div>
    <div class="ornament"><span>✦ ✦ ✦</span></div>
    <section class="notes"><div class="mono-label">Reading notes</div><ol>${howto.map((h) => html`<li>${h}</li>`)}</ol></section>
  </div>`;
}
```

```js
// ================= OVERVIEW =================

const busiest = snapLibs.filter((d) => has(d.circ)).sort((a, b) => b.circ - a.circ).slice(0, 10);

function overviewView() {
  const chg = change("circ");
  const dir = !has(chg) ? "" : chg >= 0 ? "up" : "down";
  return page({
    icon: "overview", eyebrow: "Overview",
    headline: html`<em>${fmtNum(curY?.circ)}</em> items borrowed in ${fy(focusYear)}${has(chg) ? html`, ${dir} <em>${fmtPct0(Math.abs(chg))}</em> on the year before` : ""}`,
    text: `${nShowing} libraries in view. Use the tabs above to explore what people borrow, how libraries share, and where use is low. Click any library to highlight it across every tab.`,
    top: html`<div class="catalog">
      ${kpiCard({label: "Total circulation", key: "circ", fmt: (v) => fmtNum(v), tone: "forest", help: "All items borrowed (total_circ_activity)"}, 0)}
      ${kpiCard({label: "Items per resident", key: "pc", fmt: fmtRate, tone: "teal", help: "Items borrowed ÷ population served"}, 1)}
      ${kpiCard({label: "Lent to other libraries", key: "loaned", fmt: (v) => fmtNum(v), tone: "slate", help: "Interlibrary loans provided (ill_provided)"}, 2)}
      ${kpiCard({label: "Borrowed from others", key: "received", fmt: (v) => fmtNum(v), tone: "gold", help: "Interlibrary loans received (ill_received)"}, 3)}
      ${kpiCard({label: "Libraries reporting", key: "libs", fmt: (v) => d3.format(",")(v), tone: "burgundy", help: "Libraries that filed a report that year"}, 4)}
    </div>`,
    body: [
      card({fig: "1.1", open: true, span: 7, title: "Items borrowed each year", question: "Has borrowing recovered since the pandemic?", chart: slot("A"),
        foot: `Highlighted bar = ${fy(focusYear)}. Hover a bar for details and data notes.`}),
      card({fig: "1.2", span: 5, title: "Busiest libraries", question: `Which libraries lend the most (${snapLabel}${isAll ? " total" : ""})?`, legendEl: memberLegend(), clickable: true,
        chart: slot("B")})
    ],
    howto: [
      "Every number responds to the filters in the bar at the top. “All years” shows the latest year in the cards and six-year totals in the rankings.",
      "Arrows compare the selected year with the year before it. FY2020 has no earlier year in this data.",
      "“Per resident” divides items borrowed by the population each library serves, so big and small towns can be compared fairly.",
      "FY2020 includes about 3.5 months of pandemic closures, so the dip that year is not a trend."
    ]
  });
}
```

```js
// ================= FORMATS =================
const keySet = new Set(fRows.map((d) => d.library_id + "|" + d.fiscal_year));
const fFormats = formatsRaw.filter((d) => keySet.has(String(d.library_id) + "|" + d.fiscal_year));
const catYear = (() => {
  const roll = d3.rollup(fFormats, (v) => d3.sum(v, (d) => d.circulation), (d) => d.fiscal_year, (d) => catOf[d.format_code]);
  const out = [];
  for (const y of years) {
    const yr = roll.get(y);
    if (!yr) continue;
    const total = d3.sum(cats, (c) => yr.get(c) ?? 0);
    for (const c of cats) {
      const cur = yr.get(c) ?? 0;
      const prev = roll.get(y - 1)?.get(c);
      out.push({year: y, cat: c, value: cur, share: total ? cur / total : null, yoy: has(prev) && prev > 0 ? (cur - prev) / prev : null, total});
    }
  }
  return out;
})();
const yearTotals = d3.groups(catYear, (d) => d.year).map(([year, v]) => ({year, total: v[0].total, items: v}));
const catChange = cats.map((c) => {
  const a = catYear.find((d) => d.cat === c && d.year === firstYear)?.value;
  const b = catYear.find((d) => d.cat === c && d.year === lastYear)?.value;
  return {cat: c, first: a, last: b, change: has(a) && a > 0 && has(b) ? (b - a) / a : null};
}).sort((a, b) => (b.change ?? -Infinity) - (a.change ?? -Infinity))
  .map((d, i) => ({...d, col: i % 3, row: Math.floor(i / 3)}));
const catIndex = catYear.map((d) => {
  const base = catChange.find((c) => c.cat === d.cat);
  return {...d, col: base.col, row: base.row, index: has(base.first) && base.first > 0 ? (d.value / base.first) * 100 : null};
}).filter((d) => has(d.index));



function formatsView() {
  const ranked = catChange.filter((d) => has(d.change));
  const top = ranked[0], bottom = ranked.at(-1);
  const eShare = catYear.find((d) => d.cat === "E-content" && d.year === focusYear)?.share;
  return page({
    icon: "formats", eyebrow: "What people borrow",
    headline: top && bottom
      ? html`${top.cat} ${top.change >= 0 ? "grew" : "fell"} <em>${fmtPct0(Math.abs(top.change))}</em> since ${fy(firstYear)}, while ${bottom.cat.toLowerCase()} ${bottom.change >= 0 ? "grew" : "fell"} <em>${fmtPct0(Math.abs(bottom.change))}</em>`
      : "How the mix of formats has changed",
    text: "Libraries report what kind of item each loan was. This page shows how that mix has shifted from print and discs towards digital.",
    top: html`<div class="ledger">
      ${stat({tag: "Gain", value: top ? fmtChg(top.change) : "n/a", label: `${top?.cat ?? "—"}: fastest-growing format since ${fy(firstYear)}`, icon: "up", tone: "teal"})}
      ${stat({tag: "Loss", value: bottom ? fmtChg(bottom.change) : "n/a", label: `${bottom?.cat ?? "—"}: biggest decline since ${fy(firstYear)}`, icon: "down", tone: "coral"})}
      ${stat({tag: "Share", value: fmtPct0(eShare), label: `of itemised loans were e-content in ${fy(focusYear)}`, icon: "formats", tone: "blue"})}
    </div>`,
    body: [
      card({fig: "2.1", span: 6, title: "Format mix over time", question: `How has the mix of formats changed since ${fy(firstYear)}?`, control: catModeInput,
        legendEl: legend(cats.map((c) => [c, catColor[c], 1, catHelp[c]])), chart: slot("A"),
        foot: "Hover a year to see every category with its share and year-on-year change."}),
      card({fig: "2.2", span: 6, title: "Winners and losers", question: `Each panel tracks one format against its ${fy(firstYear)} level, from biggest growth to biggest decline.`,
        chart: slot("B"), foot: `Dashed line = ${fy(firstYear)} level. Above it means growth.`})
    ],
    howto: [
      "“E-content” groups ebooks, downloadable audio, streaming video and other electronic formats.",
      "Format totals only count loans libraries itemised by type, so they can be a little lower than total circulation.",
      "Switch the left chart to “% share” to compare the mix rather than the volume.",
      "MBLC does not report adult / young adult / children splits, so formats are the only category breakdown available."
    ]
  });
}
```

```js
// ================= SHARING =================
const illYear = years.flatMap((y) => members.flatMap((m) => {
  const v = fRows.filter((d) => d.fiscal_year === y && d.member === m);
  if (!v.length) return [];
  return [["Loaned", "ill_provided"], ["Received", "ill_received"]].map(([flow, k]) => {
    const rep = v.filter((d) => has(d[k]));
    const total = rep.length ? d3.sum(rep, (d) => d[k]) : null;
    return {year: y, member: m, flow, key: `${m} · ${flow}`, total, perLib: rep.length ? total / rep.length : null, n: rep.length, missing: v.length - rep.length};
  });
})).filter((d) => has(d.total));


const netLibs = snapLibs.filter((d) => has(d.net));
const netTop = (() => {
  const lenders = [...netLibs].sort((a, b) => b.net - a.net).slice(0, 15).filter((d) => d.net > 0);
  const borrowers = [...netLibs].sort((a, b) => a.net - b.net).slice(0, 15).filter((d) => d.net < 0);
  const ids = new Set(lenders.map((d) => d.library_id));
  return [...lenders, ...borrowers.filter((d) => !ids.has(d.library_id))].sort((a, b) => b.net - a.net);
})();


function sharingView() {
  const v = snapRows;
  const loanedIn = d3.sum(v.filter((d) => d.member === "In network"), (d) => d.ill_provided ?? 0);
  const loanedAll = d3.sum(v, (d) => d.ill_provided ?? 0);
  const topLender = netTop[0]?.net > 0 ? netTop[0] : null;
  return page({
    icon: "sharing", eyebrow: "Sharing between libraries",
    headline: html`Libraries lent each other <em>${fmtNum(curY?.loaned)}</em> items in ${fy(focusYear)}`,
    text: "Interlibrary loan (ILL) lets a patron borrow a book their own library doesn't own. This page shows who lends, who borrows, and how membership in a network changes that.",
    top: html`<div class="ledger">
      ${stat({tag: "Lent", value: fmtNum(curY?.loaned), label: `items lent to other libraries in ${fy(focusYear)} (${fmtChg(change("loaned"))} vs ${fy(focusYear - 1)})`, icon: "out", tone: "lavender"})}
      ${stat({tag: "Network share", value: loanedAll ? d3.format(".2%")(loanedIn / loanedAll) : "n/a", label: `of all lending came from network members (${snapLabel})`, icon: "networks", tone: "blue"})}
      ${stat({tag: "Top lender", value: topLender ? trunc(topLender.library_name, 24) : "—", label: topLender ? `biggest net lender: gave ${fmtNum(topLender.net)} more than it took` : "No net lenders in this selection", icon: "star", tone: "teal"})}
    </div>`,
    body: [
      card({fig: "3.1", span: 7, title: "Lending and borrowing by year", question: "Do networked libraries share more than independent ones, and is sharing growing?", control: illModeInput,
        legendEl: legend([["In network · lent", C.forest], ["In network · borrowed", C.forest, 0.45], ["Not in network · lent", C.gold], ["Not in network · borrowed", C.gold, 0.45]]),
        chart: slot("A")}),
      card({fig: "3.2", span: 5, title: "Who gives, who takes", question: `Top 15 net lenders and borrowers (${snapLabel}${isAll ? " total" : ""}). Click a bar to highlight.`, clickable: true,
        legendEl: legend([["Lends more than it borrows", C.teal], ["Borrows more", C.burgundy]]),
        chart: slot("B")})
    ],
    howto: [
      "“Lent” = interlibrary loans provided to other libraries. “Borrowed” = loans received from them.",
      "“Per library” divides by the number of libraries reporting, so the small group of independent libraries can be compared with the large networked group.",
      "Net = lent − borrowed. Large libraries with deep collections tend to be net lenders.",
      "Libraries that did not report ILL in a year are left out of that year and noted in the tooltip."
    ]
  });
}
```

```js
// ================= NETWORKS =================
const pcLibs = snapLibs.filter((d) => has(d.circ_pc));
const spread = members.map((m) => {
  const v = pcLibs.filter((d) => d.member === m).map((d) => d.circ_pc).sort(d3.ascending);
  return v.length ? {member: m, n: v.length, q1: d3.quantileSorted(v, 0.25), median: d3.quantileSorted(v, 0.5), q3: d3.quantileSorted(v, 0.75)} : null;
}).filter(Boolean);


const networkStats = d3.groups(snapRows, (d) => d.network_code).map(([code, v]) => ({
  network_code: code, label: networkLabel[code] ?? code, member: code === "NOT A NETWORK" ? "Not in network" : "In network",
  libs: new Set(v.map((d) => d.library_id)).size,
  circ_pc: ratio(v, (d) => d.pcOk ? d.total_circ_activity : null, (d) => d.service_population),
  ill_pc: ratio(v, (d) => d.pcOk && has(d.ill_provided) && has(d.ill_received) ? d.ill_provided + d.ill_received : null, (d) => d.service_population)
}));


function networksView() {
  const inN = spread.find((d) => d.member === "In network"), outN = spread.find((d) => d.member === "Not in network");
  const ratioMed = inN && outN && outN.median > 0 ? inN.median / outN.median : null;
  const best = networkStats.filter((d) => d.member === "In network" && has(d.circ_pc)).sort((a, b) => b.circ_pc - a.circ_pc)[0];
  return page({
    icon: "networks", eyebrow: "Networks",
    headline: has(ratioMed)
      ? html`Network libraries see <em>${d3.format(".1f")(ratioMed)}×</em> the use per resident of independent libraries`
      : "How network membership relates to use",
    text: "Most Massachusetts libraries belong to a network that shares a catalogue and delivery van. A few stand alone. Compare the typical library in each group, then the networks themselves.",
    top: html`<div class="ledger">
      ${stat({tag: "Networked", value: inN ? fmtRate(inN.median) : "—", label: `median items per resident, network libraries (${inN?.n ?? 0})`, icon: "networks", tone: "blue"})}
      ${stat({tag: "Independent", value: outN ? fmtRate(outN.median) : "—", label: `median items per resident, independent libraries (${outN?.n ?? 0})`, icon: "library", tone: "peach"})}
      ${stat({tag: "Leading network", value: best ? best.label : "—", label: best ? `highest use per resident: ${fmtRate(best.circ_pc)} items` : "No networks in this selection", icon: "star", tone: "teal"})}
    </div>`,
    body: [
      card({fig: "4.1", span: 6, title: "Every library, by use per resident", question: "Is network membership linked to higher use? Each dot is a library; the shaded band holds the middle half.",
        legendEl: memberLegend(), clickable: true, chart: slot("A")}),
      card({fig: "4.2", span: 6, title: "Comparing networks", question: `Which networks get the most use per resident (${snapRateLabel})? Click a bar to highlight its libraries.`,
        control: netMetricInput, clickable: true, chart: slot("B")})
    ],
    howto: [
      "Each dot on the left is one library. The black line is the median: half the libraries are above it, half below.",
      "“Sharing” on the right counts items lent plus items borrowed between libraries, per resident.",
      "Clicking a network bar highlights its member libraries on every other tab.",
      "“Not in a network” libraries are few and mostly very small, so compare medians rather than totals."
    ]
  });
}
```

```js
// ================= ACCESS (underserved & underused) =================
const quadLibs = snapLibs.filter((d) => has(d.circ_pc) && has(d.fte_per_k) && d.circ_pc > 0 && d.fte_per_k > 0);
const medX = d3.median(quadLibs, (d) => d.fte_per_k);
const medY = d3.median(quadLibs, (d) => d.circ_pc);
const Q = {WW: "Well served & well used", WU: "Well served, underused", UB: "Underserved but busy", UU: "Underserved & underused"};
const QL = {[Q.UU]: "A", [Q.WU]: "B", [Q.UB]: "C", [Q.WW]: "—"};
const quadOf = (d) => d.fte_per_k >= medX ? (d.circ_pc >= medY ? Q.WW : Q.WU) : (d.circ_pc >= medY ? Q.UB : Q.UU);
const quadData = quadLibs.map((d) => ({...d, quadrant: quadOf(d)}));
const quadCount = (k) => quadData.filter((d) => d.quadrant === k).length;
const excludedQuad = snapLibs.length - quadLibs.length;


const concern = quadData.filter((d) => d.quadrant === Q.UU || d.quadrant === Q.WU)
  .map((d) => ({...d, circ_pc_r: Math.round(d.circ_pc * 10) / 10,
    network_short: d.network_code === "NOT A NETWORK" ? "None" : d.network_code === "MASSCAT" ? "MassCat" : d.network_code}));
const concernTable = Inputs.table(concern, {
  columns: ["library_name", "town_name", "pop", "network_short", "circ_pc_r", "quadrant"],
  header: {library_name: "Library", town_name: "Town", pop: "Pop.", network_short: "Network", circ_pc_r: "Use", quadrant: "Q"},
  format: {pop: (v) => fmtNum(v), circ_pc_r: (v) => fmtRate(v), quadrant: (v) => QL[v]},
  sort: "circ_pc_r", reverse: false, rows: 15, multiple: false, required: false, height: 452, layout: "fixed",
  width: {library_name: "30%", town_name: "20%", pop: "12%", network_short: "19%", circ_pc_r: "11%", quadrant: "8%"},
  align: {pop: "right", circ_pc_r: "right", quadrant: "center"}
});
```

```js
const tableSel = Generators.input(concernTable);
```

```js
if (tableSel) forceHighlight({kind: "library", key: tableSel.library_id, label: tableSel.library_name});
```

```js
function accessView() {
  return page({
    icon: "access", eyebrow: "Underserved & underused",
    headline: html`<em>${concern.length}</em> libraries have below-median use, and <em>${quadCount(Q.UU)}</em> of them are also thinly staffed`,
    text: "Low use can mean two different things: a library that is short of staff and open hours (underserved), or one with resources that people aren't using (underused). This page separates them.",
    top: html`<div class="ledger">
      ${stat({tag: "Quadrant A", value: d3.format(",")(quadCount(Q.UU)), label: "underserved & underused: few staff and low use", icon: "alert", tone: "coral"})}
      ${stat({tag: "Quadrant B", value: d3.format(",")(quadCount(Q.WU)), label: "well served, underused: staff are there, use is low", icon: "person", tone: "peach"})}
      ${stat({tag: "Quadrant C", value: d3.format(",")(quadCount(Q.UB)), label: "underserved but busy: high use despite thin staffing", icon: "check", tone: "teal"})}
    </div>`,
    body: [
      card({fig: "5.1", span: 7, title: "Resources vs use", question: "Each dot is a library, sized by population served. Shaded quadrants are the low-use ones.", legendEl: memberLegend(),
        tall: true, clickable: true, chart: slot("A"),
        foot: excludedQuad ? `${excludedQuad} libraries without staffing or circulation data are left out.` : null}),
      card({fig: "5.2", span: 5, title: "Libraries with low use", question: "Quadrants A and B. Use = items borrowed per resident. Sort by any column; click a row to highlight it everywhere.",
        chart: slot("B")})
    ],
    howto: [
      "Underserved = fewer staff per 1,000 residents than the median library in view. Underused = fewer items borrowed per resident than the median.",
      "MBLC does not publish holdings or spending, so staffing is the resource measure. It is recovered from MBLC's published circulation-per-staff ratio.",
      "The dashed lines are medians recalculated for your current filters, so a library's quadrant can change as you filter.",
      "Both axes use a log scale so that tiny and very large libraries fit on one chart."
    ]
  });
}
```

```js
// ================= TOWN SIZE =================
const sizeLibs = snapLibs.filter((d) => has(d.circ_pc) && d.pop_group);
const sizeMedians = popGroups.map((g, i) => {
  const v = sizeLibs.filter((d) => d.pop_group === g);
  return v.length ? {group: g, i, n: v.length, median: d3.median(v, (d) => d.circ_pc)} : null;
}).filter(Boolean);


const heat = popGroups.flatMap((g) => years.map((y) => {
  const v = fRows.filter((d) => d.fiscal_year === y && d.pop_group === g);
  // median library, to match the chart beside it (a pooled ratio would be dominated by the biggest library)
  const pc = d3.median(v.filter((d) => d.pcOk), (d) => d.circ_per_capita_recomputed) ?? null;
  return {group: g, year: y, pc, n: v.length, missing: v.filter((d) => !has(d.total_circ_activity)).length};
}));
heat.forEach((d) => {
  const prev = heat.find((p) => p.group === d.group && p.year === d.year - 1);
  d.yoy = has(d.pc) && has(prev?.pc) ? (d.pc - prev.pc) / prev.pc : null;
});


function sizeView() {
  const small = sizeMedians.find((d) => d.group === popGroups[0]);
  const large = sizeMedians.find((d) => d.group === popGroups.at(-1));
  const growth = popGroups.map((g) => {
    const a = heat.find((d) => d.group === g && d.year === firstYear)?.pc, b = heat.find((d) => d.group === g && d.year === lastYear)?.pc;
    return {g, chg: has(a) && has(b) && a > 0 ? (b - a) / a : null};
  }).filter((d) => has(d.chg)).sort((a, b) => b.chg - a.chg)[0];
  return page({
    icon: "size", eyebrow: "Town size",
    headline: small && large
      ? html`Libraries in towns under 5k lend <em>${fmtRate(small.median)}</em> items per resident, against <em>${fmtRate(large.median)}</em> in cities over 75k`
      : "How use per resident varies with town size",
    text: "Small towns often have one well-loved library close to everyone; cities spread use across more people and more alternatives. Here is how use per resident changes with population.",
    top: html`<div class="ledger">
      ${stat({tag: "Small towns", value: small ? fmtRate(small.median) : "—", label: `median items per resident, towns under 5k (${small?.n ?? 0} libraries)`, icon: "library", tone: "teal"})}
      ${stat({tag: "Large cities", value: large ? fmtRate(large.median) : "—", label: `median items per resident, cities over 75k (${large?.n ?? 0} libraries)`, icon: "size", tone: "blue"})}
      ${stat({tag: "Fastest growth", value: growth ? fmtChg(growth.chg) : "—", label: growth ? `${growth.g}: biggest growth in use per resident since ${fy(firstYear)}` : "Not enough data to compare years", icon: "up", tone: "lavender"})}
    </div>`,
    body: [
      card({fig: "6.1", span: 6, title: "Use per resident by town size", question: `Do smaller towns borrow more per person (${snapRateLabel})? Bars show the median; dots are libraries.`,
        legendEl: memberLegend(), clickable: true, chart: slot("A")}),
      card({fig: "6.2", span: 6, title: "Size group by year", question: `How did the typical library in each size group change from ${fy(firstYear)} to ${fy(lastYear)}? Darker = more use.`,
        tall: true, chart: slot("B")})
    ],
    howto: [
      "Town size uses the population each library serves. In FY2020, MBLC only reported municipal population, so that is used instead.",
      "Both charts use the median library in each group, so one very large library (like Boston) can't dominate its group.",
      "Very small towns can show high or volatile numbers because a few hundred residents make up the denominator.",
      "The selected year is outlined on the heatmap."
    ]
  });
}
```

<!-- Each chart is its own cell, so a toggle or highlight redraws only that chart. -->

```js
function yearBars(width) {
  const data = yearly.filter((d) => has(d.circ));
  const title = (d) => `${fy(d.year)}\n${fmtNum(d.circ)} items borrowed\n${has(d.pc) ? fmtRate(d.pc) + " per resident" : ""}` +
    (d.missingCirc ? `\n${d.missingCirc} libraries did not report` : "") + noteLine(d.year);
  const covid = data.find((d) => d.year === 2020);
  return Plot.plot({
    width, height: 380, marginLeft: 48, marginTop: 30, marginBottom: 30, style: plotStyle,
    x: {type: "band", domain: years, tickFormat: fy, label: null, tickSize: 0, padding: 0.32},
    y: {label: "Items borrowed", tickFormat: (d) => fmtNum(d, 0), nice: true},
    marks: [
      () => svg`<defs><linearGradient id="gBar" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="${C.forest}"/><stop offset="1" stop-color="${C.forestMid}"/></linearGradient></defs>`,
      gridY(),
      Plot.barY(data, {x: "year", y: "circ", rx: 2, fill: (d) => d.year === focusYear ? "url(#gBar)" : C.forestLight, title, tip: true}),
      Plot.text(data, {x: "year", y: "circ", text: (d) => fmtNum(d.circ), dy: -10, fill: (d) => d.year === focusYear ? C.forestDeep : C.inkSoft, fontWeight: 600, fontSize: 12.5}),
      covid ? Plot.text([covid], {x: "year", y: (d) => d.circ / 2, text: () => "Pandemic\nclosures", fill: C.forestDeep, fontSize: 11, fontWeight: 500, lineHeight: 1.2}) : null,
      Plot.ruleY([0], {stroke: C.rule})
    ]
  });
}
```

```js
function busiestChart(width) {
  const name = new Map(busiest.map((d) => [d.library_id, d.library_name]));
  const ml = Math.min(190, width * 0.42);
  const title = (d) => `${d.library_name} (${d.town_name})\n${d.network}\n${fmtNum(d.circ)} items borrowed (${snapLabel}${isAll ? " total" : ""})\n${fmtRate(d.circ_pc)} per resident`;
  const chart = Plot.plot({
    width, height: 380, marginLeft: ml, marginRight: 56, marginTop: 8, style: plotStyle,
    x: {axis: null, nice: true},
    y: {domain: busiest.map((d) => d.library_id), tickFormat: (id) => trunc(name.get(id), Math.floor(ml / 6.6)), label: null, tickSize: 0},
    marks: [
      Plot.barX(busiest, {x: "circ", y: "library_id", fill: (d) => memberColor[d.member], fillOpacity: hiActive ? 0.3 : 0.9, rx: 2, insetTop: 5, insetBottom: 5, title, tip: true}),
      Plot.barX(busiest.filter(isHi), {x: "circ", y: "library_id", fill: (d) => memberColor[d.member], stroke: C.ink, strokeWidth: 1.5, rx: 2, insetTop: 5, insetBottom: 5}),
      Plot.text(busiest, {x: "circ", y: "library_id", text: (d) => fmtNum(d.circ), dx: 6, textAnchor: "start", fill: C.ink, fontWeight: 600})
    ]
  });
  return onPick(chart, (d) => setHighlight({kind: "library", key: d.library_id, label: d.library_name}));
}
```

```js
function categoryArea(width) {
  const share = catMode === "% share";
  const order = [...cats].reverse();
  return Plot.plot({
    width, height: 380, marginLeft: 52, marginRight: 12, marginTop: 30, style: plotStyle,
    x: {domain: [firstYear, lastYear], ticks: years, tickFormat: fy, label: null},
    y: {label: share ? "Share of itemised circulation" : "Items borrowed", tickFormat: share ? (d) => d3.format(".0%")(d) : (d) => fmtNum(d, 0), nice: true},
    marks: [
      gridY(),
      Plot.areaY(catYear, Plot.stackY({x: "year", y: "value", z: "cat", fill: (d) => catColor[d.cat], fillOpacity: 0.88,
        order: cats, offset: share ? "normalize" : null, curve: "monotone-x", stroke: C.paper, strokeWidth: 0.75})),
      isAll ? null : Plot.ruleX([focusYear], {stroke: C.ink, strokeDasharray: "4,3", strokeOpacity: 0.6}),
      Plot.ruleX(yearTotals, Plot.pointerX({x: "year", stroke: C.ink, strokeOpacity: 0.35})),
      Plot.tip(yearTotals, Plot.pointerX({x: "year", frameAnchor: "top", title: (t) =>
        `${fy(t.year)} · total ${fmtNum(t.total)}\n` +
        order.map((c) => t.items.find((d) => d.cat === c)).map((d) =>
          `${d.cat}: ${fmtNum(d.value)} · ${fmtPct(d.share)} · ${has(d.yoy) ? fmtChg(d.yoy) + " YoY" : "no prior year"}`).join("\n") +
        noteLine(t.year)}))
    ]
  });
}
```

```js
function categoryMultiples(width) {
  const ext = d3.extent(catIndex, (d) => d.index);
  const lo = Math.min(ext[0] ?? 100, 100), hi = Math.max(ext[1] ?? 100, 100);
  const pad = (hi - lo) * 0.45 || 20;
  return Plot.plot({
    width, height: 400, marginLeft: 40, marginRight: 14, marginTop: 6, marginBottom: 28, style: plotStyle,
    fx: {axis: null, padding: 0.12}, fy: {axis: null, padding: 0.18},
    x: {domain: [firstYear, lastYear], ticks: [firstYear, lastYear], tickFormat: (d) => `FY${String(d).slice(2)}`, label: null, inset: 8},
    y: {domain: [lo - pad * 0.25, hi + pad], label: null, ticks: 3},
    marks: [
      Plot.frame({fill: "#F6F1E6", stroke: C.grid, rx: 2}),
      Plot.ruleY([100], {stroke: C.rule, strokeDasharray: "3,3"}),
      Plot.areaY(catIndex, {x: "year", y1: 100, y2: "index", fx: "col", fy: "row", z: "cat", fill: (d) => catColor[d.cat], fillOpacity: 0.12, curve: "monotone-x"}),
      Plot.lineY(catIndex, {x: "year", y: "index", fx: "col", fy: "row", z: "cat", stroke: (d) => catColor[d.cat], strokeWidth: 2.5, curve: "monotone-x"}),
      Plot.dot(catIndex.filter((d) => d.year === firstYear || d.year === lastYear), {x: "year", y: "index", fx: "col", fy: "row", fill: (d) => catColor[d.cat], r: 3.5, stroke: C.paper}),
      Plot.text(catChange, {fx: "col", fy: "row", frameAnchor: "top-left", dx: 8, dy: 8, lineAnchor: "top",
        text: (d) => `${d.cat}\n${has(d.change) ? fmtChg(d.change) : "No FY" + firstYear + " baseline"}`,
        fill: C.ink, fontWeight: 600, fontSize: 12, lineHeight: 1.3}),
      Plot.tip(catIndex, Plot.pointer({x: "year", y: "index", fx: "col", fy: "row", title: (d) =>
        `${d.cat} · ${fy(d.year)}\n${fmtNum(d.value)} items · ${fmtPct(d.share)} of total\n` +
        `${has(d.yoy) ? fmtChg(d.yoy) + " vs previous year" : "No prior year"}` + noteLine(d.year)}))
    ]
  });
}
```

```js
function illBars(width) {
  const key = illMode === "Per library" ? "perLib" : "total";
  const keys = members.flatMap((m) => ["Loaned", "Received"].map((f) => `${m} · ${f}`)).filter((k) => illYear.some((d) => d.key === k));
  const title = (d) => `${fy(d.year)} · ${d.member}\n${d.flow}: ${fmtNum(d.total)} total\n` +
    `${fmtNum(d.perLib)} per library (${d.n} libraries)` + (d.missing ? `\n${d.missing} libraries did not report` : "") + noteLine(d.year);
  const mk = (flow, opacity) => Plot.barY(illYear.filter((d) => d.flow === flow), {
    fx: "year", x: "key", y: key, fill: (d) => memberColor[d.member], fillOpacity: opacity, rx: 1.5, title, tip: true
  });
  return Plot.plot({
    width, height: 400, marginLeft: 52, marginTop: 30, style: plotStyle,
    fx: {tickFormat: fy, label: null, padding: 0.18},
    x: {axis: null, domain: keys, padding: 0.12},
    y: {label: illMode === "Per library" ? "Items per library" : "Items", tickFormat: (d) => fmtNum(d, 0), nice: true},
    marks: [
      gridY(),
      mk("Loaned", 1),
      mk("Received", 0.45),
      isAll ? null : Plot.barY(illYear.filter((d) => d.year !== focusYear), {fx: "year", x: "key", y: key, fill: C.paper, fillOpacity: 0.6}),
      Plot.ruleY([0], {stroke: C.rule})
    ]
  });
}
```

```js
function netChart(width) {
  // colour saturates at the 85th percentile so one outlier doesn't wash out the rest
  const m = d3.quantile(netTop, 0.85, (d) => Math.abs(d.net)) || 1;
  const name = new Map(netTop.map((d) => [d.library_id, d.library_name]));
  const ml = Math.min(180, width * 0.4);
  const title = (d) => `${d.library_name} (${d.town_name})\n${d.network}\nLent ${fmtNum(d.loaned)} · borrowed ${fmtNum(d.received)}\n` +
    `Net ${d.net > 0 ? "lender" : "borrower"}: ${d.net > 0 ? "+" : ""}${fmtNum(d.net)} (${snapLabel})` + (d.missing ? `\n${d.missing} year(s) not reported` : "");
  const chart = Plot.plot({
    width, height: Math.max(400, netTop.length * 15 + 60), marginLeft: ml, marginRight: 44, marginTop: 8, marginBottom: 46, style: plotStyle,
    x: {label: "← Borrows more    ·    Lends more →", labelAnchor: "center", tickFormat: (d) => fmtNum(d, 0), nice: true},
    y: {domain: netTop.map((d) => d.library_id), tickFormat: (id) => trunc(name.get(id), Math.floor(ml / 6.6)), label: null, tickSize: 0},
    color: {type: "linear", domain: [-m, 0, m], range: [C.burgundy, C.neutral, C.teal], clamp: true},
    marks: [
      gridX(),
      Plot.barX(netTop, {x: "net", y: "library_id", fill: "net", fillOpacity: hiActive ? 0.35 : 1, rx: 1.5, title, tip: true}),
      Plot.barX(netTop.filter(isHi), {x: "net", y: "library_id", fill: "net", stroke: C.ink, strokeWidth: 1.5, rx: 1.5}),
      Plot.text(netTop.filter((d) => d.net > 0), {x: "net", y: "library_id", text: (d) => fmtNum(d.net, 0), textAnchor: "start", dx: 4, fill: C.inkSoft, fontSize: 10.5}),
      Plot.text(netTop.filter((d) => d.net < 0), {x: "net", y: "library_id", text: (d) => fmtNum(d.net, 0), textAnchor: "end", dx: -4, fill: C.inkSoft, fontSize: 10.5}),
      Plot.ruleX([0], {stroke: "#A89F8C"})
    ]
  });
  return onPick(chart, (d) => setHighlight({kind: "library", key: d.library_id, label: d.library_name}));
}
```

```js
function beeswarm(width) {
  const fys = spread.map((d) => d.member);
  const data = pcLibs.filter((d) => fys.includes(d.member));
  const title = (d) => `${d.library_name} (${d.town_name})\n${d.network}\n${fmtRate(d.circ_pc)} items per resident (${snapRateLabel})\nPopulation ${fmtNum(d.pop)}`;
  const chart = Plot.plot({
    width, height: 400, marginLeft: 12, marginRight: 12, marginTop: 8, marginBottom: 40, style: plotStyle,
    fy: {axis: null, domain: fys, padding: 0.08},
    x: {label: "Items borrowed per resident →", nice: true},
    marks: [
      gridX(),
      Plot.barX(spread, {x1: "q1", x2: "q3", fy: "member", fill: (d) => memberColor[d.member], fillOpacity: 0.1}),
      Plot.dot(data, Plot.dodgeY("middle", {x: "circ_pc", fy: "member", r: 3, padding: 0.6, fill: (d) => memberColor[d.member],
        fillOpacity: hiActive ? 0.25 : 0.8, title, tip: true})),
      hiActive ? Plot.dot(data, Plot.dodgeY("middle", {x: "circ_pc", fy: "member", r: 3, padding: 0.6,
        fill: (d) => isHi(d) ? memberColor[d.member] : "none", stroke: (d) => isHi(d) ? C.ink : "none", strokeWidth: 1.8})) : null,
      Plot.ruleX(spread, {x: "median", fy: "member", stroke: C.ink, strokeWidth: 2}),
      Plot.text(spread, {fy: "member", frameAnchor: "top-left", dx: 4, dy: 4, fill: C.ink, fontWeight: 600, fontSize: 12, stroke: C.paper, strokeWidth: 4, text: (d) => `${d.member} · ${d.n} libraries`}),
      Plot.text(spread, {fy: "member", frameAnchor: "top-right", dx: -4, dy: 4, fill: C.inkSoft, fontSize: 11.5, text: (d) => `median ${fmtRate(d.median)}`})
    ]
  });
  return onPick(chart, (d) => setHighlight({kind: "library", key: d.library_id, label: d.library_name}));
}
```

```js
function networkBars(width) {
  const key = netMetric === "Circulation" ? "circ_pc" : "ill_pc";
  const fmtV = key === "circ_pc" ? fmtRate : (v) => d3.format(".2f")(v);
  const data = networkStats.filter((d) => has(d[key])).sort((a, b) => b[key] - a[key]);
  const title = (d) => `${d.label} · ${d.libs} libraries\nItems borrowed per resident: ${fmtRate(d.circ_pc)}\n` +
    `Items shared (lent + borrowed) per resident: ${has(d.ill_pc) ? d3.format(".2f")(d.ill_pc) : "No data"}\n${snapRateLabel}`;
  const chart = Plot.plot({
    width, height: Math.max(380, data.length * 36 + 60), marginLeft: 160, marginRight: 52, marginTop: 8, marginBottom: 46, style: plotStyle,
    x: {label: key === "circ_pc" ? "Items borrowed per resident →" : "Items shared between libraries, per resident →", nice: true},
    y: {domain: data.map((d) => d.label), label: null, tickSize: 0},
    marks: [
      gridX(),
      Plot.barX(data, {x: key, y: "label", fill: (d) => memberColor[d.member], fillOpacity: hiActive ? 0.35 : 1, rx: 2, insetTop: 5, insetBottom: 5, title, tip: true}),
      Plot.barX(data.filter((d) => highlight?.kind === "network" && d.network_code === highlight.key), {x: key, y: "label", fill: (d) => memberColor[d.member], stroke: C.ink, strokeWidth: 1.5, rx: 2, insetTop: 5, insetBottom: 5}),
      Plot.text(data, {x: key, y: "label", text: (d) => fmtV(d[key]), dx: 6, textAnchor: "start", fill: C.ink, fontWeight: 600, fontSize: 11.5}),
      Plot.ruleX([0], {stroke: "#A89F8C"})
    ]
  });
  return onPick(chart, (d) => setHighlight({kind: "network", key: d.network_code, label: d.label}));
}
```

```js
function quadrant(width) {
  const title = (d) => `${d.library_name} (${d.town_name})\n${d.network} · ${d.quadrant}\n` +
    `Staff per 1,000 residents: ${d3.format(".2f")(d.fte_per_k)}\nItems borrowed per resident: ${fmtRate(d.circ_pc)}\n` +
    `Open ${has(d.hours) ? d3.format(".0f")(d.hours) + " hrs/week" : "hours not reported"} · population ${fmtNum(d.pop)}`;
  const [x0, x1] = d3.extent(quadData, (d) => d.fte_per_k), [y0] = d3.extent(quadData, (d) => d.circ_pc);
  const xMin = x0 / 1.15, xMax = x1 * 1.15, yMin = y0 / 1.15;
  const corner = (anchor, text, color) => Plot.text([text], {frameAnchor: anchor, dx: anchor.endsWith("left") ? 10 : -10, dy: anchor.startsWith("top") ? 10 : -10,
    text: (d) => d, fill: color, fontWeight: 700, fontSize: 12, stroke: C.paper, strokeWidth: 5});
  const chart = Plot.plot({
    width, height: 470, marginLeft: 48, marginRight: 16, marginTop: 12, marginBottom: 42, style: plotStyle,
    x: {type: "log", label: "Staff per 1,000 residents (log scale) →", tickFormat: (d) => d3.format("~g")(d), ticks: 6},
    y: {type: "log", label: "↑ Items borrowed per resident (log scale)", tickFormat: (d) => d3.format("~g")(d), ticks: 6},
    r: {range: [2.5, 16]},
    marks: [
      // tinted quadrant backgrounds
      Plot.rect([0], {x1: () => medX, x2: () => xMax, y1: () => yMin, y2: () => medY, fill: C.burgundy, fillOpacity: 0.05}),
      Plot.rect([0], {x1: () => xMin, x2: () => medX, y1: () => yMin, y2: () => medY, fill: C.burgundy, fillOpacity: 0.09}),
      gridX(), gridY(),
      Plot.ruleX([medX], {stroke: "#A89F8C", strokeDasharray: "5,4"}),
      Plot.ruleY([medY], {stroke: "#A89F8C", strokeDasharray: "5,4"}),
      Plot.dot(quadData, {x: "fte_per_k", y: "circ_pc", r: "pop", fill: (d) => memberColor[d.member],
        fillOpacity: hiActive ? 0.18 : 0.6, stroke: C.paper, strokeWidth: 0.6, title, tip: true}),
      Plot.dot(quadData.filter(isHi), {x: "fte_per_k", y: "circ_pc", r: "pop", fill: (d) => memberColor[d.member], fillOpacity: 0.95, stroke: C.ink, strokeWidth: 2}),
      ...(width < 560
        ? [corner("top-right", "Well used", C.forest), corner("bottom-right", "B", C.goldDeep), corner("top-left", "C", C.forestDeep), corner("bottom-left", "A", C.burgundyDeep)]
        : [corner("top-right", Q.WW, C.forest), corner("bottom-right", "B · " + Q.WU, C.goldDeep), corner("top-left", "C · " + Q.UB, C.forestDeep), corner("bottom-left", "A · " + Q.UU, C.burgundyDeep)]),
      highlight?.kind === "library"
        ? Plot.text(quadData.filter(isHi), {x: "fte_per_k", y: "circ_pc", text: "library_name", dy: -14, fill: C.ink, fontWeight: 600, stroke: C.paper, strokeWidth: 4})
        : null
    ]
  });
  return onPick(chart, (d) => setHighlight({kind: "library", key: d.library_id, label: d.library_name}));
}
```

```js
function sizeChart(width) {
  const gi = (g) => popGroups.indexOf(g);
  const title = (d) => `${d.library_name} (${d.town_name})\n${d.network}\nPopulation ${fmtNum(d.pop)} · ${d.pop_group}\n${fmtRate(d.circ_pc)} items per resident`;
  const chart = Plot.plot({
    width, height: 400, marginLeft: 44, marginRight: 12, marginTop: 30, marginBottom: 46, style: plotStyle,
    x: {domain: [-0.6, popGroups.length - 0.4], ticks: d3.range(popGroups.length), tickFormat: (i) => popGroups[i], label: "Population served", labelAnchor: "center", tickSize: 0},
    y: {label: "↑ Items borrowed per resident", nice: true},
    marks: [
      gridY(),
      Plot.rectY(sizeMedians, {x1: (d) => d.i - 0.38, x2: (d) => d.i + 0.38, y: "median", fill: C.barBg, rx: 2,
        title: (d) => `${d.group}\nMedian ${fmtRate(d.median)} items per resident\n${d.n} libraries (${snapRateLabel})`, tip: true}),
      Plot.dot(sizeLibs, {x: (d) => gi(d.pop_group) + jitter(d.library_id) * 0.6, y: "circ_pc", r: 2.6,
        fill: (d) => memberColor[d.member], fillOpacity: hiActive ? 0.2 : 0.6, title, tip: true}),
      Plot.dot(sizeLibs.filter(isHi), {x: (d) => gi(d.pop_group) + jitter(d.library_id) * 0.6, y: "circ_pc", r: 5, fill: (d) => memberColor[d.member], stroke: C.ink, strokeWidth: 2}),
      Plot.link(sizeMedians, {x1: (d) => d.i - 0.38, x2: (d) => d.i + 0.38, y1: "median", y2: "median", stroke: C.forestDeep, strokeWidth: 2.5}),
      Plot.text(sizeMedians, {x: "i", y: "median", text: (d) => fmtRate(d.median), dy: -10, fill: C.forestDeep, fontWeight: 700, fontSize: 12.5, stroke: C.paper, strokeWidth: 4})
    ]
  });
  return onPick(chart, (d) => d.library_id && setHighlight({kind: "library", key: d.library_id, label: d.library_name}));
}
```

```js
function heatmap(width) {
  const vals = heat.filter((d) => has(d.pc)).map((d) => d.pc);
  const [lo, hi] = d3.extent(vals);
  const mid = d3.median(vals);
  const color = {type: "linear", domain: [lo ?? 0, mid ?? 1, hi ?? 2], range: ["#F1EBDC", "#8FB3A2", "#1F4A3F"]};
  const title = (d) => `${d.group} · ${fy(d.year)}\n` + (has(d.pc)
    ? `Median library: ${fmtRate(d.pc)} items per resident\n${d.n} libraries` + (d.missing ? ` (${d.missing} did not report)` : "") + `\n${has(d.yoy) ? fmtChg(d.yoy) + " vs previous year" : "No prior year"}`
    : "No libraries in this group") + noteLine(d.year);
  return html`<div>${Plot.plot({
    width, height: 410, marginLeft: 76, marginRight: 8, marginTop: 28, marginBottom: 8, style: plotStyle,
    x: {type: "band", domain: years, tickFormat: fy, label: null, axis: "top", tickSize: 0, padding: 0},
    y: {domain: [...popGroups].reverse(), label: null, tickSize: 0, padding: 0},
    color,
    marks: [
      Plot.cell(heat, {x: "year", y: "group", fill: C.vellum, inset: 2.5, rx: 2}),
      Plot.cell(heat.filter((d) => has(d.pc)), {x: "year", y: "group", fill: "pc", inset: 2.5, rx: 2, title, tip: true}),
      Plot.text(heat, {x: "year", y: "group", text: (d) => has(d.pc) ? fmtRate(d.pc) : "—", fontSize: 13, fontWeight: 600,
        fill: (d) => has(d.pc) && d.pc > (mid ?? 0) * 1.05 ? C.paper : C.ink}),
      isAll ? null : Plot.cell(heat.filter((d) => d.year === focusYear), {x: "year", y: "group", fill: "none", stroke: C.ink, strokeWidth: 2, inset: 1, rx: 3})
    ]
  })}${Plot.legend({color, label: "Median items borrowed per resident", width: Math.min(320, width), style: plotStyle, tickFormat: (d) => d3.format(".1f")(d)})}</div>`;
}
```

```js
// ================= masthead =================
// Simplified Massachusetts outline (projected lon/lat), drawn as a map plate.
const MA_PATH = "M7.4,174.0 L43.0,35.0 L161.5,38.0 L244.5,42.0 L334.8,44.0 L351.1,24.0 L370.4,10.0 L404.5,10.0 L406.0,34.0 L411.9,52.0 L437.1,52.0 L428.2,66.0 L400.0,80.0 L385.2,92.0 L374.8,110.0 L383.7,120.0 L395.6,124.0 L407.4,132.0 L422.3,144.0 L428.2,164.0 L432.6,182.0 L444.5,198.0 L446.0,224.0 L466.7,236.0 L496.3,236.0 L521.5,228.0 L526.0,208.0 L517.1,188.0 L508.2,174.0 L491.9,168.0 L499.3,176.0 L515.6,172.0 L528.9,190.0 L536.3,214.0 L534.9,248.0 L511.2,256.0 L474.1,260.0 L431.1,276.0 L434.1,252.0 L422.3,240.0 L407.4,258.0 L385.2,268.0 L360.0,284.0 L358.5,252.0 L348.2,234.0 L321.5,206.0 L321.5,180.0 L259.3,182.0 L111.1,178.0 L7.4,174.0Z M403.0,312.0 L422.3,290.0 L447.4,290.0 L459.3,304.0 L444.5,314.0 L403.0,312.0Z M490.4,328.0 L515.6,324.0 L531.9,332.0 L511.2,336.0 L490.4,328.0Z";
const nLibraries = new Set(rows.map((d) => d.library_id)).size;
const nNetworks = networkCodes.length;
const mapPlate = (() => {
  const el = document.createElement("div");
  el.className = "map-plate";
  // graticule lines at 42°N / 42.5°N and 72°W / 71°W in the same projection as MA_PATH
  el.innerHTML = `<svg viewBox="-10 -14 570 370" role="img" aria-label="Outline of Massachusetts">
    <path class="graticule" d="M-10,184 H560 M-10,84 H560 M230,-14 V356 M378,-14 V356"/>
    <text class="coord" x="-8" y="180">42°N</text><text class="coord" x="-8" y="80">42.5°N</text>
    <text class="coord" x="234" y="350">72°W</text><text class="coord" x="382" y="350">71°W</text>
    <path class="land" d="${MA_PATH}"/>
    <circle class="pin" cx="377" cy="110" r="4.5"/><text class="pin-label" x="352" y="104" text-anchor="end">Boston</text>
    <g transform="translate(520,40)"><circle class="compass" r="16"/><path class="compass" d="M0,-22 V22 M-22,0 H22"/><path d="M0,-14 L4,0 L0,3 L-4,0Z" fill="#B08D57"/><text class="compass-n" y="-26" text-anchor="middle">N</text></g>
  </svg>`;
  return el;
})();
```

<header class="masthead">
  <div>
    <div class="imprint"><span class="seal">MA</span><span class="mono-label">Commonwealth of Massachusetts · Board of Library Commissioners · Annual Reports</span></div>
    <h1>The Massachusetts <em>Library</em> Data Portal</h1>
    <p class="dek">What the Commonwealth's public libraries lend, how they share with one another, and where use runs low, drawn from six years of reports filed with the MBLC. Choose a section below; the filters apply throughout.</p>
    <div class="facts"><div><b>${d3.format(",")(nLibraries)}</b><span>public libraries</span></div><div><b>FY${firstYear}–${String(lastYear).slice(2)}</b><span>fiscal years</span></div><div><b>${nNetworks}</b><span>regional networks</span></div></div>
  </div>
  ${mapPlate}
</header>

<div class="toolbar">${tabInput}<div class="filters">${yearInput}<span class="sep"></span>${memberInput}${networkInput}${popInput}<span class="sep"></span>${searchInput}<div class="fb-right">${hiChip}${resetButton}</div></div></div>

```js
// Fixed host for the active tab; created once so swapping tabs/filters never removes it.
const viewHost = html`<div class="view-host"></div>`;
```

${viewHost}

```js
// Tab frame: headline, key numbers, figure frames with empty slots, notes.
// Depends on the tab and the filters only, not on chart toggles or highlights.
const viewNode = ({overview: overviewView, formats: formatsView, sharing: sharingView, networks: networksView, access: accessView, size: sizeView})[tab]();
if (viewHost._tab !== tab) viewNode.classList.add("enter");   // fade only when the tab changes
viewHost._tab = tab;
swapInPlace(viewHost, viewNode, 900);
```

```js
// Figure slot A (left chart of each tab). Re-runs only when its own chart changes.
{
  const draw = {
    overview: (w) => yearBars(w),
    formats: (w) => categoryArea(w),
    sharing: (w) => illYear.length ? illBars(w) : empty(),
    networks: (w) => pcLibs.length ? beeswarm(w) : empty(),
    access: (w) => quadData.length ? quadrant(w) : empty(),
    size: (w) => sizeLibs.length ? sizeChart(w) : empty()
  }[tab];
  swapInPlace(viewNode.querySelector('[data-slot="A"]'), resize(draw));
}
```

```js
// Figure slot B (right chart of each tab).
{
  const target = viewNode.querySelector('[data-slot="B"]');
  if (tab === "access") {
    // the table keeps its own sort/scroll state, so only insert it when it is new
    if (!target.contains(concernTable)) swapInPlace(target, html`<div class="table-wrap">${concernTable}</div>`);
  } else {
    const draw = {
      overview: (w) => busiest.length ? busiestChart(w) : empty(),
      formats: (w) => categoryMultiples(w),
      sharing: (w) => netTop.length ? netChart(w) : empty(),
      networks: (w) => networkBars(w),
      size: (w) => heatmap(w)
    }[tab];
    swapInPlace(target, resize(draw));
  }
}
```

<footer class="colophon"><div class="mono-label">Colophon</div><div>Source: Massachusetts Board of Library Commissioners annual reports, FY${firstYear}–FY${lastYear}, modelled in BigQuery (fct_library_year, fct_circulation, dim_year). Per-resident figures use population served. Needham's rows with a mistyped population (225) are excluded from per-resident figures.</div></footer>
