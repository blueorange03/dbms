USE automated_parking_db;

-- =========================================================
-- SMART PARKING SLOT RESERVATION & VIOLATION MANAGEMENT
-- Sample DML data for final DBMS project
-- Run only on the currently empty project database.
-- =========================================================

START TRANSACTION;

-- 1. USERS
INSERT INTO users
(user_id, name, email, phone, password, user_type)
VALUES
(1, 'Aarav Sharma', 'aarav.sharma@example.com', '9876501001', 'demo_hash_user1', 'CUSTOMER'),
(2, 'Diya Nair', 'diya.nair@example.com', '9876501002', 'demo_hash_user2', 'CUSTOMER'),
(3, 'Parking Admin', 'admin@smartparking.example', '9876501003', 'demo_hash_admin', 'ADMIN');

-- 2. VEHICLES
INSERT INTO vehicle
(vehicle_id, user_id, registration_no, vehicle_type, brand, model, color, weight_kg)
VALUES
(1, 1, 'KA03MN1234', 'CAR', 'Hyundai', 'i20', 'White', 1150.00),
(2, 2, 'KA05PQ5678', 'CAR', 'Tata', 'Nexon', 'Blue', 1350.00),
(3, 1, 'KA51AB9012', 'BIKE', 'Honda', 'Activa', 'Black', 110.00);

-- 3. PARKING FACILITIES
INSERT INTO parking_facility
(facility_id, facility_name, location, operating_hours, contact_number)
VALUES
(1, 'Central Smart Parking', 'Electronic City, Bengaluru', '06:00-23:00', '08040001001'),
(2, 'City Centre Parking', 'Koramangala, Bengaluru', '00:00-23:59', '08040001002');

-- 4. PARKING ZONES
INSERT INTO parking_zone
(zone_id, facility_id, zone_name, zone_type, location, capacity)
VALUES
(1, 1, 'Car Zone A', 'CAR', 'Basement Level 1', 20),
(2, 1, 'Two Wheeler Zone B', 'TWO_WHEELER', 'Ground Level', 30),
(3, 2, 'Premium Car Zone', 'CAR', 'Basement Level 2', 15);

-- 5. PARKING LIFTS
INSERT INTO parking_lift
(lift_id, zone_id, lift_code, lift_type, capacity, max_load_kg, lift_status)
VALUES
(1, 1, 'LIFT-A1', 'HYDRAULIC', 4, 6000.00, 'OPERATIONAL'),
(2, 2, 'LIFT-B1', 'MECHANICAL', 6, 1200.00, 'OPERATIONAL'),
(3, 3, 'LIFT-C1', 'HYDRAULIC', 4, 6000.00, 'MAINTENANCE');

-- 6. LIFT POSITIONS
INSERT INTO lift_position
(position_id, lift_id, position_number, vehicle_type, status)
VALUES
(1, 1, 1, 'CAR', 'OCCUPIED'),
(2, 1, 2, 'CAR', 'AVAILABLE'),
(3, 2, 1, 'BIKE', 'OCCUPIED'),
(4, 2, 2, 'BIKE', 'AVAILABLE'),
(5, 3, 1, 'CAR', 'AVAILABLE'),
(6, 3, 2, 'CAR', 'AVAILABLE');

-- 7. RESERVATIONS
INSERT INTO reservation
(reservation_id, user_id, vehicle_id, position_id, start_time, end_time, status, booking_time)
VALUES
(1, 1, 1, 1, '2026-11-02 09:00:00', '2026-11-02 12:00:00', 'COMPLETED', '2026-11-01 18:30:00'),
(2, 2, 2, 2, '2026-11-04 10:00:00', '2026-11-04 13:00:00', 'CONFIRMED', '2026-11-03 09:15:00'),
(3, 1, 3, 3, '2026-11-02 14:00:00', '2026-11-02 16:00:00', 'COMPLETED', '2026-11-02 08:00:00');

-- 8. PARKING SESSIONS
INSERT INTO parking_session
(session_id, reservation_id, vehicle_id, position_id, entry_time, exit_time, status)
VALUES
(1, 1, 1, 1, '2026-11-02 09:05:00', '2026-11-02 11:50:00', 'COMPLETED'),
(2, 2, 2, 2, NULL, NULL, 'NOT_STARTED'),
(3, 3, 3, 3, '2026-11-02 14:05:00', '2026-11-02 15:45:00', 'COMPLETED');

-- 9. BILLING
INSERT INTO billing
(bill_id, session_id, base_charge, lift_charge, reservation_charge, duration_charge,
 tax, discount, total_amount, payment_status, payment_method, transaction_reference, payment_time)
VALUES
(1, 1, 30.00, 10.00, 15.00, 55.00, 5.50, 5.00, 110.50, 'PAID', 'UPI', 'TXN-SP-20261102-001', '2026-11-02 11:55:00'),
(2, 2, 30.00, 10.00, 15.00, 0.00, 5.50, 0.00, 60.50, 'PENDING', 'CARD', 'TXN-SP-20261103-002', NULL),
(3, 3, 20.00, 5.00, 10.00, 35.00, 3.50, 0.00, 73.50, 'PAID', 'CASH', 'TXN-SP-20261102-003', '2026-11-02 15:50:00');

-- 10. VIOLATIONS
INSERT INTO violation
(violation_id, vehicle_id, session_id, position_id, violation_type, description,
 fine_amount, reported_by, violation_time, status, penalty_status,
 penalty_payment_method, penalty_payment_date)
VALUES
(1, 1, 1, 1, 'OVERTIME_PARKING', 'Vehicle exceeded the reserved parking duration.', 200.00, 3,
 '2026-11-02 11:40:00', 'RESOLVED', 'PAID', 'UPI', '2026-11-02 12:00:00'),
(2, 3, 3, 3, 'IMPROPER_PARKING', 'Vehicle was not aligned correctly within the allocated position.', 150.00, 3,
 '2026-11-02 14:30:00', 'OPEN', 'UNPAID', NULL, NULL);

COMMIT;

-- =========================================================
-- VERIFY INSERTED RECORDS
-- =========================================================
SELECT 'users' AS table_name, COUNT(*) AS total_records FROM users
UNION ALL SELECT 'vehicle', COUNT(*) FROM vehicle
UNION ALL SELECT 'parking_facility', COUNT(*) FROM parking_facility
UNION ALL SELECT 'parking_zone', COUNT(*) FROM parking_zone
UNION ALL SELECT 'parking_lift', COUNT(*) FROM parking_lift
UNION ALL SELECT 'lift_position', COUNT(*) FROM lift_position
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'parking_session', COUNT(*) FROM parking_session
UNION ALL SELECT 'billing', COUNT(*) FROM billing
UNION ALL SELECT 'violation', COUNT(*) FROM violation;

-- A few useful relationship checks
SELECT r.reservation_id, u.name, v.registration_no, lp.position_number, r.status
FROM reservation r
JOIN users u ON r.user_id = u.user_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
JOIN lift_position lp ON r.position_id = lp.position_id;

SELECT b.bill_id, ps.session_id, b.total_amount, b.payment_status
FROM billing b
JOIN parking_session ps ON b.session_id = ps.session_id;
