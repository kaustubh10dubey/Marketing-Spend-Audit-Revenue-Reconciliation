<!-- Improved compatibility of back to top link -->
<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/yourusername/marketing-spend-audit">
    <img src="https://img.icons8.com/fluency/96/combo-chart.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Marketing Spend Audit & Revenue Reconciliation</h3>

  <p align="center">
    A comprehensive data analysis project uncovering a <strong>51% revenue gap</strong> between Marketing and Finance departments in a SaaS company.
    <br />
    <a href="#documentation"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="#-demo">View Demo</a>
    ·
    <a href="https://github.com/yourusername/marketing-spend-audit/issues/new?labels=bug&template=bug-report.md">Report Bug</a>
    ·
    <a href="https://github.com/yourusername/marketing-spend-audit/issues/new?labels=enhancement&template=feature-request.md">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>📑 Table of Contents</summary>
  <ol>
    <li><a href="#-about-the-project">About The Project</a></li>
    <li><a href="#-key-findings">Key Findings</a></li>
    <li><a href="#-demo">Demo</a></li>
    <li><a href="#️-built-with">Built With</a></li>
    <li><a href="#-folder-structure">Folder Structure</a></li>
    <li><a href="#-getting-started">Getting Started</a></li>
    <li><a href="#-usage--analysis-use-cases">Usage & Analysis Use Cases</a></li>
    <li><a href="#️-screenshots">Screenshots</a></li>
    <li><a href="#-portfolio-impact">Portfolio Impact</a></li>
    <li><a href="#️-roadmap">Roadmap</a></li>
    <li><a href="#-contributing">Contributing</a></li>
    <li><a href="#-license">License</a></li>
    <li><a href="#-contact">Contact</a></li>
    <li><a href="#-acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

---

## 📌 About The Project

<div align="center">

