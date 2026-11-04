USE automated_parking_db;

-- Add 15 more reservations: 11 completed, 2 confirmed, 2 cancelled.
-- Existing reservation IDs are 1-3; this script adds IDs 4-18.
START TRANSACTION;

INSERT INTO reservation
(reservation_id, user_id, vehicle_id, position_id, start_time, end_time, status, booking_time)
VALUES
(4, 4, 4, 1, '2026-11-01 08:00:00', '2026-11-01 10:00:00', 'COMPLETED', '2026-10-31 18:00:00'),
(5, 5, 5, 2, '2026-11-01 10:00:00', '2026-11-01 12:00:00', 'COMPLETED', '2026-10-31 19:00:00'),
(6, 6, 6, 1, '2026-11-01 12:00:00', '2026-11-01 14:00:00', 'COMPLETED', '2026-11-01 08:00:00'),
(7, 7, 7, 2, '2026-11-01 14:00:00', '2026-11-01 16:00:00', 'COMPLETED', '2026-11-01 09:00:00'),
(8, 8, 8, 1, '2026-11-02 08:00:00', '2026-11-02 10:00:00', 'COMPLETED', '2026-11-01 20:00:00'),
(9, 9, 9, 2, '2026-11-02 10:00:00', '2026-11-02 12:00:00', 'COMPLETED', '2026-11-01 21:00:00'),
(10, 10, 10, 3, '2026-11-02 12:00:00', '2026-11-02 14:00:00', 'COMPLETED', '2026-11-02 07:00:00'),
(11, 11, 11, 4, '2026-11-02 14:00:00', '2026-11-02 16:00:00', 'COMPLETED', '2026-11-02 07:30:00'),
(12, 12, 12, 3, '2026-11-03 08:00:00', '2026-11-03 10:00:00', 'COMPLETED', '2026-11-02 18:00:00'),
(13, 13, 13, 4, '2026-11-03 10:00:00', '2026-11-03 12:00:00', 'COMPLETED', '2026-11-02 19:00:00'),
(14, 14, 14, 1, '2026-11-03 13:00:00', '2026-11-03 15:00:00', 'COMPLETED', '2026-11-03 08:00:00'),
(15, 15, 15, 2, '2026-11-05 09:00:00', '2026-11-05 12:00:00', 'CONFIRMED', '2026-11-03 10:00:00'),
(16, 16, 16, 1, '2026-11-06 14:00:00', '2026-11-06 17:00:00', 'CONFIRMED', '2026-11-03 11:00:00'),
(17, 17, 17, 2, '2026-11-04 09:00:00', '2026-11-04 11:00:00', 'CANCELLED', '2026-11-02 12:00:00'),
(18, 18, 18, 1, '2026-11-04 13:00:00', '2026-11-04 15:00:00', 'CANCELLED', '2026-11-02 13:00:00');

-- Create sessions for completed and confirmed reservations (IDs 4-16).
INSERT INTO parking_session
(session_id, reservation_id, vehicle_id, position_id, entry_time, exit_time, status)
VALUES
(4, 4, 4, 1, '2026-11-01 08:00:05', '2026-11-01 09:50:00', 'COMPLETED'),
(5, 5, 5, 2, '2026-11-01 10:00:05', '2026-11-01 11:50:00', 'COMPLETED'),
(6, 6, 6, 1, '2026-11-01 12:00:05', '2026-11-01 13:50:00', 'COMPLETED'),
(7, 7, 7, 2, '2026-11-01 14:00:05', '2026-11-01 15:50:00', 'COMPLETED'),
(8, 8, 8, 1, '2026-11-02 08:00:05', '2026-11-02 09:50:00', 'COMPLETED'),
(9, 9, 9, 2, '2026-11-02 10:00:05', '2026-11-02 11:50:00', 'COMPLETED'),
(10, 10, 10, 3, '2026-11-02 12:00:05', '2026-11-02 13:50:00', 'COMPLETED'),
(11, 11, 11, 4, '2026-11-02 14:00:05', '2026-11-02 15:50:00', 'COMPLETED'),
(12, 12, 12, 3, '2026-11-03 08:00:05', '2026-11-03 09:50:00', 'COMPLETED'),
(13, 13, 13, 4, '2026-11-03 10:00:05', '2026-11-03 11:50:00', 'COMPLETED'),
(14, 14, 14, 1, '2026-11-03 13:00:05', '2026-11-03 14:50:00', 'COMPLETED'),
(15, 15, 15, 2, NULL, NULL, 'NOT_STARTED'),
(16, 16, 16, 1, NULL, NULL, 'NOT_STARTED');

