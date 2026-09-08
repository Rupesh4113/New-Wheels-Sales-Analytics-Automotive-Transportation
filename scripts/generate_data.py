import os
import random
import csv
from datetime import datetime, timedelta

random.seed(42)

RAW_DIR = os.path.join('data', 'raw')
PROCESSED_DIR = os.path.join('data', 'processed')
os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)

print('Initializing synthetic data generator for New Wheels Sales Analytics...')
import os
import random
import csv
from datetime import datetime, timedelta

random.seed(42)

RAW_DIR = os.path.join('data', 'raw')
PROCESSED_DIR = os.path.join('data', 'processed')
os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)

# -------------------------------------------------------------
# 1. DISPATCH CENTERS
# -------------------------------------------------------------
dispatch_centers = [
    (1, 'Northeast Distribution Hub', 'Northeast', 'Newark', 'NJ', 1200, '2020-03-15'),
    (2, 'Southeast Logistics Center', 'Southeast', 'Atlanta', 'GA', 1400, '2019-06-01'),
    (3, 'Midwest Central Terminal', 'Midwest', 'Chicago', 'IL', 1600, '2018-11-10'), # Major bottleneck
    (4, 'Southwest Freight Depot', 'Southwest', 'Dallas', 'TX', 1300, '2021-01-20'),
    (5, 'Pacific Gateway Facility', 'West', 'Los Angeles', 'CA', 1800, '2018-04-12'),
    (6, 'Gulf Coast Fulfillment Center', 'Southeast', 'Houston', 'TX', 1100, '2021-08-05'), # Secondary bottleneck
    (7, 'Great Lakes Transit Hub', 'Midwest', 'Detroit', 'MI', 1250, '2020-09-18'),
    (8, 'Northwest Regional Center', 'West', 'Seattle', 'WA', 950, '2022-02-28')
]

