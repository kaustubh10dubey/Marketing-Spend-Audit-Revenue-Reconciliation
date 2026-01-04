import pandas as pd
import os

# Quick validation
files = ['marketing_spend.csv', 'funnel_events.csv', 'revenue_marketing.csv', 'revenue_finance.csv']
for f in files:
    if os.path.exists(f'data/{f}'):
        df = pd.read_csv(f'data/{f}')
        print(f"✅ {f}: {df.shape[0]} rows")
    else:
        print(f"❌ {f} missing")

spend = pd.read_csv('data/marketing_spend.csv')
print(f"Total spend: ${spend['spend'].sum():,}")
print("✅ Project structure validated!")