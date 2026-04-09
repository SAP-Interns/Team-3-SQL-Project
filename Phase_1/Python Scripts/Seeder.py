import pyodbc
from faker import Faker
import random
from datetime import date, timedelta
from DataCleaner import clean

fake = Faker(['de_DE'])

# Configuration & Seed
seed = 10
numOfSalesRep = 50
numOfCustomers = 500
numOfProducts = 200
numOfSales = 10000
random.seed(seed)

# Connection
conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=NordaTrade_GmbH;'
    'Trusted_Connection=yes;'
)
cursor = conn.cursor()

def final_master_seed():
    print("Starting Final Master Seed...")
    
    clean()

    # --- 2. DATES & LOOKUPS ---
    curr, end = date(2024, 1, 1), date(2028, 12, 31)
    date_buffer = []
    while curr <= end:
        iso_w = curr.isocalendar()[1]
        date_key = int(curr.strftime('%Y%m%d'))
        
        date_buffer.append((date_key, curr, curr.year, (curr.month-1)//3+1, curr.month, curr.strftime('%B'), 
                            52 if iso_w > 52 else iso_w, curr.isoweekday(), curr.strftime('%A'), 1 if curr.isoweekday() <= 5 else 0))
        curr += timedelta(days=1)
        
    cursor.executemany("""
        INSERT INTO [dim_date] (DateKey, FullDate, Year, Quarter, MonthNum, MonthName, WeekNum, DayOfWeek, DayName, IsBusinessDay) 
        VALUES (?,?,?,?,?,?,?,?,?,?)""", date_buffer)
    
    cursor.executemany("INSERT INTO dim_regions (Name) VALUES (?)", [('DACH',), ('Benelux',), ('Western Europe',)])
    cursor.executemany("INSERT INTO dim_account_tiers (Name) VALUES (?)", [('Bronze',), ('Silver',), ('Gold',), ('Platinum',)])
    cursor.executemany("INSERT INTO dim_sale_statuses (Name) VALUES (?)", [('Pending',), ('Delivered',), ('Cancelled',)])
    cursor.executemany("INSERT INTO dim_return_reasons (Name) VALUES (?)", [('Defective',), ('Not Satisfied',)])
    conn.commit()

    # --- 3. GEOGRAPHY ---
    cursor.execute("SELECT ID, Name FROM dim_regions")
    regs = {name: id for id, name in cursor.fetchall()}
    countries = [('Germany', 'DACH'), ('Austria', 'DACH'), ('Switzerland', 'DACH'), ('Netherlands', 'Benelux'), ('France', 'Western Europe')]
    
    t_ids = []
    for c_name, r_name in countries:
        cursor.execute("INSERT INTO dim_countries (Name, RegionID) VALUES (?, ?)", (c_name, regs[r_name]))
        c_id = cursor.execute("SELECT @@IDENTITY").fetchone()[0]
        for s in ['North', 'South']:
            cursor.execute("INSERT INTO dim_territories (Name, CountryID) VALUES (?, ?)", (f"{c_name} {s}", c_id))
            t_ids.append(cursor.execute("SELECT @@IDENTITY").fetchone()[0])
    conn.commit()

    # --- 4. STAFF (Reps) ---
    rep_start_date = date(2024, 1, 1)
    start_date_key = int(rep_start_date.strftime('%Y%m%d'))
    cursor.execute("SELECT ID FROM dim_regions")
    reg_ids = [r[0] for r in cursor.fetchall()]
    for _ in range(numOfSalesRep):
        cursor.execute("INSERT INTO dim_sales_reps (Name, RegionID, StartingDateKey, StartingDate) VALUES (?, ?, ?, ?)", (fake.name(), random.choice(reg_ids), start_date_key, rep_start_date))
        r_id = cursor.execute("SELECT @@IDENTITY").fetchone()[0]
        q_date = date(2026, 6, 30) - timedelta(days=random.randint(0, 200))
        q_date_key = int(q_date.strftime('%Y%m%d'))
        cursor.execute("INSERT INTO fact_quotas (SalesRepresentativeID, TerritoryID, DueDateKey, DueDate, TargetAmount) VALUES (?, ?, ?, ?, ?)", (r_id, random.choice(t_ids), q_date_key, q_date, random.randint(20000,750000)))
    conn.commit()

    # --- 5. CATEGORIES ---
    category_map = {"Industrial Equipment": ["Generators", "Robots"], "Office Supplies": ["Papers", "Printers"], "Technology Hardware": ["Computers"]}
    child_cat_ids = []
    for parent, children in category_map.items():
        cursor.execute("INSERT INTO dim_categories (Name, ParentID) VALUES (?, NULL)", (parent,))
        p_id = cursor.execute("SELECT @@IDENTITY").fetchone()[0]
        for child in children:
            cursor.execute("INSERT INTO dim_categories (Name, ParentID) VALUES (?, ?)", (child, p_id))
            child_cat_ids.append(cursor.execute("SELECT @@IDENTITY").fetchone()[0])
    conn.commit()

    # --- 6. CUSTOMERS & JUNCTION ---
    cursor.execute("SELECT ID FROM dim_account_tiers")
    tier_ids = [t[0] for t in cursor.fetchall()]
    cursor.execute("SELECT ID FROM dim_sales_reps")
    all_reps = [r[0] for r in cursor.fetchall()]

    cursor.execute("SELECT ID FROM dim_territories")
    ter_ids = [r[0] for r in cursor.fetchall()]
    for _ in range(numOfCustomers):
        cursor.execute("INSERT INTO dim_customers (Name, BillingAddress, TerritoryID, CreditLimit, AccountTierID) VALUES (?,?,?,?,?)", 
                       (fake.company(), fake.street_address().replace('\n', ', '), random.choice(ter_ids), random.randint(1, 100000), random.choice(tier_ids)))
        c_id = cursor.execute("SELECT @@IDENTITY").fetchone()[0]
        
        if random.random() < 0.80:
            for r_id in random.sample(all_reps, random.randint(1, 2)):
                assign_date = rep_start_date + timedelta(days=random.randint(0, 700))
                assign_date_key = int(assign_date.strftime('%Y%m%d'))
                
                cursor.execute("""
                    INSERT INTO rep_customer_assignments (CustomerID, SalesRepresentativeID, AssignedDateKey, AssignedDate) 
                    VALUES (?, ?, ?, ?)""", (c_id, r_id, assign_date_key, assign_date))
    conn.commit()

    # --- 7. PRODUCTS ---
    product_after = [" Pro", " Max", " Plus", ""]
    for _ in range(numOfProducts):
        p = round(random.uniform(100, 1500), 2)
        multiplier = random.uniform(1.2, 3.5)
        listing_price = round(p * multiplier, 2)
        cursor.execute("INSERT INTO dim_products (Name, CategoryID, UnitCost, ListingPrice, Stock) VALUES (?,?,?,?,?)", 
                       (fake.word().capitalize() + random.choice(product_after), random.choice(child_cat_ids), p, listing_price, random.randint(1, 1000)))
    conn.commit()

    # --- 7.5 PROMOTIONS ---
    promos = [
        ('Spring Sale', 10, date(2024, 3, 1), date(2024, 5, 31)),
        ('Summer Clearance', 20, date(2024, 6, 1), date(2024, 8, 31)),
        ('Black Friday', 30, date(2024, 11, 20), date(2024, 11, 30)),
        ('Year End Blowout', 25, date(2025, 12, 1), date(2025, 12, 31)),
        ('New Year 2026', 15, date(2026, 1, 1), date(2026, 2, 28))
    ]
    promo_data = []
    for p_name, disc, start, end in promos:
        start_date_key = int(start.strftime('%Y%m%d'))
        end_date_key = int(end.strftime('%Y%m%d'))
        
        cursor.execute("""
            INSERT INTO dim_promotions (Name, DiscountPercentage, StartDateKey, EndDateKey, StartDate, EndDate) 
            OUTPUT INSERTED.ID, INSERTED.DiscountPercentage, INSERTED.StartDate, INSERTED.EndDate 
            VALUES (?, ?, ?, ?, ?, ?)""", (p_name, disc, start_date_key, end_date_key, start, end))
        promo_data.append(cursor.fetchone())

    cursor.execute("SELECT ID FROM dim_products")
    all_product_ids = [p[0] for p in cursor.fetchall()]
    product_promo_map = {pid: [] for pid in all_product_ids}
    for p_id, p_disc, p_start, p_end in promo_data:
        targeted_products = random.sample(all_product_ids, 30)
        for prod_id in targeted_products:
            cursor.execute("INSERT INTO product_promotions (PromotionID, ProductID) VALUES (?, ?)", (p_id, prod_id))
            product_promo_map[prod_id].append((p_id, p_disc, p_start.date(), p_end.date()))
    conn.commit()

    # --- 8. SALES ---
    print("Generating Sales Orders...")
    cursor.execute("SELECT ID, Name FROM dim_sale_statuses")
    status_map = {name: id for id, name in cursor.fetchall()}
    cursor.execute("SELECT ID, Name FROM dim_return_reasons")
    reason_map = {name: id for id, name in cursor.fetchall()}

    statuses = [status_map['Delivered'], status_map['Pending'], status_map['Cancelled']]
    weights = [80, 15, 5]

    cursor.execute("SELECT CustomerID, SalesRepresentativeID FROM rep_customer_assignments")
    pairs = cursor.fetchall()
    cursor.execute("SELECT ID, ListingPrice FROM dim_products")
    prods = cursor.fetchall()

    for i in range(1, numOfSales + 1):
        c_id, r_id = random.choice(pairs)
        o_date = date(2026, 3, 28) - timedelta(days=random.randint(0, 800))
        o_date_key = int(o_date.strftime('%Y%m%d'))
        
        chosen_status_id = random.choices(statuses, weights=weights, k=1)[0]
        
        ship_date = o_date + timedelta(days=random.randint(1, 20)) if chosen_status_id == status_map['Delivered'] else None
        ship_date_key = int(ship_date.strftime('%Y%m%d')) if ship_date else None
        
        cursor.execute("""
            INSERT INTO fact_sale_orders (CustomerID, SalesRepresentativeID, OrderDateKey, OrderDate, PaymentTerm, SaleStatusID, ShippingDateKey, ShippingDate) 
            OUTPUT INSERTED.ID VALUES (?, ?, ?, ?, 'Net 30', ?, ?, ?)""", 
            (c_id, r_id, o_date_key, o_date, chosen_status_id, ship_date_key, ship_date))
        o_id = cursor.fetchone()[0]
        
        for _ in range(2):
            p_id, base_price = random.choice(prods)
            applied_promo_id = None
            final_unit_price = base_price
            qty = random.randint(1,10)
            
            if p_id in product_promo_map:
                for promo_id, disc, start, end in product_promo_map[p_id]:
                    if start <= o_date <= end:
                        applied_promo_id = promo_id
                        final_unit_price = round(base_price * (1 - (disc / 100.0)), 2)                       
                        break

            totalPrice = final_unit_price * qty            
            cursor.execute("""
                INSERT INTO fact_order_line_items (SaleOrderID, ProductID, Quantity, UnitPrice, TotalPrice, PromotionID) 
                OUTPUT INSERTED.ID, INSERTED.Quantity, INSERTED.TotalPrice
                VALUES (?, ?, ?, ?, ?, ?)""", 
                (o_id, p_id, qty, final_unit_price, totalPrice, applied_promo_id))
            
            row = cursor.fetchone()
            line_item_id = row[0]
            returned_qty = row[1]
            returned_total_price = row[2]

            if chosen_status_id == status_map['Cancelled']:
                ret_date = o_date + timedelta(days=random.randint(0, 2))
                ret_date_key = int(ret_date.strftime('%Y%m%d'))
                
                cursor.execute("""
                    INSERT INTO [fact_returns] (OrderLineItemID, ReturnDateKey, ReturnDate, ReturnReasonID, ReturnQuantity, CreditAmount) 
                    VALUES (?, ?, ?, ?, ?, ?)""", (line_item_id, ret_date_key, ret_date, reason_map['Not Satisfied'], returned_qty, returned_total_price))
        
        if i % 2500 == 0:
            print(f"--- {i} orders processed...")
            conn.commit()

    conn.commit()
    print("SUCCESS! NordaTrade_GmbH is fully populated.")

final_master_seed()
conn.close()