
"""
Utility functions for the Marketing Spend Audit and Revenue Reconciliation project.
"""

import pandas as pd
from typing import Dict, Tuple, Any

def load_all_data(data_dir: str = 'data/') -> Dict[str, pd.DataFrame]:
    """
    Loads all necessary CSV files from the specified directory into pandas DataFrames.

    Args:
        data_dir (str): The directory where the CSV files are located.

    Returns:
        Dict[str, pd.DataFrame]: A dictionary of pandas DataFrames, with file names as keys.
    
    Raises:
        FileNotFoundError: If any of the required CSV files are not found.
    """
    files_to_load = [
        'marketing_spend.csv',
        'funnel_events.csv',
        'revenue_marketing.csv',
        'revenue_finance.csv'
    ]
    dataframes = {}
    try:
        for filename in files_to_load:
            path = f"{data_dir}{filename}"
            df = pd.read_csv(path)
            # Convert date columns
            for col in df.columns:
                if 'date' in col or 'timestamp' in col:
                    df[col] = pd.to_datetime(df[col])
            dataframes[filename.split('.')[0]] = df
        return dataframes
    except FileNotFoundError as e:
        print(f"Error loading data: {e}. Make sure all CSV files are in the '{data_dir}' directory.")
        raise

def calculate_roas(
    df_mkt: pd.DataFrame, df_fin: pd.DataFrame, df_spend: pd.DataFrame
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Calculates Return on Ad Spend (ROAS) from both marketing and finance perspectives.

    Args:
        df_mkt (pd.DataFrame): DataFrame with marketing revenue data.
        df_fin (pd.DataFrame): DataFrame with finance revenue data.
        df_spend (pd.DataFrame): DataFrame with marketing spend data.

    Returns:
        Tuple[pd.DataFrame, pd.DataFrame]: A tuple containing two DataFrames:
                                     1. Marketing ROAS by channel.
                                     2. Finance ROAS by channel.
    """
    spend_by_channel = df_spend.groupby('campaign')['spend'].sum()
    mkt_revenue_by_channel = df_mkt.groupby('campaign')['revenue'].sum()
    
    # Assumption: Finance revenue needs to be mapped to a campaign. We merge with marketing data to do this.
    fin_revenue_by_channel = df_mkt.merge(df_fin, on='date', suffixes=('_mkt', '_fin'))\
                                     .groupby('campaign')['revenue_fin'].sum()

    roas_mkt = (mkt_revenue_by_channel / spend_by_channel).reset_index(name='roas')
    roas_fin = (fin_revenue_by_channel / spend_by_channel).reset_index(name='roas')
    
    return roas_mkt, roas_fin

def calculate_cac(df_spend: pd.DataFrame, df_funnel: pd.DataFrame) -> pd.DataFrame:
    """Calculate true CAC using finance-verified paid users."""
    # Assumption: Link campaign to funnel events by date
    daily_campaigns = df_spend[['date', 'campaign']].drop_duplicates()
    df_funnel['date'] = pd.to_datetime(df_funnel['timestamp'].dt.date)
    events_with_campaign = pd.merge(df_funnel, daily_campaigns, on='date')
    
    # Assumption: An acquisition is a unique user checkout event
    acquisitions = events_with_campaign[events_with_campaign['event_type'] == 'checkout']\
                   .groupby('campaign')['user_id'].nunique().reset_index(name='customers')
    
    spend_by_channel = df_spend.groupby('campaign')['spend'].sum().reset_index()
    
    cac_df = pd.merge(acquisitions, spend_by_channel, on='campaign')
    cac_df['cac'] = cac_df['spend'] / cac_df['customers']
    
    return cac_df[['campaign', 'cac', 'customers']]

def detect_misreporting(df_mkt: pd.DataFrame, df_fin: pd.DataFrame, df_spend: pd.DataFrame) -> pd.DataFrame:
    """
    Detects various forms of misreporting and anomalies in the data.

    Args:
        df_mkt (pd.DataFrame): DataFrame with marketing revenue data.
        df_fin (pd.DataFrame): DataFrame with finance revenue data.
        df_spend (pd.DataFrame): DataFrame with marketing spend data.

    Returns:
        pd.DataFrame: A DataFrame listing all detected anomalies.
    """
    anomalies = []

    # Aggregate revenue and merge
    mkt_rev_agg = df_mkt.groupby('date')['revenue'].sum().reset_index(name='mkt_revenue')
    fin_rev_agg = df_fin.groupby('date')['revenue'].sum().reset_index(name='fin_revenue')
    revenue_comp = pd.merge(mkt_rev_agg, fin_rev_agg, on='date', how='outer').fillna(0)

    # 1. Revenue Inflation (only where finance revenue is reported)
    inflation_candidates = revenue_comp[revenue_comp['fin_revenue'] > 0].copy()
    inflation_candidates['variance'] = (inflation_candidates['mkt_revenue'] - inflation_candidates['fin_revenue']) / inflation_candidates['fin_revenue']
    inflated = inflation_candidates[inflation_candidates['variance'] > 0.2]
    for _, row in inflated.iterrows():
        severity = 'Critical' if row['variance'] > 0.5 else 'High'
        anomalies.append({'date': row['date'], 'anomaly_type': 'Revenue Inflation', 'details': f"Variance: {row['variance']:.2%}", 'severity': severity})

    # 2. Missing Invoices (where finance revenue is zero but marketing revenue is not)
    missing = revenue_comp[(revenue_comp['fin_revenue'] == 0) & (revenue_comp['mkt_revenue'] > 0)]
    for _, row in missing.iterrows():
        anomalies.append({'date': row['date'], 'anomaly_type': 'Missing Invoice', 'details': f"Mkt Revenue: {row['mkt_revenue']}", 'severity': 'High'})

    # 3. Outlier Spend Days
    spend_mean = df_spend['spend'].mean()
    spend_std = df_spend['spend'].std()
    outlier_threshold = spend_mean + 2 * spend_std
    outliers = df_spend[df_spend['spend'] > outlier_threshold]
    for _, row in outliers.iterrows():
        anomalies.append({'date': row['date'], 'anomaly_type': 'Outlier Spend', 'details': f"Spend: {row['spend']}", 'severity': 'High'})
        
    return pd.DataFrame(anomalies)

def generate_reconciliation_report() -> Dict[str, Any]:
    """
    Generates a full reconciliation report by running all audit functions.

    Returns:
        Dict[str, Any]: A dictionary containing key metrics and result DataFrames.
    """
    try:
        data = load_all_data()
        df_mkt = data['revenue_marketing']
        df_fin = data['revenue_finance']
        df_spend = data['marketing_spend']
        df_funnel = data['funnel_events']

        roas_mkt, roas_fin = calculate_roas(df_mkt, df_fin, df_spend)
        cac_df = calculate_cac(df_spend, df_funnel)
        anomalies_df = detect_misreporting(df_mkt, df_fin, df_spend)

        # Executive Metrics
        total_spend = df_spend['spend'].sum()
        total_fin_revenue = df_fin['revenue'].sum()
        overall_roas = total_fin_revenue / total_spend
        
        report = {
            "executive_summary": {
                "total_spend": total_spend,
                "total_finance_revenue": total_fin_revenue,
                "overall_finance_roas": overall_roas,
                "total_anomalies_detected": len(anomalies_df),
            },
            "roas_marketing": roas_mkt,
            "roas_finance": roas_fin,
            "cac_by_channel": cac_df,
            "detected_anomalies": anomalies_df
        }
        return report

    except Exception as e:
        print(f"An error occurred during report generation: {e}")
        return {}

if __name__ == '__main__':
    # Example of how to use the functions
    report_data = generate_reconciliation_report()
    if report_data:
        print("--- Reconciliation Report ---")
        for key, value in report_data['executive_summary'].items():
            print(f"{key.replace('_', ' ').title()}: {value}")
        print("\n--- ROAS (Finance) ---")
        print(report_data['roas_finance'])
        print("\n--- CAC by Channel ---")
        print(report_data['cac_by_channel'])
        print("\n--- Detected Anomalies ---")
        print(report_data['detected_anomalies'])
