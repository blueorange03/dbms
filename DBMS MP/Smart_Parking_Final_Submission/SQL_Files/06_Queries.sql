USE automated_parking_db;

-- SMART PARKING: PHASE 3 - SQL QUERIES
-- Run sections individually when capturing screenshots for the report.

-- =========================================================
-- A. SIMPLE SELECT, WHERE, ORDER BY, DISTINCT
-- =========================================================

-- Q1. Display all registered customers.
SELECT user_id, name, email, phone, user_type
FROM users
ORDER BY name;

-- Q2. Display all vehicles belonging to customers.
SELECT vehicle_id, user_id, registration_no, vehicle_type, brand, model
FROM vehicle
ORDER BY vehicle_id;

-- Q3. Display confirmed reservations.
SELECT reservation_id, user_id, vehicle_id, position_id, start_time, end_time, status
FROM reservation
WHERE status = 'CONFIRMED'
ORDER BY start_time;

-- Q4. Display the different vehicle types registered in the system.
SELECT DISTINCT vehicle_type
FROM vehicle;

-- Q5. Display available lift positions.
SELECT position_id, lift_id, position_number, vehicle_type, status
FROM lift_position
WHERE status = 'AVAILABLE'
ORDER BY lift_id, position_number;

-- =========================================================
-- B. AGGREGATE FUNCTIONS, GROUP BY AND HAVING
-- =========================================================

-- Q6. Count the number of registered users.
SELECT COUNT(*) AS total_users
FROM users;

-- Q7. Count vehicles by vehicle type.
SELECT vehicle_type, COUNT(*) AS vehicle_count
FROM vehicle
GROUP BY vehicle_type;

-- Q8. Find the total revenue from paid bills.
SELECT SUM(total_amount) AS total_revenue
FROM billing
WHERE payment_status = 'PAID';

-- Q9. Find average, minimum and maximum bill amounts.
SELECT
    AVG(total_amount) AS average_bill,
    MIN(total_amount) AS minimum_bill,
    MAX(total_amount) AS maximum_bill
FROM billing;

-- Q10. Count reservations by status.
SELECT status, COUNT(*) AS reservation_count
FROM reservation
GROUP BY status
ORDER BY reservation_count DESC;

-- Q11. Display users who have made more than one reservation.
SELECT u.user_id, u.name, COUNT(r.reservation_id) AS reservation_count
FROM users u
JOIN reservation r ON r.user_id = u.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(r.reservation_id) > 1;

-- =========================================================
-- C. JOIN QUERIES
-- =========================================================

-- Q12. Display reservation details with customer and vehicle information.
SELECT
    r.reservation_id,
    u.name AS customer_name,
    v.registration_no,
    v.brand,
    v.model,
    r.start_time,
    r.end_time,
    r.status
FROM reservation r
JOIN users u ON r.user_id = u.user_id
JOIN vehicle v ON r.vehicle_id = v.vehicle_id
ORDER BY r.start_time;

-- Q13. Display parking sessions with vehicle and parking position details.
SELECT
    ps.session_id,
    v.registration_no,
    lp.position_number,
    pl.lift_code,
    ps.entry_time,
    ps.exit_time,
    ps.status
FROM parking_session ps
JOIN vehicle v ON ps.vehicle_id = v.vehicle_id
JOIN lift_position lp ON ps.position_id = lp.position_id
JOIN parking_lift pl ON lp.lift_id = pl.lift_id
ORDER BY ps.session_id;

-- Q14. Display billing details along with customer and vehicle information.
SELECT
    b.bill_id,
    u.name AS customer_name,
    v.registration_no,
    b.total_amount,
    b.payment_status,
    b.payment_method
FROM billing b
JOIN parking_session ps ON b.session_id = ps.session_id
JOIN vehicle v ON ps.vehicle_id = v.vehicle_id
JOIN users u ON v.user_id = u.user_id
ORDER BY b.bill_id;

-- =========================================================
-- D. NESTED QUERIES
-- =========================================================

-- Q15. Find bills whose total amount is greater than the average bill amount.
SELECT bill_id, total_amount, payment_status
FROM billing
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM billing
);

-- Q16. Find users who have made at least one reservation.
SELECT user_id, name
FROM users
WHERE user_id IN (
    SELECT user_id
    FROM reservation
);

-- Q17. Find vehicles that have never been used in a parking session.
SELECT vehicle_id, registration_no
FROM vehicle
WHERE vehicle_id NOT IN (
    SELECT vehicle_id
    FROM parking_session
);

-- =========================================================
-- E. CORRELATED SUBQUERIES
-- =========================================================

-- Q18. Find users whose reservation count is greater than
-- the average reservation count per user (including users with zero).
SELECT u.user_id, u.name
FROM users u
WHERE (
    SELECT COUNT(*)
    FROM reservation r
    WHERE r.user_id = u.user_id
) > (
    SELECT AVG(reservation_count)
    FROM (
        SELECT COUNT(r2.reservation_id) AS reservation_count
        FROM users u2
        LEFT JOIN reservation r2 ON r2.user_id = u2.user_id
        GROUP BY u2.user_id
    ) AS user_reservation_counts
);

-- Q19. Find each user's most recent reservation.
SELECT r.reservation_id, r.user_id, r.start_time, r.status
FROM reservation r
WHERE r.start_time = (
    SELECT MAX(r2.start_time)
    FROM reservation r2
    WHERE r2.user_id = r.user_id
)
ORDER BY r.user_id;

-- Q20. Find bills greater than the average bill for their payment status.
SELECT b.bill_id, b.payment_status, b.total_amount
FROM billing b
WHERE b.total_amount > (
    SELECT AVG(b2.total_amount)
    FROM billing b2
    WHERE b2.payment_status = b.payment_status
);

-- =========================================================
-- F. UPDATE OPERATION - SAFE DEMONSTRATION
-- The transaction is rolled back to preserve original sample data.
-- =========================================================

START TRANSACTION;

UPDATE users
SET phone = '9000000000'
WHERE user_id = 4;

SELECT user_id, name, phone
FROM users
WHERE user_id = 4;

ROLLBACK;

-- Verify that the original phone number is restored.
SELECT user_id, name, phone
FROM users
WHERE user_id = 4;

-- =========================================================
-- G. DELETE OPERATION - SAFE DEMONSTRATION
-- The transaction is rolled back to preserve original sample data.
-- =========================================================

START TRANSACTION;

DELETE FROM violation
WHERE violation_id = 5;

SELECT *
FROM violation
WHERE violation_id = 5;

ROLLBACK;

-- Verify that the deleted demonstration row is restored.
SELECT *
FROM violation
WHERE violation_id = 5;

-- =========================================================
-- END OF PHASE 3 QUERIES
-- =========================================================
