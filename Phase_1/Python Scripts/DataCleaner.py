import pyodbc

# Connection
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=NordaTrade_GmbH;'
    'Trusted_Connection=yes;'
)
cursor = conn.cursor()

def clean():
    # --- STEP 1: CLEANUP ---
    print("Cleaning database...")
    cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'")
    tables = ['Return', 'OrderLineItem', 'Promotion_Product', 'SaleOrder', 
              'Customer_SalesRepresentative', 'Customer', 'Product', 'Category', 
              'Quota', 'SalesRepresentative', 'Territory', 'Country', 'Region', 
              'AccountTier', 'SaleStatus', 'ReturnReason', 'Promotion', 'Date']
    for t in tables:
        cursor.execute(f"DELETE FROM [{t}]")
    cursor.execute("EXEC sp_MSforeachtable 'IF OBJECTPROPERTY(OBJECT_ID(''?''), ''TableHasIdentity'') = 1 DBCC CHECKIDENT (''?'', RESEED, 0)'")
    cursor.execute("EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'")
    conn.commit()
    

clean()
conn.close()
print("Cleaned Sucessfully!")