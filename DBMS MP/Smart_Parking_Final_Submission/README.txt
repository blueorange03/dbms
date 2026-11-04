SMART PARKING SLOT RESERVATION & VIOLATION MANAGEMENT SYSTEM
SQL submission package

Run these files in numeric order on a fresh MySQL 8.0 database:
01_Database_Creation.sql
02_Table_Creation_DDL.sql
03_Sample_Data_DML.sql
04_Additional_Users_and_Vehicles.sql
05_Activity_Data.sql
06_Queries.sql
07_Procedures_Functions_Triggers.sql

Important:
- Run the data scripts only once on a fresh database. They insert fixed IDs.
- File 06 contains demonstration UPDATE and DELETE statements wrapped in
  transactions and rolled back.
- File 07 creates 3 stored procedures, 1 stored function and 3 triggers.
- The lift POSITIONING state is a database simulation; physical lift movement
  requires a separate hardware/controller integration.
- The user's live database also contains a one-off test reservation/session
  (reservation 19/session 17); that test data is not part of the clean seed scripts.