with open(os.path.join(RAW_DIR, 'dispatch_centers.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['dispatch_center_id', 'center_name', 'region', 'city', 'state', 'capacity', 'established_date'])
    w.writerows(dispatch_centers)

# -------------------------------------------------------------
# 2. CARRIERS
# -------------------------------------------------------------
carriers = [
    (1, 'SwiftAuto Logistics', 'National', 4),
    (2, 'Apex Freight Systems', 'Regional', 3),
    (3, 'TransNational Express', 'National', 5),
    (4, 'Velocity Transporters', 'Regional', 3),
    (5, 'PrimeRoute Haulers', 'National', 6)
]

with open(os.path.join(RAW_DIR, 'carriers.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['carrier_id', 'carrier_name', 'service_region', 'sla_days'])
    w.writerows(carriers)

# -------------------------------------------------------------
# 3. VEHICLES / PRODUCTS (20 distinct models)
# -------------------------------------------------------------
vehicles = [
    (1, 'Apex Horizon', 'Sedan', 'Mid-Size', 'AeroMotors', 2024, 28500.00, 22800.00),
    (2, 'Apex EV-Pulse', 'Electric', 'Compact', 'AeroMotors', 2024, 37500.00, 29250.00),
    (3, 'Aero Vista Crossover', 'SUV', 'Crossover', 'AeroMotors', 2024, 34000.00, 26860.00),
    (4, 'Terra Titan 1500', 'Truck', 'Full-Size', 'TerraDynamics', 2024, 46500.00, 36270.00),
    (5, 'Terra Pathfinder', 'SUV', 'Full-Size', 'TerraDynamics', 2024, 42000.00, 33180.00),
    (6, 'Terra Trekker Eco', 'SUV', 'Compact', 'TerraDynamics', 2024, 31000.00, 24800.00),
    (7, 'Lumina Grand Touring', 'Sedan', 'Full-Size', 'Lumina', 2024, 36500.00, 28835.00),
    (8, 'Lumina Spark City', 'Economy', 'Compact', 'Lumina', 2023, 21500.00, 17415.00),
    (9, 'Lumina Volt Premier', 'Electric', 'Mid-Size', 'Lumina', 2024, 44000.00, 34320.00),
    (10, 'Zenith Sovereignty', 'Luxury', 'Full-Size', 'Zenith', 2024, 78500.00, 58875.00),
    (11, 'Zenith Elegance Coupe', 'Luxury', 'Coupe', 'Zenith', 2024, 69000.00, 52440.00),
    (12, 'Zenith E-Crown', 'Electric', 'Full-Size', 'Zenith', 2024, 84500.00, 63375.00),
    (13, 'Vortech Outlaw GT', 'Sports', 'Coupe', 'Vortech', 2024, 56000.00, 43680.00),
    (14, 'Vortech Cyclone R', 'Sports', 'Compact', 'Vortech', 2024, 48500.00, 38315.00),
    (15, 'Terra Hauler HD', 'Truck', 'Full-Size', 'TerraDynamics', 2024, 54500.00, 42510.00),
    (16, 'Aero Metro Commuter', 'Economy', 'Compact', 'AeroMotors', 2023, 23000.00, 18630.00),
    (17, 'Lumina CrossCountry', 'SUV', 'Crossover', 'Lumina', 2024, 38500.00, 30415.00),
    (18, 'Zenith Ascent Luxury SUV', 'Luxury', 'Full-Size', 'Zenith', 2024, 82000.00, 61500.00),
    (19, 'Apex Storm EV', 'Electric', 'Crossover', 'AeroMotors', 2024, 49500.00, 38610.00),
    (20, 'Vortech Velocity Sport', 'Sports', 'Coupe', 'Vortech', 2024, 62000.00, 48360.00)
]

with open(os.path.join(RAW_DIR, 'vehicles.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['vehicle_id', 'vehicle_model', 'vehicle_class', 'vehicle_style', 'brand', 'model_year', 'list_price', 'cost_price'])
    w.writerows(vehicles)

# -------------------------------------------------------------
# 4. CUSTOMERS (1,600 realistic customers)
# -------------------------------------------------------------
first_names = ['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth',
               'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen',
               'Christopher', 'Nancy', 'Daniel', 'Lisa', 'Matthew', 'Betty', 'Anthony', 'Margaret', 'Mark', 'Sandra',
               'Donald', 'Ashley', 'Steven', 'Kimberly', 'Paul', 'Emily', 'Andrew', 'Donna', 'Joshua', 'Michelle']
last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
              'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
              'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson',
              'Walker', 'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores']

regions_data = {
    'Northeast': [('New York', 'NY'), ('Boston', 'MA'), ('Philadelphia', 'PA'), ('Newark', 'NJ'), ('Hartford', 'CT')],
    'Southeast': [('Atlanta', 'GA'), ('Miami', 'FL'), ('Charlotte', 'NC'), ('Nashville', 'TN'), ('Orlando', 'FL')],
    'Midwest': [('Chicago', 'IL'), ('Detroit', 'MI'), ('Indianapolis', 'IN'), ('Columbus', 'OH'), ('Milwaukee', 'WI')],
    'Southwest': [('Dallas', 'TX'), ('Houston', 'TX'), ('Phoenix', 'AZ'), ('Austin', 'TX'), ('San Antonio', 'TX')],
    'West': [('Los Angeles', 'CA'), ('San Francisco', 'CA'), ('Seattle', 'WA'), ('Denver', 'CO'), ('Portland', 'OR')]
}

customer_segments = ['Individual', 'Small Business', 'Corporate Fleet']
segment_weights = [0.82, 0.13, 0.05]

customers = []
for c_id in range(1, 1601):
    fn = random.choice(first_names)
    ln = random.choice(last_names)
    gender = random.choice(['Male', 'Female', 'Non-Binary'])
    age = random.randint(22, 73)
    reg_region = random.choice(list(regions_data.keys()))
    city, state = random.choice(regions_data[reg_region])
    seg = random.choices(customer_segments, weights=segment_weights)[0]
    reg_date = datetime(2023, 1, 1) + timedelta(days=random.randint(0, 680))
    customers.append((c_id, f'{fn} {ln}', gender, age, city, state, reg_region, seg, reg_date.strftime('%Y-%m-%d')))

with open(os.path.join(RAW_DIR, 'customers.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['customer_id', 'customer_name', 'gender', 'age', 'city', 'state', 'region', 'customer_segment', 'registration_date'])
    w.writerows(customers)

print('Generated dispatch centers, carriers, vehicles, customers successfully.')
# -------------------------------------------------------------
# 5. ORDERS, ORDER ITEMS, SHIPPING, & CUSTOMER FEEDBACK
# -------------------------------------------------------------

veh_dict = {v[0]: {'model': v[1], 'class': v[2], 'style': v[3], 'brand': v[4], 'price': v[6], 'cost': v[7]} for v in vehicles}
carrier_dict = {c[0]: {'name': c[1], 'sla': c[3]} for c in carriers}
cust_dict = {c[0]: {'name': c[1], 'region': c[6], 'segment': c[7]} for c in customers}

# Region to DC mapping
region_dc_map = {
    'Northeast': [1],
    'Southeast': [2, 6],
    'Midwest': [3, 7],
    'Southwest': [4, 6],
    'West': [5, 8]
}

# Quarterly order distribution: Q1 > Q2 > Q3 > Q4 (declining sales trend)
quarters = [
    ('Q1', datetime(2024, 1, 1), datetime(2024, 3, 31), 780),
    ('Q2', datetime(2024, 4, 1), datetime(2024, 6, 30), 710),
    ('Q3', datetime(2024, 7, 1), datetime(2024, 9, 30), 570),
    ('Q4', datetime(2024, 10, 1), datetime(2024, 12, 31), 510)
]

orders = []
order_items = []
shipping_records = []
feedback_records = []

order_counter = 1
item_counter = 1
shipment_counter = 1
feedback_counter = 1

customer_order_history = {} # cust_id -> list of {'order_id': id, 'date': dt, 'delay': days}

comments_positive = [
    'Vehicle delivered in showroom condition. Very impressed with the quick turnaround!',
    'Seamless delivery experience and fantastic performance so far.',
    'Arrived earlier than promised! Driver was courteous and professional.',
    'Excellent vehicle, smooth delivery process. Highly recommend New Wheels.',
    'Delivery on schedule, vehicle is spotless and driving like a dream.'
]
comments_neutral = [
    'Delivery arrived as scheduled, minor paperwork delay at hand-off.',
    'Vehicle is solid. Transit took the full promised duration.',
    'Decent service overall, communication could be slightly clearer.',
    'Average delivery experience. Vehicle meets expectations.'
]
comments_negative = [
    'Delayed transit by several days with vague tracking updates.',
    'Delivery took over a week past the promised date. Very stressful experience.',
    'Poor carrier communication regarding rescheduled drop-off.',
    'Expected faster fulfillment given the premium price point.'
]
comments_severe = [
    'Unacceptable delay! Over two weeks late with zero customer support response.',
    'Delivery breached SLA by 10 days. Vehicle was sitting at Chicago hub for days with no movement.',
    'Terrible logistics breakdown. Had to rent a car due to unannounced delivery delays.',
    'Horrible experience! Promised delivery date missed repeatedly. Will not purchase again.'
]

for q_name, start_date, end_date, target_count in quarters:
    days_range = (end_date - start_date).days
    
    # In Q3 and Q4, discount rates are increased aggressively (discount leakage)
    q_base_discount = 0.045 if q_name == 'Q1' else (0.055 if q_name == 'Q2' else (0.095 if q_name == 'Q3' else 0.125))
    
    for _ in range(target_count):
        o_date = start_date + timedelta(days=random.randint(0, days_range))
        
        # Decide if repeat customer or new customer
        is_repeat = False
        selected_cust_id = None
        
        # Eligible past customers
        past_customers = [cid for cid, hist in customer_order_history.items() if hist[-1]['date'] < o_date]
        if past_customers and random.random() < 0.28:
            candidate_id = random.choice(past_customers)
            last_delay = customer_order_history[candidate_id][-1]['delay']
            # Repeat probability drops dramatically if previous delivery was delayed!
            rep_prob = 0.42 if last_delay <= 0 else (0.25 if last_delay <= 3 else 0.08)
            if random.random() < rep_prob:
                is_repeat = True
                selected_cust_id = candidate_id
        
        if not is_repeat:
            selected_cust_id = random.randint(1, len(customers))
            
        cust = cust_dict[selected_cust_id]
        cust_region = cust['region']
        cust_seg = cust['segment']
        
        # Quantity
        if cust_seg == 'Individual':
            qty = 1
        elif cust_seg == 'Small Business':
            qty = random.choices([1, 2], weights=[0.8, 0.2])[0]
        else:
            qty = random.choices([2, 3, 4], weights=[0.6, 0.3, 0.1])[0]
            
        # Vehicle selection (different regional popularity)
        if cust_region in ['Midwest', 'Southwest']:
            # Trucks and SUVs more popular
            v_id = random.choices(list(veh_dict.keys()), weights=[1.2, 0.8, 1.5, 2.2, 1.8, 1.5, 1.0, 1.2, 0.9, 0.7, 0.6, 0.5, 1.1, 0.9, 2.0, 1.0, 1.4, 0.8, 0.8, 1.0])[0]
        elif cust_region == 'West':
            # EVs and Sedans more popular
            v_id = random.choices(list(veh_dict.keys()), weights=[1.5, 2.2, 1.4, 0.8, 1.0, 1.2, 1.4, 1.5, 2.0, 1.2, 1.1, 1.6, 1.2, 1.0, 0.7, 1.4, 1.2, 1.1, 2.1, 1.2])[0]
        else:
            v_id = random.randint(1, 20)
            
        veh = veh_dict[v_id]
        unit_price = veh['price']
        
        # Discount logic: discount leakage occurs in Q3/Q4 and on specific models
        disc_rate = q_base_discount + random.uniform(-0.02, 0.04)
        if v_id in [10, 11, 12, 18]: # Luxury models occasionally steeply discounted in late quarters
            if q_name in ['Q3', 'Q4']:
                disc_rate += random.uniform(0.04, 0.08)
        disc_rate = max(0.0, min(0.25, disc_rate))
        unit_discount = round(unit_price * disc_rate, 2)
        total_discount = round(unit_discount * qty, 2)
        gross_sales = round(unit_price * qty, 2)
        net_sales = round(gross_sales - total_discount, 2)
        
        # Order status: 95% Completed, 3.5% Cancelled, 1.5% Returned
        o_status = random.choices(['Completed', 'Cancelled', 'Returned'], weights=[0.95, 0.035, 0.015])[0]
        
        # Dispatch center selection
        dc_candidates = region_dc_map.get(cust_region, [1])
        dc_id = random.choice(dc_candidates)
        
        # Shipping Carrier
        carrier_id = random.randint(1, 5)
        sla_days = carrier_dict[carrier_id]['sla']
        
        orders.append((
            order_counter, selected_cust_id, o_date.strftime('%Y-%m-%d'),
            o_status, v_id, qty, gross_sales, total_discount, net_sales,
            cust_region, dc_id
        ))
        
        order_items.append((
            item_counter, order_counter, v_id, qty,
            unit_price, total_discount, net_sales
        ))
        
        # Shipping simulation
        dispatch_date = o_date + timedelta(days=random.randint(1, 2))
        shipped_date = dispatch_date
        promised_date = o_date + timedelta(days=sla_days)
        
        # Fulfillment delay logic: Bottleneck at DC 3 (Midwest) and DC 6 (Houston) especially in Q3 & Q4
        is_bottleneck_dc = (dc_id in [3, 6])
        if q_name in ['Q3', 'Q4'] and is_bottleneck_dc:
            # 75% chance of severe delay
            is_delayed = (random.random() < 0.78)
            if is_delayed:
                delay_days = random.randint(4, 14)
                deliv_days = (promised_date - dispatch_date).days + delay_days
            else:
                delay_days = 0
                deliv_days = max(1, (promised_date - dispatch_date).days - random.randint(0, 1))
        elif q_name in ['Q3', 'Q4']:
            # Non-bottleneck DCs in Q3/Q4 have mild pressure
            is_delayed = (random.random() < 0.28)
            delay_days = random.randint(1, 6) if is_delayed else 0
            deliv_days = max(1, (promised_date - dispatch_date).days + delay_days)
        else:
            # Q1 and Q2: healthy operations
            is_delayed = (random.random() < 0.12)
            delay_days = random.randint(1, 4) if is_delayed else 0
            deliv_days = max(1, (promised_date - dispatch_date).days + delay_days)
            
        actual_delivery_date = dispatch_date + timedelta(days=deliv_days)
        
        if o_status == 'Cancelled':
            deliv_status = 'Cancelled'
            deliv_days = 0
            delay_days = 0
            actual_delivery_date = None
        elif delay_days > 0:
            deliv_status = 'Delayed'
        else:
            deliv_status = 'On-Time'
            delay_days = 0
            
        actual_deliv_str = actual_delivery_date.strftime('%Y-%m-%d') if actual_delivery_date else ''
        shipping_records.append((
            shipment_counter, order_counter, dc_id, carrier_id,
            dispatch_date.strftime('%Y-%m-%d'), shipped_date.strftime('%Y-%m-%d'),
            promised_date.strftime('%Y-%m-%d'), actual_deliv_str,
            deliv_status, deliv_days, delay_days
        ))
        
        # Record customer history for repeat behavior
        if selected_cust_id not in customer_order_history:
            customer_order_history[selected_cust_id] = []
        customer_order_history[selected_cust_id].append({
            'order_id': order_counter,
            'date': o_date,
            'delay': delay_days
        })
        
        # Feedback simulation
        # 16% missing feedback (realistic data quality scenario)
        has_feedback = (random.random() > 0.16) and (o_status != 'Cancelled') and actual_delivery_date
        if has_feedback:
            feedback_date = actual_delivery_date + timedelta(days=random.randint(1, 4))
            
            # Rating depends strongly on delivery performance
            if deliv_days <= 2 or delay_days == 0:
                rating = random.choices([5, 4, 3], weights=[0.68, 0.26, 0.06])[0]
            elif deliv_days <= 5 and delay_days <= 2:
                rating = random.choices([5, 4, 3, 2], weights=[0.25, 0.50, 0.20, 0.05])[0]
            elif deliv_days <= 8 or delay_days <= 5:
                rating = random.choices([4, 3, 2, 1], weights=[0.10, 0.35, 0.40, 0.15])[0]
            else: # Severe delays (> 8 days or delay_days > 5)
                rating = random.choices([2, 1], weights=[0.20, 0.80])[0]
                
            if rating == 5:
                cat = 'Very Positive'
                comment = random.choice(comments_positive)
            elif rating == 4:
                cat = 'Positive'
                comment = random.choice(comments_positive)
            elif rating == 3:
                cat = 'Neutral'
                comment = random.choice(comments_neutral)
            elif rating == 2:
                cat = 'Negative'
                comment = random.choice(comments_negative)
            else:
                cat = 'Very Negative'
                comment = random.choice(comments_severe)
                
            feedback_records.append((
                feedback_counter, order_counter, selected_cust_id,
                rating, feedback_date.strftime('%Y-%m-%d'), cat, comment
            ))
            feedback_counter += 1
        elif o_status != 'Cancelled' and actual_delivery_date and random.random() < 0.2:
            # Explicit NULL rating record for defensible methodology testing
            feedback_date = actual_delivery_date + timedelta(days=2)
            feedback_records.append((
                feedback_counter, order_counter, selected_cust_id,
                '', feedback_date.strftime('%Y-%m-%d'), 'Unrated', ''
            ))
            feedback_counter += 1

        order_counter += 1
        item_counter += 1
        shipment_counter += 1

# Write orders.csv
with open(os.path.join(RAW_DIR, 'orders.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['order_id', 'customer_id', 'order_date', 'order_status', 'vehicle_id', 'quantity', 'list_price', 'discount', 'net_sales', 'order_region', 'dispatch_center_id'])
    w.writerows(orders)

# Write order_items.csv
with open(os.path.join(RAW_DIR, 'order_items.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['order_item_id', 'order_id', 'vehicle_id', 'quantity', 'unit_price', 'discount', 'line_total'])
    w.writerows(order_items)

# Write shipping.csv
with open(os.path.join(RAW_DIR, 'shipping.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['shipment_id', 'order_id', 'dispatch_center_id', 'carrier_id', 'dispatch_date', 'shipped_date', 'promised_delivery_date', 'actual_delivery_date', 'delivery_status', 'delivery_days', 'delay_days'])
    w.writerows(shipping_records)

# Write customer_feedback.csv
with open(os.path.join(RAW_DIR, 'customer_feedback.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['feedback_id', 'order_id', 'customer_id', 'rating', 'feedback_date', 'satisfaction_category', 'comments'])
    w.writerows(feedback_records)

print(f'Generation complete:')
print(f'  Orders: {len(orders)}')
print(f'  Order Items: {len(order_items)}')
print(f'  Shipping records: {len(shipping_records)}')
print(f'  Feedback records: {len(feedback_records)}')
