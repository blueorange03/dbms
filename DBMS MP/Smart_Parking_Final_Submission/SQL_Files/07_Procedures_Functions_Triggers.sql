USE automated_parking_db;

-- =========================================================
-- PHASE 4: STORED FUNCTION, PROCEDURES AND TRIGGERS
-- MySQL 8.0
--
-- This implements database-side workflow support:
-- 1. Validate and create reservations.
-- 2. Mark a reserved lift as POSITIONING (a database simulation
--    of the automated lift command; no physical lift hardware is connected).
-- 3. Calculate bills consistently.
-- 4. Release a parking position when a session is completed.
--
-- Run this file once. It drops same-named routines/triggers first
-- so that the file can be rerun safely.
-- =========================================================

DROP TRIGGER IF EXISTS trg_reservation_after_insert;
DROP TRIGGER IF EXISTS trg_billing_before_insert;
DROP TRIGGER IF EXISTS trg_session_after_update;

DROP PROCEDURE IF EXISTS sp_create_reservation;
DROP PROCEDURE IF EXISTS sp_prepare_lift_for_reservation;
DROP PROCEDURE IF EXISTS sp_complete_parking_session;

DROP FUNCTION IF EXISTS fn_calculate_bill_total;

DELIMITER $$

-- ---------------------------------------------------------
-- FUNCTION 1: Calculate the final bill amount.
-- Tax is supplied as an amount, not a percentage.
-- ---------------------------------------------------------
CREATE FUNCTION fn_calculate_bill_total(
    p_base_charge DECIMAL(10,2),
    p_lift_charge DECIMAL(10,2),
    p_reservation_charge DECIMAL(10,2),
    p_duration_charge DECIMAL(10,2),
    p_tax DECIMAL(10,2),
    p_discount DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(
        COALESCE(p_base_charge, 0) +
        COALESCE(p_lift_charge, 0) +
        COALESCE(p_reservation_charge, 0) +
        COALESCE(p_duration_charge, 0) +
        COALESCE(p_tax, 0) -
        COALESCE(p_discount, 0),
        2
    );
END$$

-- ---------------------------------------------------------
-- TRIGGER 1: Calculate total_amount automatically before
-- a new billing row is inserted.
-- ---------------------------------------------------------
CREATE TRIGGER trg_billing_before_insert
BEFORE INSERT ON billing
FOR EACH ROW
BEGIN
    SET NEW.total_amount = fn_calculate_bill_total(
        NEW.base_charge,
        NEW.lift_charge,
        NEW.reservation_charge,
        NEW.duration_charge,
        NEW.tax,
        NEW.discount
    );
END$$

-- ---------------------------------------------------------
-- PROCEDURE 1: Create a reservation after validating:
-- - valid time interval
-- - vehicle belongs to the given user
-- - requested position is available
-- - vehicle type matches the position
-- - no overlapping active reservation for that position
-- ---------------------------------------------------------
CREATE PROCEDURE sp_create_reservation(
    IN p_user_id INT,
    IN p_vehicle_id INT,
    IN p_position_id INT,
    IN p_start_time DATETIME,
    IN p_end_time DATETIME
)
BEGIN
    DECLARE v_owner_id INT DEFAULT NULL;
    DECLARE v_vehicle_type VARCHAR(20) DEFAULT NULL;
    DECLARE v_position_type VARCHAR(20) DEFAULT NULL;
    DECLARE v_position_status VARCHAR(30) DEFAULT NULL;
    DECLARE v_conflicts INT DEFAULT 0;

    IF p_start_time IS NULL OR p_end_time IS NULL OR p_end_time <= p_start_time THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid reservation time interval';
    END IF;

    SELECT user_id, vehicle_type
    INTO v_owner_id, v_vehicle_type
    FROM vehicle
    WHERE vehicle_id = p_vehicle_id;

    IF v_owner_id IS NULL OR v_owner_id <> p_user_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vehicle does not belong to the specified user';
    END IF;

    SELECT vehicle_type, status
    INTO v_position_type, v_position_status
    FROM lift_position
    WHERE position_id = p_position_id;

    IF v_position_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking position does not exist';
    END IF;

    IF v_position_status <> 'AVAILABLE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking position is not available';
    END IF;

    IF v_vehicle_type <> v_position_type THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Vehicle type does not match parking position';
    END IF;

    SELECT COUNT(*)
    INTO v_conflicts
    FROM reservation
    WHERE position_id = p_position_id
      AND status IN ('CONFIRMED', 'COMPLETED')
      AND start_time < p_end_time
      AND end_time > p_start_time;

    IF v_conflicts > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking position already has an overlapping reservation';
    END IF;

    INSERT INTO reservation
        (user_id, vehicle_id, position_id, start_time, end_time, status, booking_time)
    VALUES
        (p_user_id, p_vehicle_id, p_position_id,
         p_start_time, p_end_time, 'CONFIRMED', NOW());
END$$

-- ---------------------------------------------------------
-- TRIGGER 2: Mark a position RESERVED when a confirmed
-- reservation is inserted.
-- ---------------------------------------------------------
CREATE TRIGGER trg_reservation_after_insert
AFTER INSERT ON reservation
FOR EACH ROW
BEGIN
    IF NEW.status = 'CONFIRMED' THEN
        UPDATE lift_position
        SET status = 'RESERVED'
        WHERE position_id = NEW.position_id;
    END IF;
END$$

-- ---------------------------------------------------------
-- PROCEDURE 2: Prepare the lift associated with a confirmed
-- reservation. POSITIONING is a simulated controller state.
-- ---------------------------------------------------------
CREATE PROCEDURE sp_prepare_lift_for_reservation(
    IN p_reservation_id INT
)
BEGIN
    DECLARE v_lift_id INT DEFAULT NULL;
    DECLARE v_reservation_status VARCHAR(30) DEFAULT NULL;

    SELECT pl.lift_id, r.status
    INTO v_lift_id, v_reservation_status
    FROM reservation r
    JOIN lift_position lp ON r.position_id = lp.position_id
    JOIN parking_lift pl ON lp.lift_id = pl.lift_id
    WHERE r.reservation_id = p_reservation_id;

    IF v_lift_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reservation or associated lift not found';
    END IF;

    IF v_reservation_status <> 'CONFIRMED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only confirmed reservations can prepare a lift';
    END IF;

    UPDATE parking_lift
    SET lift_status = 'POSITIONING'
    WHERE lift_id = v_lift_id;
END$$

-- ---------------------------------------------------------
-- TRIGGER 3: When a parking session changes to COMPLETED,
-- release the position, reset the lift, and complete the reservation.
-- ---------------------------------------------------------
CREATE TRIGGER trg_session_after_update
AFTER UPDATE ON parking_session
FOR EACH ROW
BEGIN
    IF NEW.status = 'COMPLETED'
       AND (OLD.status IS NULL OR OLD.status <> 'COMPLETED') THEN
        -- Release the parking position.
        UPDATE lift_position
        SET status = 'AVAILABLE'
        WHERE position_id = NEW.position_id;

        -- Return the associated lift to operational state.
        UPDATE parking_lift pl
        JOIN lift_position lp ON lp.lift_id = pl.lift_id
        SET pl.lift_status = 'OPERATIONAL'
        WHERE lp.position_id = NEW.position_id;

        -- Mark the related reservation as completed.
        UPDATE reservation
        SET status = 'COMPLETED'
        WHERE reservation_id = NEW.reservation_id;
    END IF;
END$$

-- ---------------------------------------------------------
-- PROCEDURE 3: Complete a parking session.
-- The AFTER UPDATE trigger above releases its position.
-- ---------------------------------------------------------
CREATE PROCEDURE sp_complete_parking_session(
    IN p_session_id INT
)
BEGIN
    DECLARE v_session_status VARCHAR(30) DEFAULT NULL;

    SELECT status
    INTO v_session_status
    FROM parking_session
    WHERE session_id = p_session_id;

    IF v_session_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking session not found';
    END IF;

    IF v_session_status = 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking session is already completed';
    END IF;

    UPDATE parking_session
    SET exit_time = NOW(),
        status = 'COMPLETED'
    WHERE session_id = p_session_id;
END$$

DELIMITER ;

-- =========================================================
-- VERIFY ROUTINES AND TRIGGERS
-- =========================================================
SHOW FUNCTION STATUS
WHERE Db = 'automated_parking_db';

SHOW PROCEDURE STATUS
WHERE Db = 'automated_parking_db';

SHOW TRIGGERS
FROM automated_parking_db;

-- =========================================================
-- OPTIONAL MANUAL TESTS
-- Run these separately after reviewing the existing data.
--
-- 1. Test billing function:
-- SELECT fn_calculate_bill_total(30, 10, 15, 40, 5, 0) AS bill_total;
-- Expected: 100.00
--
-- 2. Test lift preparation using a confirmed reservation:
-- CALL sp_prepare_lift_for_reservation(2);
-- SELECT lift_id, lift_status FROM parking_lift;
--
-- 3. Test reservation creation only with a genuinely available,
--    type-compatible position and a non-overlapping future time.
-- Example (verify position 4 is AVAILABLE before running):
-- CALL sp_create_reservation(
--     19, 19, 4,
--     '2026-11-08 10:00:00',
--     '2026-11-08 12:00:00'
-- );
--
-- 4. Test session completion only on a session not already completed:
-- CALL sp_complete_parking_session(2);
-- =========================================================