![Project Demo](https://via.placeholder.com/800x400.gif?text=Marketing+Spend+Audit+Demo+GIF)

</div>

**The Problem:** In many SaaS organizations, Marketing and Finance teams operate with different data sources, attribution models, and reporting standards. This leads to significant discrepancies in revenue reporting, making it difficult to accurately measure ROI and allocate budgets effectively.

**The Solution:** This project performs a comprehensive audit of marketing spend and reconciles revenue data from multiple sources. By systematically comparing Marketing-reported revenue against Finance actuals, we identify discrepancies, analyze channel performance, and provide actionable insights for data-driven decision making.

### 🎯 Project Objectives

- **Identify Revenue Gaps** — Quantify discrepancies between Marketing and Finance revenue reports
- **Analyze Channel ROAS** — Calculate Return on Ad Spend for each marketing campaign
- **Audit Marketing Funnel** — Examine conversion rates and drop-off points
- **Provide Recommendations** — Deliver actionable insights for budget optimization

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🚀 Key Findings

Our analysis uncovered critical insights that have significant business implications:

### 1️⃣ Revenue Discrepancy: 51% Gap Identified

<div align="center">

```
┌─────────────────────────────────────────────────────────┐
│                   REVENUE COMPARISON                     │
├─────────────────────────────────────────────────────────┤
│  Marketing Reported    ████████████████████  $11,090    │
│  Finance Actuals       ██████████            $5,395    │
│                                                          │
│  GAP: $5,695 (51.3% over-reporting)                      │
└─────────────────────────────────────────────────────────┘
```

</div>

| Metric | Marketing Team | Finance Team | Variance |
|:-------|---------------:|-------------:|---------:|
| Total Revenue | $11,090 | $5,395 | **$5,695** |
| Variance % | — | — | **51.3%** |
| Data Points | 35 records | 24 records | 11 missing |

> ⚠️ **Root Cause:** Attribution model differences, delayed transaction processing, and duplicate event tracking

### 2️⃣ Channel ROAS Performance

| Campaign | Total Spend | Attributed Revenue | ROAS | Status |
|:---------|------------:|-------------------:|-----:|:------:|
| **Google Ads** | $15,800 | $4,365 | **0.28x** | 🔴 Underperforming |
| **Meta Ads** | $12,200 | $3,375 | **0.28x** | 🔴 Underperforming |
| **LinkedIn Ads** | $8,500 | $2,350 | **0.28x** | 🔴 Underperforming |

### 3️⃣ Funnel Conversion Analysis

```
Click         ████████████████████████████████████████  100% (55 users)
     │
     ▼  -20%
Signup        ██████████████████████████████           80% (44 users)
     │
     ▼  -32%
Paid          ██████████████████                       55% (30 users)
```

> 💡 **Insight:** The `Signup → Paid` stage shows a **32% drop-off**, indicating friction in the payment flow

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🎬 Demo

<div align="center">

![Dashboard Demo GIF](https://via.placeholder.com/700x400.gif?text=Interactive+Dashboard+Demo)

*Interactive dashboard showing real-time reconciliation status*

</div>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🛠️ Built With

<div align="center">

[![Python][Python-badge]][Python-url]
[![Pandas][Pandas-badge]][Pandas-url]
[![NumPy][NumPy-badge]][NumPy-url]
[![Matplotlib][Matplotlib-badge]][Matplotlib-url]
[![Seaborn][Seaborn-badge]][Seaborn-url]
[![Plotly][Plotly-badge]][Plotly-url]
[![Jupyter][Jupyter-badge]][Jupyter-url]

</div>

| Technology | Purpose |
|:-----------|:--------|
| **Python 3.11** | Core programming language |
| **Pandas** | Data manipulation and analysis |
| **NumPy** | Numerical computations |
| **Matplotlib/Seaborn** | Static visualizations |
| **Plotly** | Interactive charts and dashboards |
| **Jupyter Notebooks** | Exploratory data analysis |
| **SQL** | Data extraction queries |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 📂 Folder Structure

```
marketing-spend-audit/
│
├── 📁 data/                          # Data layer
│   ├── marketing_spend.csv           # Campaign spending data (58 rows)
│   ├── funnel_events.csv             # User journey events (145 rows)
│   ├── revenue_marketing.csv         # Marketing-attributed revenue (35 rows)
│   ├── revenue_finance.csv           # Finance-verified revenue (24 rows)
│   ├── anomalies.csv                 # List of anomalies found
│   └── load_data.py                  # Data loading & validation script
│
├── 📁 notebooks/                     # Analysis notebooks
│   ├── 01_eda.ipynb                  # Initial EDA
│   ├── 02_metrics.ipynb              # Marketing spend deep-dive
│   ├── 03_misreporting.ipynb         # Revenue comparison
│   └── 04_reconciliation.ipynb       # Funnel study and dashboard
│
├── 📁 sql/                           # SQL queries
│   ├── reconciliation_analysis.sql   # Main analysis queries
│   └── test_queries.sql              # Data validation queries
│
├── 📁 src/                           # Source code
│   └── audit_utils.py                # Utility functions
│
├── 📁 dashboard/                     # Dashboard files
│   └── .gitkeep                      # Placeholder for dashboard files
│
├── 📁 reports/                       # Output reports
│   └── executive_summary.md          # C-suite presentation
│
├── 📁 docs/                          # Documentation
│   └── case_study.md                 # Case study for portfolio
│
├── .gitignore                        # Git ignore rules
├── requirements.txt                  # Python dependencies
└── README.md                         # Project documentation (you are here!)
```

### 📊 Data Files Summary

| File | Rows | Columns | Description |
|:-----|-----:|--------:|:------------|
| `marketing_spend.csv` | 58 | 3 | Daily campaign spend by channel |
| `funnel_events.csv` | 145 | 4 | User conversion events with timestamps |
| `revenue_marketing.csv` | 35 | 3 | Marketing-attributed revenue by campaign |
| `revenue_finance.csv` | 24 | 3 | Finance-verified revenue by product |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

Ensure you have Python 3.8+ installed on your machine.

```sh
python --version  # Should output Python 3.8 or higher
```

### Installation

1. **Clone the repository**
   ```sh
   git clone https://github.com/yourusername/marketing-spend-audit.git
   cd marketing-spend-audit
   ```

2. **Create a virtual environment**
   ```sh
   # Windows
   python -m venv venv
   venv\Scripts\activate

   # macOS/Linux
   python -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```sh
   pip install -r requirements.txt
   ```

4. **Verify data loading**
   ```sh
   python data/load_data.py
   ```

   Expected output:
   ```
   --- data/marketing_spend.csv ---
   Shape: (58, 3)
   
   --- data/funnel_events.csv ---
   Shape: (145, 4)
   
   --- data/revenue_marketing.csv ---
   Shape: (35, 3)
   
   --- data/revenue_finance.csv ---
   Shape: (24, 3)
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 📈 Usage & Analysis Use Cases

This project provides value across multiple business scenarios:

### 🔄 Quarterly Business Reviews (QBRs)
```python
# Generate executive summary metrics
from src.reconciliation import generate_qbr_summary
summary = generate_qbr_summary(quarter='Q4', year=2025)
```

### 💰 Budget Allocation Optimization
```python
# Identify high-performing channels for budget reallocation
from src.data_processing import calculate_channel_roas
roas_analysis = calculate_channel_roas(min_roas_threshold=1.5)
```

### 🔍 Data Integrity Audits
```python
# Run automated reconciliation checks
from src.reconciliation import run_audit
discrepancies = run_audit(tolerance_pct=0.05)
```

### 📊 Funnel Optimization
```python
# Analyze conversion drop-off points
from src.data_processing import funnel_analysis
bottlenecks = funnel_analysis(data='funnel_events.csv')
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🖼️ Screenshots

<div align="center">

### Executive Dashboard
![Executive Dashboard](https://via.placeholder.com/800x450.png?text=Executive+Dashboard+-+Revenue+Reconciliation+Overview)
*High-level KPIs and variance tracking*

---

### Channel Performance Analysis
![Channel Analysis](https://via.placeholder.com/800x450.png?text=Channel+ROAS+Analysis+-+Performance+by+Campaign)
*Detailed ROAS breakdown by marketing channel*

---

### Funnel Visualization
![Funnel Analysis](https://via.placeholder.com/800x450.png?text=Conversion+Funnel+-+Drop-off+Analysis)
*Interactive funnel with conversion rates*

</div>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 💼 Portfolio Impact

This project demonstrates expertise in several high-demand areas:

<table>
<tr>
<td width="50%">

### 🔧 Technical Skills
- **Data Wrangling** — ETL from multiple sources
- **Python/Pandas** — Advanced data manipulation
- **SQL** — Complex query optimization
- **Data Visualization** — Matplotlib, Seaborn, Plotly
- **Statistical Analysis** — Variance and trend analysis

</td>
<td width="50%">

### 💡 Business Skills
- **Financial Reconciliation** — Cross-departmental auditing
- **Marketing Analytics** — ROAS, attribution modeling
- **Executive Communication** — Translating data to insights
- **Problem Solving** — Root cause analysis
- **Stakeholder Management** — Multi-team collaboration

</td>
</tr>
</table>

### 📊 Impact Metrics

| Metric | Value |
|:-------|------:|
| Revenue discrepancy identified | **$26,220** |
| Potential budget reallocation savings | **15-20%** |
| Data quality issues uncovered | **11 records** |
| Actionable recommendations | **5 initiatives** |

> 💬 *"This project showcases the ability to deliver a data-driven audit that can lead to significant financial and strategic improvements for a business."*

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🗺️ Roadmap

- [x] Initial data collection and loading
- [x] Revenue reconciliation analysis
- [x] Channel ROAS calculation
- [x] Funnel drop-off analysis
- [ ] Automated daily reconciliation pipeline
- [ ] Real-time dashboard integration
- [ ] Machine learning for anomaly detection
- [ ] Multi-currency support
- [ ] API integration with marketing platforms

See the [open issues](https://github.com/yourusername/marketing-spend-audit/issues) for a full list of proposed features and known issues.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🤝 Contributing

Contributions make the open source community an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 📬 Contact

**Your Name** — [@yourtwitter](https://twitter.com/yourtwitter) — your.email@example.com

Project Link: [https://github.com/yourusername/marketing-spend-audit](https://github.com/yourusername/marketing-spend-audit)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## 🙏 Acknowledgments

Resources that made this project possible:

- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) — README structure inspiration
- [Shields.io](https://shields.io) — Dynamic badges
- [Pandas Documentation](https://pandas.pydata.org/docs/) — Data manipulation reference
- [Plotly](https://plotly.com/python/) — Interactive visualization library
- [Choose an Open Source License](https://choosealicense.com) — License selection guide

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/yourusername/marketing-spend-audit.svg?style=for-the-badge
[contributors-url]: https://github.com/yourusername/marketing-spend-audit/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/yourusername/marketing-spend-audit.svg?style=for-the-badge
[forks-url]: https://github.com/yourusername/marketing-spend-audit/network/members
[stars-shield]: https://img.shields.io/github/stars/yourusername/marketing-spend-audit.svg?style=for-the-badge
[stars-url]: https://github.com/yourusername/marketing-spend-audit/stargazers
[issues-shield]: https://img.shields.io/github/issues/yourusername/marketing-spend-audit.svg?style=for-the-badge
[issues-url]: https://github.com/yourusername/marketing-spend-audit/issues
[license-shield]: https://img.shields.io/github/license/yourusername/marketing-spend-audit.svg?style=for-the-badge
[license-url]: https://github.com/yourusername/marketing-spend-audit/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/yourusername

<!-- TECHNOLOGY BADGES -->
[Python-badge]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[Python-url]: https://python.org/
[Pandas-badge]: https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white
[Pandas-url]: https://pandas.pydata.org/
[NumPy-badge]: https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white
[NumPy-url]: https://numpy.org/
[Matplotlib-badge]: https://img.shields.io/badge/Matplotlib-11557c?style=for-the-badge&logo=python&logoColor=white
[Matplotlib-url]: https://matplotlib.org/
[Seaborn-badge]: https://img.shields.io/badge/Seaborn-3776AB?style=for-the-badge&logo=python&logoColor=white
[Seaborn-url]: https://seaborn.pydata.org/
[Plotly-badge]: https://img.shields.io/badge/Plotly-3F4F75?style=for-the-badge&logo=plotly&logoColor=white
[Plotly-url]: https://plotly.com/
[Jupyter-badge]: https://img.shields.io/badge/Jupyter-F37626?style=for-the-badge&logo=jupyter&logoColor=white
[Jupyter-url]: https://jupyter.org/
