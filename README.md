<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>John Dave Benedict Isidro — BI Developer</title>
<meta name="description" content="Business Intelligence Developer and Analytics Engineer. Dashboards, ETL, workflow automation, and data quality.">
<style>
*{box-sizing:border-box;margin:0;padding:0}
:root{
  --paper:#FBFAF7;--ink:#1F2A33;--muted:#6B7780;--line:#E6E3DC;--soft:#F2F0EA;
  --accent:#4A6B82;--sage:#7E9A82;--clay:#B07A66;
  --mono:'SFMono-Regular',Consolas,'Liberation Mono',Menlo,monospace;
  --sans:'Inter','Helvetica Neue',Arial,sans-serif;
}
html{scroll-behavior:smooth}
body{font-family:var(--sans);background:var(--paper);color:var(--ink);line-height:1.6;
  font-size:16px;-webkit-font-smoothing:antialiased}
.wrap{max-width:920px;margin:0 auto;padding:0 28px}
.mono{font-family:var(--mono);font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}

/* top bar */
.topbar{position:sticky;top:0;background:rgba(251,250,247,.88);backdrop-filter:blur(8px);
  border-bottom:1px solid var(--line);z-index:10}
.topbar .wrap{display:flex;justify-content:space-between;align-items:center;height:58px}
.topbar .name{font-weight:700;font-size:15px;letter-spacing:-.01em}
.topbar nav{display:flex;gap:22px}
.topbar nav a{font-size:13px;color:var(--muted)}
.topbar nav a:hover{color:var(--ink);text-decoration:none}
@media(max-width:640px){.topbar nav{display:none}}

