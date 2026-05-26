-- ============================================================
-- SCRIPT 2: REFERENCE DATA
-- Warehouse Management Practice Database
-- Run against: warehouse_mockup
-- Insert order: employees (managers first) -> warehouses ->
--               update employee warehouse_id -> zones ->
--               aisles -> bin_locations -> suppliers -> products
-- ============================================================

USE warehouse_mockup;
GO

-- ============================================================
-- EMPLOYEES
-- Insert order: top-level managers (NULL manager_id) first,
-- then supervisors, then workers
-- ============================================================
INSERT INTO employees (id, name, role, warehouse_id, manager_id, hire_date, salary) VALUES
(1,  'Robert Haines',    'Regional Director',    NULL, NULL, '2015-03-10', 120000.00),
(2,  'Sandra Ortiz',     'Regional Director',    NULL, NULL, '2016-07-22', 118000.00),
(3,  'James Alcott',     'Warehouse Manager',    NULL, 1,    '2017-05-14', 85000.00),
(4,  'Maria Delgado',    'Warehouse Manager',    NULL, 1,    '2018-02-28', 84000.00),
(5,  'Kevin Tran',       'Warehouse Manager',    NULL, 2,    '2017-11-03', 85500.00),
(6,  'Linda Park',       'Supervisor',           NULL, 3,    '2019-01-15', 62000.00),
(7,  'Carlos Mendez',    'Supervisor',           NULL, 3,    '2019-06-20', 61500.00),
(8,  'Aisha Nwosu',      'Supervisor',           NULL, 4,    '2020-03-11', 62500.00),
(9,  'Tom Bridges',      'Supervisor',           NULL, 5,    '2019-09-30', 63000.00),
(10, 'Priya Sharma',     'Supervisor',           NULL, 5,    '2020-07-14', 61000.00),
(11, 'Derek Willis',     'Warehouse Worker',     NULL, 6,    '2021-02-01', 42000.00),
(12, 'Fatima Hassan',    'Warehouse Worker',     NULL, 6,    '2021-04-15', 41500.00),
(13, 'Marco Rivera',     'Warehouse Worker',     NULL, 6,    '2022-01-10', 41000.00),
(14, 'Jenny Choi',       'Warehouse Worker',     NULL, 7,    '2021-07-19', 42500.00),
(15, 'Aaron Smith',      'Warehouse Worker',     NULL, 7,    '2022-03-28', 41000.00),
(16, 'Natalie Cross',    'Warehouse Worker',     NULL, 8,    '2021-11-08', 42000.00),
(17, 'Omar Khalid',      'Warehouse Worker',     NULL, 8,    '2022-06-01', 41500.00),
(18, 'Rosa Gutierrez',   'Warehouse Worker',     NULL, 9,    '2021-05-17', 42000.00),
(19, 'Ben Matsuda',      'Warehouse Worker',     NULL, 9,    '2022-09-12', 41000.00),
(20, 'Claire Dubois',    'Warehouse Worker',     NULL, 10,   '2021-08-23', 41500.00),
(21, 'Isaac Freeman',    'Warehouse Worker',     NULL, 10,   '2023-01-16', 40500.00),
(22, 'Yuki Tanaka',      'Warehouse Worker',     NULL, 7,    '2023-03-05', 40500.00),
(23, 'Hassan Ali',       'Warehouse Worker',     NULL, 8,    '2023-05-22', 40000.00),
(24, 'Megan Cole',       'Warehouse Worker',     NULL, 9,    '2023-07-11', 40000.00),
(25, 'Luis Vargas',      'Warehouse Worker',     NULL, 10,   '2023-10-03', 40000.00);
GO

-- ============================================================
-- WAREHOUSES
-- ============================================================
INSERT INTO warehouses (id, name, location, capacity_sqft, manager_id) VALUES
(1, 'North Distribution Center',  'Chicago, IL',      120000, 3),
(2, 'South Distribution Center',  'Dallas, TX',       95000,  4),
(3, 'West Coast Hub',             'Los Angeles, CA',  110000, 5),
(4, 'East Coast Hub',             'Newark, NJ',       100000, NULL),
(5, 'Central Fulfillment',        'Kansas City, MO',  80000,  NULL);
GO