-- Add one billing record per new parking session.
INSERT INTO billing
(bill_id, session_id, base_charge, lift_charge, reservation_charge, duration_charge, tax, discount, total_amount, payment_status, payment_method, transaction_reference, payment_time)
VALUES
(4, 4, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'UPI', 'TXN-SP-20261103-004', '2026-11-01 09:50:00'),
(5, 5, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'CARD', 'TXN-SP-20261103-005', '2026-11-01 11:50:00'),
(6, 6, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'UPI', 'TXN-SP-20261103-006', '2026-11-01 13:50:00'),
(7, 7, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'CARD', 'TXN-SP-20261103-007', '2026-11-01 15:50:00'),
(8, 8, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'UPI', 'TXN-SP-20261103-008', '2026-11-02 09:50:00'),
(9, 9, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'CARD', 'TXN-SP-20261103-009', '2026-11-02 11:50:00'),
(10, 10, 20.00, 5.00, 15.00, 25.00, 3.25, 0.00, 68.25, 'PAID', 'UPI', 'TXN-SP-20261103-010', '2026-11-02 13:50:00'),
(11, 11, 20.00, 5.00, 15.00, 25.00, 3.25, 0.00, 68.25, 'PAID', 'CARD', 'TXN-SP-20261103-011', '2026-11-02 15:50:00'),
(12, 12, 20.00, 5.00, 15.00, 25.00, 3.25, 0.00, 68.25, 'PAID', 'UPI', 'TXN-SP-20261103-012', '2026-11-03 09:50:00'),
(13, 13, 20.00, 5.00, 15.00, 25.00, 3.25, 0.00, 68.25, 'PAID', 'CARD', 'TXN-SP-20261103-013', '2026-11-03 11:50:00'),
(14, 14, 30.00, 10.00, 15.00, 40.00, 4.75, 0.00, 99.75, 'PAID', 'UPI', 'TXN-SP-20261103-014', '2026-11-03 14:50:00'),
(15, 15, 30.00, 10.00, 15.00, 0.00, 2.75, 0.00, 57.75, 'PENDING', 'CARD', 'TXN-SP-20261103-015', NULL),
(16, 16, 30.00, 10.00, 15.00, 0.00, 2.75, 0.00, 57.75, 'PENDING', 'CARD', 'TXN-SP-20261103-016', NULL);

-- Add three more violations for demonstration.
INSERT INTO violation
(violation_id, vehicle_id, session_id, position_id, violation_type, description, fine_amount, reported_by, violation_time, status, penalty_status, penalty_payment_method, penalty_payment_date)
VALUES
(3, 5, 5, 2, 'OVERTIME_PARKING', 'Vehicle remained beyond the reserved time slot.', 200.00, 3, '2026-11-01 12:05:00', 'RESOLVED', 'PAID', 'UPI', '2026-11-01 12:20:00'),
(4, 8, 8, 1, 'IMPROPER_PARKING', 'Vehicle was parked outside the marked position.', 150.00, 3, '2026-11-02 09:30:00', 'OPEN', 'UNPAID', NULL, NULL),
(5, 12, 12, 3, 'UNAUTHORIZED_PARKING', 'Vehicle occupied a position without valid authorization.', 250.00, 3, '2026-11-03 09:15:00', 'UNDER_REVIEW', 'UNPAID', NULL, NULL);

-- Positions 1 and 3 are now free because their earlier sessions have ended.
UPDATE lift_position SET status = 'AVAILABLE' WHERE position_id IN (1, 3);

COMMIT;

-- VERIFY UPDATED COUNTS
SELECT 'users' AS table_name, COUNT(*) AS records FROM users
UNION ALL SELECT 'vehicle', COUNT(*) FROM vehicle
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'parking_session', COUNT(*) FROM parking_session
UNION ALL SELECT 'billing', COUNT(*) FROM billing
UNION ALL SELECT 'violation', COUNT(*) FROM violation;

-- Verify reservation and customer relationships
SELECT r.reservation_id, u.name, v.registration_no, lp.position_number, r.start_time, r.status
FROM reservation r
JOIN users u ON r.user_id = u.user_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
JOIN lift_position lp ON r.position_id = lp.position_id
ORDER BY r.reservation_id;
