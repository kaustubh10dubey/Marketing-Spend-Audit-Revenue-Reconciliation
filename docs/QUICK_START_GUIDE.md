# Quick Start Guide

This guide will help you get the project up and running quickly.

## 1. Prerequisites

- Python 3.8+
- `pip` for package management

## 2. Installation

```bash
# Clone the repository
git clone <repository_url>
cd marketing-spend-audit

# Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows, use `.venv\Scripts\activate`

# Install dependencies
pip install -r requirements.txt
```

## 3. Running the Analysis

The core analysis is performed in the Jupyter notebooks in the `notebooks/` directory.

1.  **Start Jupyter Lab:**
    ```bash
    jupyter lab
    ```
2.  **Run the notebooks in order:**
    - `01_eda.ipynb`
    - `02_metrics.ipynb`
    - `03_misreporting.ipynb`
    - `04_reconciliation.ipynb`

## 4. Viewing the Outputs

-   **Reports:** The `reports/` directory contains the `executive_summary.md` and exported charts and tables from the notebooks.
-   **SQL Queries:** The `sql/` directory contains the queries used for data analysis and validation.
-   **Data:** The `data/` directory contains the raw CSV files.