-- ============================================================
-- UPDATE EMPLOYEE WAREHOUSE ASSIGNMENTS
-- ============================================================
UPDATE employees SET warehouse_id = 1 WHERE id IN (1, 3, 6, 7, 11, 12, 13, 14, 15, 22);
UPDATE employees SET warehouse_id = 2 WHERE id IN (4, 8, 16, 17, 23);
UPDATE employees SET warehouse_id = 3 WHERE id IN (2, 5, 9, 10, 18, 19, 20, 21, 24, 25);
GO

-- ============================================================
-- ZONES
-- ============================================================
INSERT INTO zones (id, warehouse_id, zone_code, zone_type) VALUES
(1,  1, 'W1-RCV', 'receiving'),
(2,  1, 'W1-STR', 'storage'),
(3,  1, 'W1-SHP', 'shipping'),
(4,  2, 'W2-RCV', 'receiving'),
(5,  2, 'W2-STR', 'storage'),
(6,  2, 'W2-SHP', 'shipping'),
(7,  3, 'W3-RCV', 'receiving'),
(8,  3, 'W3-STR', 'storage'),
(9,  3, 'W3-SHP', 'shipping'),
(10, 4, 'W4-RCV', 'receiving'),
(11, 4, 'W4-STR', 'storage'),
(12, 4, 'W4-SHP', 'shipping'),
(13, 5, 'W5-RCV', 'receiving'),
(14, 5, 'W5-STR', 'storage'),
(15, 5, 'W5-SHP', 'shipping');
GO

-- ============================================================
-- AISLES
-- Storage zones get 4 aisles, receiving and shipping get 2
-- ============================================================
INSERT INTO aisles (id, zone_id, aisle_code) VALUES
(1,  1,  'A1'), (2,  1,  'A2'),
(3,  2,  'B1'), (4,  2,  'B2'), (5,  2,  'B3'), (6,  2,  'B4'),
(7,  3,  'C1'), (8,  3,  'C2'),
(9,  4,  'A1'), (10, 4,  'A2'),
(11, 5,  'B1'), (12, 5,  'B2'), (13, 5,  'B3'), (14, 5,  'B4'),
(15, 6,  'C1'), (16, 6,  'C2'),
(17, 7,  'A1'), (18, 7,  'A2'),
(19, 8,  'B1'), (20, 8,  'B2'), (21, 8,  'B3'), (22, 8,  'B4'),
(23, 9,  'C1'), (24, 9,  'C2'),
(25, 10, 'A1'), (26, 10, 'A2'),
(27, 11, 'B1'), (28, 11, 'B2'), (29, 11, 'B3'), (30, 11, 'B4'),
(31, 12, 'C1'), (32, 12, 'C2'),
(33, 13, 'A1'), (34, 13, 'A2'),
(35, 14, 'B1'), (36, 14, 'B2'), (37, 14, 'B3'), (38, 14, 'B4'),
(39, 15, 'C1'), (40, 15, 'C2');
GO

