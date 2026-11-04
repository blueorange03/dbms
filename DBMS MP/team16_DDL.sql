-- CREATE DATABASE automated_parking_db;

-- USE automated_parking_db;

-- USER
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(15),
    password VARCHAR(255),
    user_type VARCHAR(20)
);

-- VEHICLE
CREATE TABLE vehicle (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    registration_no VARCHAR(20) UNIQUE,
    vehicle_type VARCHAR(20),
    brand VARCHAR(50),
    model VARCHAR(50),
    color VARCHAR(30),
    weight_kg DECIMAL(8,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- PARKING FACILITY
CREATE TABLE parking_facility (
    facility_id INT AUTO_INCREMENT PRIMARY KEY,
    facility_name VARCHAR(150),
    location VARCHAR(200),
    operating_hours VARCHAR(100),
    contact_number VARCHAR(15)
);

-- PARKING ZONE
CREATE TABLE parking_zone (
    zone_id INT AUTO_INCREMENT PRIMARY KEY,
    facility_id INT NOT NULL,
    zone_name VARCHAR(100),
    zone_type VARCHAR(30),
    location VARCHAR(150),
    capacity INT,
    FOREIGN KEY (facility_id) REFERENCES parking_facility(facility_id)
);

-- PARKING LIFT
CREATE TABLE parking_lift (
    lift_id INT AUTO_INCREMENT PRIMARY KEY,
    zone_id INT NOT NULL,
    lift_code VARCHAR(30) UNIQUE,
    lift_type VARCHAR(30),
    capacity INT,
    max_load_kg DECIMAL(10,2),
    lift_status VARCHAR(30),
    FOREIGN KEY (zone_id) REFERENCES parking_zone(zone_id)
);

-- LIFT POSITION
CREATE TABLE lift_position (
    position_id INT AUTO_INCREMENT PRIMARY KEY,
    lift_id INT NOT NULL,
    position_number INT NOT NULL,
    vehicle_type VARCHAR(20),
    status VARCHAR(30),
    UNIQUE (lift_id, position_number),
    FOREIGN KEY (lift_id) REFERENCES parking_lift(lift_id)
);

-- RESERVATION
CREATE TABLE reservation (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    position_id INT NOT NULL,
    start_time DATETIME,
    end_time DATETIME,
    status VARCHAR(30),
    booking_time DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    FOREIGN KEY (position_id) REFERENCES lift_position(position_id)
);

-- PARKING SESSION
CREATE TABLE parking_session (
    session_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNIQUE,
    vehicle_id INT NOT NULL,
    position_id INT NOT NULL,
    entry_time DATETIME,
    exit_time DATETIME,
    status VARCHAR(30),
    FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    FOREIGN KEY (position_id) REFERENCES lift_position(position_id)
);

-- BILLING
CREATE TABLE billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL UNIQUE,
    base_charge DECIMAL(10,2),
    lift_charge DECIMAL(10,2),
    reservation_charge DECIMAL(10,2),
    duration_charge DECIMAL(10,2),
    tax DECIMAL(10,2),
    discount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    payment_status VARCHAR(30),
    payment_method VARCHAR(30),
    transaction_reference VARCHAR(100) UNIQUE,
    payment_time DATETIME,
    FOREIGN KEY (session_id) REFERENCES parking_session(session_id)
);

-- VIOLATION
CREATE TABLE violation (
    violation_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    session_id INT,
    position_id INT NOT NULL,
    violation_type VARCHAR(100),
    description VARCHAR(255),
    fine_amount DECIMAL(10,2),
    reported_by INT NOT NULL,
    violation_time DATETIME,
    status VARCHAR(30),
    penalty_status VARCHAR(30),
    penalty_payment_method VARCHAR(30),
    penalty_payment_date DATETIME,
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id),
    FOREIGN KEY (session_id) REFERENCES parking_session(session_id),
    FOREIGN KEY (position_id) REFERENCES lift_position(position_id),
    FOREIGN KEY (reported_by) REFERENCES users(user_id)
);


SHOW TABLES;

USE automated_parking_db;

DESCRIBE users;
DESCRIBE vehicle;
DESCRIBE parking_facility;
DESCRIBE parking_zone;
DESCRIBE parking_lift;
DESCRIBE lift_position;
DESCRIBE reservation;
DESCRIBE parking_session;
DESCRIBE billing;
DESCRIBE violation;


SELECT
    TABLE_NAME AS `Table`,
    COLUMN_NAME AS `Column`,
    COLUMN_TYPE AS `Type`,
    IS_NULLABLE AS `Nullable`,
    COLUMN_KEY AS `Key`
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'automated_parking_db'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