/* hero */
.hero{padding:78px 0 30px}
.hero .role{margin-bottom:20px}
.hero h1{font-size:46px;line-height:1.05;font-weight:800;letter-spacing:-.025em;margin-bottom:20px}
.hero h1 .em{color:var(--accent)}
.hero .lede{font-size:18px;color:#3a4750;max-width:680px;margin-bottom:26px}
.hero .links{display:flex;gap:10px;flex-wrap:wrap}
.btn{display:inline-flex;align-items:center;gap:7px;border:1px solid var(--line);background:#fff;
  padding:9px 15px;border-radius:8px;font-size:13.5px;color:var(--ink);font-weight:500}
.btn:hover{border-color:var(--accent);color:var(--accent);text-decoration:none}
.btn.primary{background:var(--accent);color:#fff;border-color:var(--accent)}
.btn.primary:hover{background:#3d5a6e;color:#fff}

/* metric strip */
.metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:1px;background:var(--line);
  border:1px solid var(--line);border-radius:12px;overflow:hidden;margin:34px 0 10px}
.metric{background:#fff;padding:20px 18px}
.metric .v{font-size:26px;font-weight:800;letter-spacing:-.02em}
.metric .l{font-size:12.5px;color:var(--muted);margin-top:3px;line-height:1.35}
@media(max-width:640px){.metrics{grid-template-columns:repeat(2,1fr)}}

/* sections */
section{padding:48px 0;border-top:1px solid var(--line)}
.shead{display:flex;align-items:baseline;gap:14px;margin-bottom:26px}
.shead h2{font-size:22px;font-weight:750;letter-spacing:-.02em}
.shead .idx{font-family:var(--mono);font-size:12px;color:var(--accent)}

/* projects */
.proj{border:1px solid var(--line);border-radius:12px;padding:22px 24px;margin-bottom:16px;background:#fff;transition:.15s}
.proj:hover{border-color:var(--accent);box-shadow:0 2px 14px rgba(31,42,51,.05)}
.proj .ptop{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;margin-bottom:8px}
.proj h3{font-size:18px;font-weight:700;letter-spacing:-.01em}
.proj .tag{font-family:var(--mono);font-size:10.5px;color:var(--muted);white-space:nowrap;padding-top:4px}
.proj p{color:#3a4750;font-size:15px;margin-bottom:14px}
.proj .stack{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:15px}
.chip{font-family:var(--mono);font-size:10.5px;background:var(--soft);color:#52606a;padding:3px 9px;border-radius:5px}
.proj .plinks{display:flex;gap:14px;font-size:13.5px}
.proj .plinks .live{font-weight:600}

/* experience timeline */
.exp{display:grid;grid-template-columns:130px 1fr;gap:20px;padding:18px 0;border-bottom:1px solid var(--soft)}
.exp:last-child{border-bottom:none}
.exp .when{font-family:var(--mono);font-size:12px;color:var(--muted);padding-top:3px}
.exp h3{font-size:16.5px;font-weight:700}
.exp .co{color:var(--accent);font-size:14px;margin-bottom:8px}
.exp ul{list-style:none;margin-top:6px}
.exp li{font-size:14.5px;color:#3a4750;padding-left:16px;position:relative;margin-bottom:5px}
.exp li::before{content:'';position:absolute;left:0;top:10px;width:5px;height:5px;border-radius:50%;background:var(--sage)}
@media(max-width:640px){.exp{grid-template-columns:1fr;gap:6px}}

/* skills + certs grid */
.cols{display:grid;grid-template-columns:1fr 1fr;gap:30px}
@media(max-width:640px){.cols{grid-template-columns:1fr}}
.skillgroup{margin-bottom:18px}
.skillgroup .gl{font-family:var(--mono);font-size:11px;color:var(--muted);margin-bottom:7px}
.skillgroup .gv{display:flex;gap:7px;flex-wrap:wrap}
.cert{padding:9px 0;border-bottom:1px solid var(--soft);font-size:14.5px}
.cert:last-child{border:none}
.cert .ci{font-family:var(--mono);font-size:10.5px;color:var(--muted);display:block;margin-top:1px}

footer{border-top:1px solid var(--line);padding:34px 0 50px;text-align:center}
footer .links{display:flex;gap:16px;justify-content:center;margin-bottom:12px}
footer p{font-size:12.5px;color:var(--muted)}
</style></head><body>

<div class="topbar"><div class="wrap">
  <span class="name">John Dave Benedict Isidro</span>
  <nav><a href="#work">Projects</a><a href="#experience">Experience</a><a href="#skills">Skills</a><a href="#contact">Contact</a></nav>
</div></div>

<div class="wrap">
  <header class="hero">
    <div class="role mono">Business Intelligence Developer · Analytics Engineer · Automation</div>
    <h1>I build reporting systems that<br><span class="em">people can actually trust.</span></h1>
    <p class="lede">BI Developer and Analytics Engineer with experience across investment operations, BPO, and logistics. I turn messy operational data into scalable dashboards, automated pipelines, and AI-assisted workflows that cut manual effort and strengthen data governance.</p>
    <div class="links">
      <a class="btn primary" href="#work">View projects</a>
      <a class="btn" href="https://linkedin.com/in/daveisidro">LinkedIn</a>
      <a class="btn" href="https://github.com/legianaz">GitHub</a>
      <a class="btn" href="mailto:jdaveisidro@gmail.com">Email</a>
    </div>
    <div class="metrics"><div class="metric"><div class="v" style="color:var(--accent)">1–3 hrs</div><div class="l">saved per reporting cycle by replacing manual MBR/QBR decks</div></div><div class="metric"><div class="v" style="color:var(--ink)">4</div><div class="l">BI / data roles across investment, BPO, and logistics</div></div><div class="metric"><div class="v" style="color:var(--sage)">100%</div><div class="l">analytics uptime via automated secured-report extraction</div></div><div class="metric"><div class="v" style="color:var(--clay)">5+</div><div class="l">years building dashboards, pipelines, and automations</div></div></div>
  </header>

  <section id="work">
    <div class="shead"><span class="idx">01</span><h2>Selected Projects</h2></div>
    <div class="proj">
      <div class="ptop"><h3>Operations Intelligence Suite</h3><span class="tag">BI · 4-page dashboard</span></div>
      <p>A role-based dashboard suite (Executive, Operations, Team Leader, Employee) built on a relational model, with consistent KPI color language and a single config block for thresholds. Each page answers one question for one audience.</p>
      <div class="stack"><span class="chip">HTML/JS</span><span class="chip">Chart.js</span><span class="chip">Relational model</span><span class="chip">KPI design</span></div>
      <div class="plinks"><a class="live" href="ops_suite/ops_suite.html">View demo &rarr;</a><a href="https://github.com/legianaz">Source</a></div>
    </div><div class="proj">
      <div class="ptop"><h3>BPO KPI Validation Tool</h3><span class="tag">BI testing · QA</span></div>
      <p>A universal validation tool for the testing stage of the BI lifecycle. Upload a source CSV, auto-map columns, and independently recalculate SLA, CSAT, AHT, FCR and more, with full working and a match/mismatch cross-check against the dashboard.</p>
      <div class="stack"><span class="chip">HTML/JS</span><span class="chip">PapaParse</span><span class="chip">Data validation</span></div>
      <div class="plinks"><a class="live" href="kpi_validator/kpi_validator.html">View demo &rarr;</a><a href="https://github.com/legianaz">Source</a></div>
    </div><div class="proj">
      <div class="ptop"><h3>Investment Document Classifier</h3><span class="tag">Automation · Python</span></div>
      <p>Reads downloaded fund documents (capital calls, K-1s, distribution notices), identifies the type by signature keywords, detects the date, and renames to a standard convention, with a preview-then-apply step that keeps a human in the loop.</p>
      <div class="stack"><span class="chip">Python</span><span class="chip">pdfplumber</span><span class="chip">Rule-based NLP</span></div>
      <div class="plinks"><a class="live" href="doc_classifier_rulebased/README_doc_classifier.md">View files &rarr;</a><a href="https://github.com/legianaz">Source</a></div>
    </div><div class="proj">
      <div class="ptop"><h3>Local ETL Pipeline</h3><span class="tag">Data engineering · PowerShell</span></div>
      <p>A six-stage ETL pipeline (extract, clean, validate, transform, aggregate, load) that turns a raw CSV into an HTML report, fully local with a validation gate that stops bad data before it reaches a dashboard.</p>
      <div class="stack"><span class="chip">PowerShell</span><span class="chip">ETL</span><span class="chip">Data governance</span></div>
      <div class="plinks"><a class="live" href="etl_pipeline/README_pipeline.md">View files &rarr;</a><a href="https://github.com/legianaz">Source</a></div>
    </div><div class="proj">
      <div class="ptop"><h3>Data Profiler</h3><span class="tag">Data quality · PowerShell</span></div>
      <p>A health-check tool that profiles any CSV: completeness, types, duplicates, outliers via the IQR method, invalid emails and dates, with an HTML and Excel report. The artifact a BI developer reaches for before trusting a dataset.</p>
      <div class="stack"><span class="chip">PowerShell</span><span class="chip">Statistics</span><span class="chip">Reporting</span></div>
      <div class="plinks"><a class="live" href="data_profiler/README_profiler.md">View files &rarr;</a><a href="https://github.com/legianaz">Source</a></div>
    </div>
    <p class="mono" style="margin-top:14px">Demo links open the built tools · source links point to github.com/legianaz</p>
  </section>

  <section id="experience">
    <div class="shead"><span class="idx">02</span><h2>Experience</h2></div>
    <div class="exp"><div class="when">2026–Present</div>
      <div><h3>Data Management Analyst</h3><div class="co">Connext</div><ul><li>Manage and track financial investment data across hedge funds, private equity, and real estate to ensure completeness and reporting accuracy.</li><li>Work directly with clients and stakeholders to monitor document delivery, resolve missing-data issues, and maintain investment record integrity.</li><li>Oversee end-to-end tracking workflows so every required financial document is accounted for and aligned with operational timelines.</li></ul></div></div><div class="exp"><div class="when">2024–2025</div>
      <div><h3>BI Developer / Analytics Engineer</h3><div class="co">SupportNinja</div><ul><li>Built executive dashboards in Power BI and Looker Studio, replacing manual MBR/QBR decks and cutting reporting prep by 1–3 hours per cycle.</li><li>Developed Python + Selenium automation to extract secured BI reports when database access was restricted, ensuring uninterrupted analytics.</li><li>Designed API-based ingestion integrating BigQuery and operational systems into scalable reporting models, and SQL data models for enterprise pipelines.</li><li>Supported SIT, UT, and UAT testing in JIRA across Agile cycles to ensure reporting accuracy and deployment readiness.</li></ul></div></div><div class="exp"><div class="when">2021–2024</div>
      <div><h3>Engineering Ops Tech / Data Quality Analyst</h3><div class="co">Flexport</div><ul><li>Analyzed large operational datasets to monitor KPI performance including accuracy, timeliness, and zero-tolerance compliance metrics.</li><li>Built performance dashboards in Looker and advanced spreadsheets, giving Operations and Engineering real-time visibility.</li><li>Identified recurring data and process issues through trend analysis, delivering actionable insights to leadership.</li></ul></div></div><div class="exp"><div class="when">2018–2021</div>
      <div><h3>Full Stack Developer</h3><div class="co">Freelance</div><ul><li>Designed and built full-stack web applications with .NET (C#, VB), MySQL, and JavaScript, delivering systems to client requirements.</li><li>Architected database schemas, backend logic, and responsive front-ends for end-to-end delivery.</li></ul></div></div>
  </section>

  <section id="skills">
    <div class="shead"><span class="idx">03</span><h2>Skills &amp; Certifications</h2></div>
    <div class="cols">
      <div><div class="skillgroup"><div class="gl">Data & Analytics</div><div class="gv"><span class="chip">SQL</span><span class="chip">Data Modeling</span><span class="chip">ETL</span><span class="chip">Data Warehousing</span><span class="chip">Data Integration</span></div></div><div class="skillgroup"><div class="gl">BI Tools</div><div class="gv"><span class="chip">Power BI</span><span class="chip">Looker Studio</span></div></div><div class="skillgroup"><div class="gl">Cloud & Platforms</div><div class="gv"><span class="chip">BigQuery</span><span class="chip">Google Cloud Storage</span><span class="chip">Azure Synapse</span><span class="chip">Azure Blob</span><span class="chip">Event Hubs</span></div></div><div class="skillgroup"><div class="gl">Programming & Automation</div><div class="gv"><span class="chip">Python</span><span class="chip">JavaScript</span><span class="chip">PHP</span><span class="chip">Selenium</span><span class="chip">API Integration</span><span class="chip">Workflow Automation</span></div></div><div class="skillgroup"><div class="gl">Workflow & Governance</div><div class="gv"><span class="chip">JIRA</span><span class="chip">Agile (SIT/UT/UAT)</span><span class="chip">Data Governance</span><span class="chip">Risk & Vulnerability</span></div></div></div>
      <div>
        <div class="skillgroup"><div class="gl">Certifications</div></div>
        <div class="cert">Microsoft Power BI Developer & Architect<span class="ci">Specialization</span></div><div class="cert">Data Analytics Essentials<span class="ci">Cisco</span></div><div class="cert">Google Analytics<span class="ci">Certificate</span></div><div class="cert">Google Data Studio<span class="ci">Certificate</span></div><div class="cert">IBM Cybersecurity Analyst<span class="ci">Certificate</span></div>
        <div style="margin-top:18px" class="skillgroup">
          <div class="gl">Education</div>
          <div style="font-size:14.5px;margin-top:4px">Tarlac State University<span class="ci mono" style="display:block;color:var(--muted);margin-top:2px">B.S. — Major in Web Development</span></div>
        </div>
      </div>
    </div>
  </section>

  <section id="contact">
    <div class="shead"><span class="idx">04</span><h2>Get in touch</h2></div>
    <p style="font-size:17px;max-width:600px;margin-bottom:20px">Open to Business Intelligence and Analytics Engineering roles. The fastest way to reach me is email or LinkedIn.</p>
    <div class="links">
      <a class="btn primary" href="mailto:jdaveisidro@gmail.com">jdaveisidro@gmail.com</a>
      <a class="btn" href="https://linkedin.com/in/daveisidro">linkedin.com/in/daveisidro</a>
      <a class="btn" href="https://github.com/legianaz">github.com/legianaz</a>
    </div>
  </section>
</div>

<footer><div class="wrap">
  <div class="links mono">
    <a href="https://linkedin.com/in/daveisidro">LinkedIn</a>
    <a href="https://github.com/legianaz">GitHub</a>
    <a href="mailto:jdaveisidro@gmail.com">Email</a>
  </div>
  <p>Built as a static HTML page · no trackers ·  John Dave Benedict Isidro</p>
</div></footer>

</body></html>
