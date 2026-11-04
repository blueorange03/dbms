USE automated_parking_db;

-- Add 25 additional customer accounts (existing user IDs are 1-3).
-- This brings the users table to 28 records in total.
INSERT INTO users (user_id, name, email, phone, password, user_type) VALUES
(4, 'Rohan Mehta', 'rohan.mehta@example.com', '9876501004', 'demo_hash_user4', 'CUSTOMER'),
(5, 'Ananya Rao', 'ananya.rao@example.com', '9876501005', 'demo_hash_user5', 'CUSTOMER'),
(6, 'Karthik Iyer', 'karthik.iyer@example.com', '9876501006', 'demo_hash_user6', 'CUSTOMER'),
(7, 'Meera Krishnan', 'meera.krishnan@example.com', '9876501007', 'demo_hash_user7', 'CUSTOMER'),
(8, 'Aditya Kulkarni', 'aditya.kulkarni@example.com', '9876501008', 'demo_hash_user8', 'CUSTOMER'),
(9, 'Sneha Reddy', 'sneha.reddy@example.com', '9876501009', 'demo_hash_user9', 'CUSTOMER'),
(10, 'Arjun Menon', 'arjun.menon@example.com', '9876501010', 'demo_hash_user10', 'CUSTOMER'),
(11, 'Ishita Gupta', 'ishita.gupta@example.com', '9876501011', 'demo_hash_user11', 'CUSTOMER'),
(12, 'Vikram Shetty', 'vikram.shetty@example.com', '9876501012', 'demo_hash_user12', 'CUSTOMER'),
(13, 'Pooja Desai', 'pooja.desai@example.com', '9876501013', 'demo_hash_user13', 'CUSTOMER'),
(14, 'Rahul Verma', 'rahul.verma@example.com', '9876501014', 'demo_hash_user14', 'CUSTOMER'),
(15, 'Nisha Thomas', 'nisha.thomas@example.com', '9876501015', 'demo_hash_user15', 'CUSTOMER'),
(16, 'Sanjay Rao', 'sanjay.rao@example.com', '9876501016', 'demo_hash_user16', 'CUSTOMER'),
(17, 'Aditi Shah', 'aditi.shah@example.com', '9876501017', 'demo_hash_user17', 'CUSTOMER'),
(18, 'Manish Jain', 'manish.jain@example.com', '9876501018', 'demo_hash_user18', 'CUSTOMER'),
(19, 'Kavya Pillai', 'kavya.pillai@example.com', '9876501019', 'demo_hash_user19', 'CUSTOMER'),
(20, 'Varun Hegde', 'varun.hegde@example.com', '9876501020', 'demo_hash_user20', 'CUSTOMER'),
(21, 'Priya Nambiar', 'priya.nambiar@example.com', '9876501021', 'demo_hash_user21', 'CUSTOMER'),
(22, 'Nikhil Bhat', 'nikhil.bhat@example.com', '9876501022', 'demo_hash_user22', 'CUSTOMER'),
(23, 'Sanya Kapoor', 'sanya.kapoor@example.com', '9876501023', 'demo_hash_user23', 'CUSTOMER'),
(24, 'Deepak Kumar', 'deepak.kumar@example.com', '9876501024', 'demo_hash_user24', 'CUSTOMER'),
(25, 'Ritika Sinha', 'ritika.sinha@example.com', '9876501025', 'demo_hash_user25', 'CUSTOMER'),
(26, 'Harish Gowda', 'harish.gowda@example.com', '9876501026', 'demo_hash_user26', 'CUSTOMER'),
(27, 'Tanya Bose', 'tanya.bose@example.com', '9876501027', 'demo_hash_user27', 'CUSTOMER'),
(28, 'Abhishek Das', 'abhishek.das@example.com', '9876501028', 'demo_hash_user28', 'CUSTOMER');

-- Add one vehicle for each new customer (existing vehicle IDs are 1-3).
INSERT INTO vehicle (vehicle_id, user_id, registration_no, vehicle_type, brand, model, color, weight_kg) VALUES
(4, 4, 'KA05EL1004', 'CAR', 'Maruti Suzuki', 'Baleno', 'Silver', 1080.00),
(5, 5, 'KA06FM1005', 'CAR', 'Honda', 'City', 'Grey', 1200.00),
(6, 6, 'KA07GN1006', 'CAR', 'Toyota', 'Glanza', 'Red', 1050.00),
(7, 7, 'KA08HO1007', 'CAR', 'Hyundai', 'Creta', 'White', 1400.00),
(8, 8, 'KA09IP1008', 'CAR', 'Kia', 'Seltos', 'Black', 1350.00),
(9, 9, 'KA10JQ1009', 'CAR', 'Tata', 'Punch', 'Blue', 1100.00),
(10, 10, 'KA11KR1010', 'BIKE', 'Honda', 'Activa 6G', 'White', 109.00),
(11, 11, 'KA12LS1011', 'BIKE', 'TVS', 'Jupiter', 'Grey', 108.00),
(12, 12, 'KA13MT1012', 'BIKE', 'Royal Enfield', 'Classic 350', 'Black', 195.00),
(13, 13, 'KA14NU1013', 'BIKE', 'Bajaj', 'Pulsar 150', 'Blue', 148.00),
(14, 14, 'KA15OV1014', 'CAR', 'Maruti Suzuki', 'Swift', 'White', 950.00),
(15, 15, 'KA16PW1015', 'CAR', 'Volkswagen', 'Polo', 'Blue', 1150.00),
(16, 16, 'KA17QX1016', 'CAR', 'Hyundai', 'Venue', 'Silver', 1250.00),
(17, 17, 'KA18RY1017', 'CAR', 'Mahindra', 'XUV300', 'Red', 1300.00),
(18, 18, 'KA19SZ1018', 'CAR', 'Honda', 'Amaze', 'Grey', 1050.00),
(19, 19, 'KA20TA1019', 'BIKE', 'Suzuki', 'Access 125', 'Black', 104.00),
(20, 20, 'KA21UB1020', 'BIKE', 'Yamaha', 'FZ-S', 'Blue', 135.00),
(21, 21, 'KA22VC1021', 'BIKE', 'Ather', '450X', 'White', 111.00),
(22, 22, 'KA23WD1022', 'CAR', 'Tata', 'Tiago', 'Orange', 1080.00),
(23, 23, 'KA24XE1023', 'CAR', 'Renault', 'Kwid', 'White', 760.00),
(24, 24, 'KA25YF1024', 'BIKE', 'TVS', 'Apache RTR 160', 'Red', 139.00),
(25, 25, 'KA26ZG1025', 'BIKE', 'KTM', 'Duke 200', 'Orange', 159.00),
(26, 26, 'KA27AH1026', 'CAR', 'Toyota', 'Innova Crysta', 'White', 1800.00),
(27, 27, 'KA28BI1027', 'CAR', 'Skoda', 'Slavia', 'Grey', 1250.00),
(28, 28, 'KA29CJ1028', 'CAR', 'Hyundai', 'Verna', 'Black', 1200.00);

-- Verify counts
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_vehicles FROM vehicle;
SELECT user_id, name, email, user_type FROM users ORDER BY user_id;
