import pyodbc



def clean():

    # Connection
    conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=NordaTrade_GmbH;'
    'Trusted_Connection=yes;'
    )
    cursor = conn.cursor()

    # --- STEP 1: CLEANUP ---
    print("Cleaning database with new naming standard...")
    cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'")
    
    tables = [
        'fact_returns', 
        'fact_order_line_items', 
        'product_promotions', 
        'fact_sale_orders', 
        'rep_customer_assignments', 
        'dim_customers', 
        'dim_products', 
        'dim_categories', 
        'fact_quotas', 
        'dim_sales_reps', 
        'dim_territories', 
        'dim_countries', 
        'dim_regions', 
        'dim_account_tiers', 
        'dim_sale_statuses', 
        'dim_return_reasons', 
        'dim_promotions', 
        'dim_date'
    ]
    
    for t in tables:
        try:
            cursor.execute(f"DELETE FROM [{t}]")
        except Exception as e:
            print(f"Skipping {t}: {e}")
            
    cursor.execute("EXEC sp_MSforeachtable 'IF OBJECTPROPERTY(OBJECT_ID(''?''), ''TableHasIdentity'') = 1 DBCC CHECKIDENT (''?'', RESEED, 0)'")
    
    cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'")
    
    conn.commit()
    conn.close()
    

clean()
print("Cleaned Successfully!")