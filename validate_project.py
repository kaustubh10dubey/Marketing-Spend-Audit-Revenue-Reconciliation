import pandas as pd
import os

def validate():
    # Check files
    files = ['marketing_spend.csv', 'funnel_events.csv', 'revenue_marketing.csv', 'revenue_finance.csv']
    all_files_exist = True
    for f in files:
        path = f'data/{f}'
        if not os.path.exists(path):
            print(f"❌ MISSING: {path}")
            all_files_exist = False
        else:
            df = pd.read_csv(path)
            print(f"✅ {f}: {df.shape}")
    
    if not all_files_exist:
        print("🔴 Some data files are missing. Cannot proceed with validation.")
        return False

    # Check key metrics
    spend = pd.read_csv('data/marketing_spend.csv')
    mkt_rev = pd.read_csv('data/revenue_marketing.csv')
    fin_rev = pd.read_csv('data/revenue_finance.csv')
    
    # Check for expected columns before using them
    if 'spend' not in spend.columns:
        print("❌ 'spend' column not found in marketing_spend.csv")
        return False
    if 'reported_revenue' not in mkt_rev.columns:
        print("❌ 'reported_revenue' column not found in revenue_marketing.csv")
        return False
    if 'actual_revenue' not in fin_rev.columns:
        print("❌ 'actual_revenue' column not found in revenue_finance.csv")
        return False
    if 'user_id' not in mkt_rev.columns:
        print("❌ 'user_id' column not found in revenue_marketing.csv")
        return False

    print(f"💰 Spend: ${spend['spend'].sum():,}")
    print(f"💵 Mkt Rev: ${mkt_rev['reported_revenue'].sum():,}")
    print(f"💰 Fin Rev: ${fin_rev['actual_revenue'].sum():,}")
    print(f"📊 Gap: {((mkt_rev['reported_revenue'].sum() - fin_rev['actual_revenue'].sum()) / mkt_rev['reported_revenue'].sum() * 100):.1f}%")
    
    # Check U111 duplicate
    u111 = mkt_rev[mkt_rev['user_id'] == 'U111']
    print(f"🔍 U111 rows: {len(u111)}")
    
    print("🟢 ALL CHECKS PASSED!")
    return True

if __name__ == "__main__":
    validate()
