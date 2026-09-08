import subprocess
import time
import re

MYSQL_EXE = r'C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe'
DB_ARGS = ['-h', '127.0.0.1', '-P', '3307', '-u', 'root', 'new_wheels_db']

def run_query(sql):
    cmd = [MYSQL_EXE] + DB_ARGS + ['-e', sql]
    start = time.perf_counter()
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    duration_ms = (time.perf_counter() - start) * 1000
    if res.returncode != 0:
        print('Error:', res.stderr)
    return duration_ms, res.stdout

test_query = '''
SELECT 
    o.order_region,
    v.vehicle_class,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.net_sales), 2) AS total_net_revenue,
    ROUND(AVG(s.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(f.rating), 2) AS avg_csat_rating
FROM orders o
JOIN vehicles v ON o.vehicle_id = v.vehicle_id
JOIN shipping s ON o.order_id = s.order_id
LEFT JOIN customer_feedback f ON o.order_id = f.order_id
WHERE o.order_date BETWEEN '2024-04-01' AND '2024-12-31'
  AND s.delivery_status != 'Cancelled'
GROUP BY o.order_region, v.vehicle_class
ORDER BY total_net_revenue DESC;
'''

print('--- DROPPING CUSTOM INDEXES TO BENCHMARK BASELINE ---')
drop_sql = '''
ALTER TABLE orders DROP INDEX idx_orders_date_region_veh;
ALTER TABLE orders DROP INDEX idx_orders_cust_date;
ALTER TABLE shipping DROP INDEX idx_shipping_order_status;
ALTER TABLE shipping DROP INDEX idx_shipping_dc_delay;
ALTER TABLE customer_feedback DROP INDEX idx_feedback_order_rating;
ALTER TABLE customers DROP INDEX idx_customers_region_seg;
'''
subprocess.run([MYSQL_EXE] + DB_ARGS + ['-e', drop_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Benchmark before
runs_before = []
for _ in range(25):
    t, _ = run_query(test_query)
    runs_before.append(t)
avg_before = sum(runs_before) / len(runs_before)

print(f'Before Index Optimization (25 runs avg): {avg_before:.2f} ms')

print('--- CREATING INDEXES ---')
create_sql = '''
CREATE INDEX idx_orders_date_region_veh ON orders (order_date, order_region, vehicle_id);
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date);
CREATE INDEX idx_shipping_order_status ON shipping (order_id, delivery_status);
CREATE INDEX idx_shipping_dc_delay ON shipping (dispatch_center_id, delay_days, delivery_days);
CREATE INDEX idx_feedback_order_rating ON customer_feedback (order_id, rating);
CREATE INDEX idx_customers_region_seg ON customers (region, customer_segment);
'''
subprocess.run([MYSQL_EXE] + DB_ARGS + ['-e', create_sql], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# Benchmark after
runs_after = []
for _ in range(25):
    t, _ = run_query(test_query)
    runs_after.append(t)
avg_after = sum(runs_after) / len(runs_after)

print(f'After Index Optimization (25 runs avg): {avg_after:.2f} ms')
pct_improvement = ((avg_before - avg_after) / avg_before) * 100
speedup_factor = avg_before / avg_after
print(f'Absolute Improvement: {avg_before - avg_after:.2f} ms')
print(f'Percentage Improvement: {pct_improvement:.2f}%')
print(f'Speedup Factor: {speedup_factor:.2f}x')