-- ============================================================
-- BIN LOCATIONS
-- 5 bins per aisle, varying max weights, a few inactive
-- ============================================================
INSERT INTO bin_locations (id, aisle_id, bin_code, max_weight_kg, is_active) VALUES
(1,  1,  'BIN-01', 500.00,  1), (2,  1,  'BIN-02', 500.00,  1), (3,  1,  'BIN-03', 750.00,  1), (4,  1,  'BIN-04', 750.00,  1), (5,  1,  'BIN-05', 500.00,  1),
(6,  2,  'BIN-01', 500.00,  1), (7,  2,  'BIN-02', 500.00,  1), (8,  2,  'BIN-03', 750.00,  1), (9,  2,  'BIN-04', 500.00,  1), (10, 2,  'BIN-05', 500.00,  0),
(11, 3,  'BIN-01', 1000.00, 1), (12, 3,  'BIN-02', 1000.00, 1), (13, 3,  'BIN-03', 750.00,  1), (14, 3,  'BIN-04', 750.00,  1), (15, 3,  'BIN-05', 500.00,  1),
(16, 4,  'BIN-01', 1000.00, 1), (17, 4,  'BIN-02', 750.00,  1), (18, 4,  'BIN-03', 750.00,  1), (19, 4,  'BIN-04', 500.00,  1), (20, 4,  'BIN-05', 500.00,  1),
(21, 5,  'BIN-01', 1000.00, 1), (22, 5,  'BIN-02', 1000.00, 1), (23, 5,  'BIN-03', 750.00,  1), (24, 5,  'BIN-04', 750.00,  1), (25, 5,  'BIN-05', 500.00,  0),
(26, 6,  'BIN-01', 750.00,  1), (27, 6,  'BIN-02', 750.00,  1), (28, 6,  'BIN-03', 500.00,  1), (29, 6,  'BIN-04', 500.00,  1), (30, 6,  'BIN-05', 500.00,  1),
(31, 7,  'BIN-01', 500.00,  1), (32, 7,  'BIN-02', 500.00,  1), (33, 7,  'BIN-03', 500.00,  1), (34, 7,  'BIN-04', 500.00,  1), (35, 7,  'BIN-05', 500.00,  1),
(36, 8,  'BIN-01', 500.00,  1), (37, 8,  'BIN-02', 500.00,  1), (38, 8,  'BIN-03', 500.00,  1), (39, 8,  'BIN-04', 500.00,  0), (40, 8,  'BIN-05', 500.00,  1),
(41, 9,  'BIN-01', 500.00,  1), (42, 9,  'BIN-02', 500.00,  1), (43, 9,  'BIN-03', 750.00,  1), (44, 9,  'BIN-04', 750.00,  1), (45, 9,  'BIN-05', 500.00,  1),
(46, 10, 'BIN-01', 500.00,  1), (47, 10, 'BIN-02', 500.00,  1), (48, 10, 'BIN-03', 750.00,  1), (49, 10, 'BIN-04', 500.00,  1), (50, 10, 'BIN-05', 500.00,  1),
(51, 11, 'BIN-01', 1000.00, 1), (52, 11, 'BIN-02', 1000.00, 1), (53, 11, 'BIN-03', 750.00,  1), (54, 11, 'BIN-04', 750.00,  1), (55, 11, 'BIN-05', 500.00,  1),
(56, 12, 'BIN-01', 1000.00, 1), (57, 12, 'BIN-02', 750.00,  1), (58, 12, 'BIN-03', 750.00,  1), (59, 12, 'BIN-04', 500.00,  1), (60, 12, 'BIN-05', 500.00,  1),
(61, 13, 'BIN-01', 1000.00, 1), (62, 13, 'BIN-02', 1000.00, 1), (63, 13, 'BIN-03', 750.00,  1), (64, 13, 'BIN-04', 750.00,  1), (65, 13, 'BIN-05', 500.00,  0),
(66, 14, 'BIN-01', 750.00,  1), (67, 14, 'BIN-02', 750.00,  1), (68, 14, 'BIN-03', 500.00,  1), (69, 14, 'BIN-04', 500.00,  1), (70, 14, 'BIN-05', 500.00,  1),
(71, 15, 'BIN-01', 500.00,  1), (72, 15, 'BIN-02', 500.00,  1), (73, 15, 'BIN-03', 500.00,  1), (74, 15, 'BIN-04', 500.00,  1), (75, 15, 'BIN-05', 500.00,  1),
(76, 16, 'BIN-01', 500.00,  1), (77, 16, 'BIN-02', 500.00,  1), (78, 16, 'BIN-03', 500.00,  1), (79, 16, 'BIN-04', 500.00,  1), (80, 16, 'BIN-05', 500.00,  1),
(81, 17, 'BIN-01', 500.00,  1), (82, 17, 'BIN-02', 500.00,  1), (83, 17, 'BIN-03', 750.00,  1), (84, 17, 'BIN-04', 750.00,  1), (85, 17, 'BIN-05', 500.00,  1),
(86, 18, 'BIN-01', 500.00,  1), (87, 18, 'BIN-02', 500.00,  1), (88, 18, 'BIN-03', 750.00,  1), (89, 18, 'BIN-04', 500.00,  1), (90, 18, 'BIN-05', 500.00,  0),
(91, 19, 'BIN-01', 1000.00, 1), (92, 19, 'BIN-02', 1000.00, 1), (93, 19, 'BIN-03', 750.00,  1), (94, 19, 'BIN-04', 750.00,  1), (95, 19, 'BIN-05', 500.00,  1),
(96, 20, 'BIN-01', 1000.00, 1), (97, 20, 'BIN-02', 750.00,  1), (98, 20, 'BIN-03', 750.00,  1), (99, 20, 'BIN-04', 500.00,  1), (100,20, 'BIN-05', 500.00,  1);
GO

