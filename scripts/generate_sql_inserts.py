import csv
import os

def escape_sql(val):
    if val is None or val == '':
        return 'NULL'
    try:
        if '.' in val:
            float(val)
            return val
        int(val)
        return val
    except ValueError:
        pass
    escaped = val.replace("'", "''")
    return f"'{escaped}'"

raw_dir = os.path.join('data', 'raw')
out_sql = os.path.join('sql', '03_load_data.sql')

tables = [
    ('dispatch_centers', 'dispatch_centers.csv'),
    ('carriers', 'carriers.csv'),
    ('customers', 'customers.csv'),
    ('vehicles', 'vehicles.csv'),
    ('orders', 'orders.csv'),
    ('order_items', 'order_items.csv'),
    ('shipping', 'shipping.csv'),
    ('customer_feedback', 'customer_feedback.csv')
]

with open(out_sql, 'w', encoding='utf-8') as sql_out:
    sql_out.write('-- ====================================================================\n')
    sql_out.write('-- SCRIPT: 03_load_data.sql\n')
    sql_out.write('-- PROJECT: New Wheels Sales Analytics — Automotive / Transportation\n')
    sql_out.write('-- DESCRIPTION: Standalone DML batch loading script for all entities\n')
    sql_out.write('-- ====================================================================\n\n')
    sql_out.write('USE new_wheels_db;\n\n')
    sql_out.write('SET foreign_key_checks = 0;\n\n')

    for table_name, csv_file in tables:
        csv_path = os.path.join(raw_dir, csv_file)
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader)
            cols = ', '.join(header)
            rows = list(reader)
            print(f'Processing {table_name}: {len(rows)} rows...')
            batch_size = 250
            for i in range(0, len(rows), batch_size):
                batch = rows[i:i+batch_size]
                sql_out.write(f'INSERT INTO {table_name} ({cols}) VALUES\n')
                val_lines = []
                for row in batch:
                    vals = [escape_sql(v) for v in row]
                    val_lines.append(f'    ({", ".join(vals)})')
                sql_out.write(',\n'.join(val_lines))
                sql_out.write(';\n\n')

    sql_out.write('SET foreign_key_checks = 1;\n\n')
    sql_out.write('-- Verification row counts\n')
    sql_out.write('SELECT "dispatch_centers" AS entity, COUNT(*) AS total_records FROM dispatch_centers\n')
    sql_out.write('UNION ALL SELECT "carriers", COUNT(*) FROM carriers\n')
    sql_out.write('UNION ALL SELECT "customers", COUNT(*) FROM customers\n')
    sql_out.write('UNION ALL SELECT "vehicles", COUNT(*) FROM vehicles\n')
    sql_out.write('UNION ALL SELECT "orders", COUNT(*) FROM orders\n')
    sql_out.write('UNION ALL SELECT "order_items", COUNT(*) FROM order_items\n')
    sql_out.write('UNION ALL SELECT "shipping", COUNT(*) FROM shipping\n')
    sql_out.write('UNION ALL SELECT "customer_feedback", COUNT(*) FROM customer_feedback;\n')

print(f'Generated {out_sql} successfully.')