-- ============================================================
-- SUPPLIERS
-- ============================================================
INSERT INTO suppliers (id, name, contact_email, country, lead_time_days) VALUES
(1,  'Pacific Goods Co.',          'orders@pacificgoods.com',       'USA',       5),
(2,  'Atlantic Supply Group',      'supply@atlanticsg.com',         'USA',       7),
(3,  'Global Parts Ltd.',          'procurement@globalparts.co.uk', 'UK',        14),
(4,  'Euro Wholesale GmbH',        'wholesale@eurogmbh.de',         'Germany',   18),
(5,  'Shenzhen Direct Mfg.',       'sales@szdirect.cn',             'China',     30),
(6,  'Monterrey Industrial',       'ventas@mtyindustrial.mx',       'Mexico',    10),
(7,  'Nordic Logistics AB',        'info@nordiclogistics.se',       'Sweden',    21),
(8,  'Apex Distributors',          'apex@apexdist.com',             'USA',       4),
(9,  'Southern Cross Supplies',    NULL,                            'Australia', 25),
(10, 'Great Lakes Wholesale',      'orders@greatlakeswhl.com',      'USA',       6),
(11, 'Rio Trading Co.',            'trade@riotrading.br',           'Brazil',    20),
(12, 'Tokyo Components Inc.',      'tci@tokyocomp.jp',              'Japan',     28),
(13, 'Midwest Parts Supply',       'parts@midwestsupply.com',       'USA',       3),
(14, 'Coastal Importers LLC',      'imports@coastalllc.com',        'USA',       8),
(15, 'Continental Freight SA',     NULL,                            'France',    16);
GO

-- ============================================================
-- PRODUCTS
-- ============================================================
INSERT INTO products (id, sku, name, category, unit_weight_kg, unit_price) VALUES
(1,  'ELEC-MON-001', '27in 4K Monitor',               'Electronics', 6.50,  349.99),
(2,  'ELEC-MON-002', '24in FHD Monitor',              'Electronics', 4.20,  199.99),
(3,  'ELEC-KBD-001', 'Mechanical Keyboard',           'Electronics', 1.10,   89.99),
(4,  'ELEC-MSE-001', 'Wireless Mouse',                'Electronics', 0.15,   39.99),
(5,  'ELEC-USB-001', 'USB-C Hub 7-Port',              'Electronics', 0.30,   49.99),
(6,  'ELEC-CAB-001', 'HDMI Cable 2m',                 'Electronics', 0.20,   14.99),
(7,  'ELEC-CAB-002', 'USB-C Cable 1m',                'Electronics', 0.10,    9.99),
(8,  'ELEC-WEB-001', '1080p Webcam',                  'Electronics', 0.35,   79.99),
(9,  'ELEC-SPK-001', 'Bluetooth Speaker',             'Electronics', 0.80,   59.99),
(10, 'ELEC-CHG-001', '65W USB-C Charger',             'Electronics', 0.25,   44.99),
(11, 'FURN-CHR-001', 'Ergonomic Office Chair',        'Furniture',  18.00,  449.99),
(12, 'FURN-DSK-001', 'Standing Desk 60in',            'Furniture',  42.00,  599.99),
(13, 'FURN-DSK-002', 'Corner Desk 48in',              'Furniture',  32.00,  299.99),
(14, 'FURN-SHF-001', 'Bookshelf 5-Tier',              'Furniture',  22.00,  149.99),
(15, 'FURN-CAB-001', 'Filing Cabinet 3-Drawer',       'Furniture',  28.00,  199.99),
(16, 'TOOL-DRL-001', 'Cordless Drill 20V',            'Tools',       1.80,   99.99),
(17, 'TOOL-SET-001', 'Socket Set 40pc',               'Tools',       2.50,   59.99),
(18, 'TOOL-SAW-001', 'Circular Saw 7.25in',           'Tools',       4.20,  129.99),
(19, 'TOOL-LEV-001', 'Digital Level 24in',            'Tools',       0.90,   44.99),
(20, 'TOOL-MSR-001', 'Laser Measure 165ft',           'Tools',       0.20,   49.99),
(21, 'SAFE-HLM-001', 'Hard Hat Class E',              'Safety',      0.45,   29.99),
(22, 'SAFE-VES-001', 'Hi-Vis Safety Vest',            'Safety',      0.20,   14.99),
(23, 'SAFE-GLV-001', 'Cut Resistant Gloves L',        'Safety',      0.15,   19.99),
(24, 'SAFE-BOT-001', 'Safety Boots Size 10',          'Safety',      1.40,   89.99),
(25, 'SAFE-EAR-001', 'Ear Protection 25dB',           'Safety',      0.10,   12.99),
(26, 'PACK-BOX-001', 'Cardboard Box 12x12x12',        'Packaging',   0.40,    2.99),
(27, 'PACK-BOX-002', 'Cardboard Box 18x18x18',        'Packaging',   0.65,    4.99),
(28, 'PACK-TAP-001', 'Packing Tape 6-Roll Pack',      'Packaging',   0.80,    9.99),
(29, 'PACK-WRP-001', 'Bubble Wrap Roll 100ft',        'Packaging',   1.20,   14.99),
(30, 'PACK-LBL-001', 'Shipping Labels 500ct',         'Packaging',   0.30,   19.99),
(31, 'CLEN-MOP-001', 'Industrial Mop Set',            'Cleaning',    1.80,   34.99),
(32, 'CLEN-BCK-001', 'Mop Bucket with Wringer',       'Cleaning',    4.50,   49.99),
(33, 'CLEN-BRM-001', 'Push Broom 24in',               'Cleaning',    1.20,   24.99),
(34, 'CLEN-DSF-001', 'Disinfectant Spray 1gal',       'Cleaning',    4.00,   18.99),
(35, 'CLEN-BAG-001', 'Heavy Duty Trash Bags 50ct',    'Cleaning',    1.10,   16.99),
(36, 'OFFC-PPR-001', 'Copy Paper Case 10-Ream',       'Office',     22.00,   49.99),
(37, 'OFFC-PEN-001', 'Ballpoint Pens 12-Pack',        'Office',      0.15,    7.99),
(38, 'OFFC-FLD-001', 'Manila Folders 100ct',          'Office',      0.60,   12.99),
(39, 'OFFC-STK-001', 'Sticky Notes 12-Pack',          'Office',      0.25,    8.99),
(40, 'OFFC-STP-001', 'Heavy Duty Stapler',            'Office',      0.55,   22.99),
(41, 'ELEC-SRG-001', 'Surge Protector 8-Outlet',      'Electronics', 0.60,   34.99),
(42, 'ELEC-EXT-001', 'Extension Cord 25ft',           'Electronics', 0.70,   19.99),
(43, 'TOOL-WRN-001', 'Adjustable Wrench Set 3pc',     'Tools',       1.20,   39.99),
(44, 'SAFE-MSK-001', 'N95 Respirator Masks 20ct',     'Safety',      0.30,   24.99),
(45, 'FURN-MAT-001', 'Anti-Fatigue Mat 3x5ft',        'Furniture',   2.80,   59.99),
(46, 'PACK-STR-001', 'Strapping Tape 2in 6-Pack',     'Packaging',   1.50,   22.99),
(47, 'CLEN-GLV-001', 'Latex Gloves 100ct Box',        'Cleaning',    0.40,   13.99),
(48, 'OFFC-CLK-001', 'Wall Clock 12in',               'Office',      0.55,   17.99),
(49, 'ELEC-BAT-001', 'AA Batteries 48ct',             'Electronics', 0.75,   19.99),
(50, 'TOOL-TPE-001', 'Measuring Tape 25ft',           'Tools',       0.30,   14.99);
GO
