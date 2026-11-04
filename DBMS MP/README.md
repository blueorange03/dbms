# Parkwise — Smart Parking Reservation & Violation Management

A Flask and MySQL application for the existing `automated_parking_db` project. It uses the 10 existing tables and the supplied procedures, function, and triggers. The application never creates, drops, or migrates the database.

## Database review

All supplied SQL files were reviewed:

- `Smart_Parking_Final_Submission/SQL_Files/01_Database_Creation.sql` through `07_Procedures_Functions_Triggers.sql`
- `team16_DDL.sql` (duplicate table DDL)

`02_Table_Creation_DDL.sql` is the schema source. Relationships follow its foreign keys: users own vehicles; facilities contain zones, lifts and lift positions; reservations connect users, vehicles and positions; sessions connect reservations, vehicles and positions; billing belongs to sessions; violations reference vehicles, sessions, positions, and reporting users. The SQL seed scripts use placeholder passwords such as `demo_hash_user4`, so they are not usable login credentials.

The app relies on the existing `sp_create_reservation`, `sp_prepare_lift_for_reservation`, and `sp_complete_parking_session` routines. `trg_reservation_after_insert` updates the position state; `trg_session_after_update` releases it on completion; `trg_billing_before_insert` uses `fn_calculate_bill_total`. Lift positioning is represented only by a database status. There is no lift hardware connection.

## Features

- Customer registration and sign in with Werkzeug password hashing
- Customer vehicle add/list/remove (foreign keys preserve vehicles with history)
- Availability dashboard with position and lift state
- Advance reservation creation through the stored procedure
- Simulated lift positioning for confirmed reservations
- Admin vehicle entry and exit tracking, using the session procedure on exit
- Bill and payment status views; marking a bill paid is a demonstration action, not a payment gateway
- Admin console for facilities/lift records, users and violations
- Violation reporting, status management and demonstration penalty payment
- Parameterized SQL values and session-based access checks

## Requirements

- macOS with Python 3.10 or later
- MySQL Server 8.0 with the existing `automated_parking_db`
- Existing tables, routines, and triggers installed

## Setup on macOS

1. Start MySQL and verify the existing database is available. Do not rerun the seed scripts against a populated database. If the routines/triggers are not installed yet, review `07_Procedures_Functions_Triggers.sql` first; it drops and recreates same-named routines/triggers.
2. From this project directory, create and activate a virtual environment:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Create local configuration from the example and edit it:

   ```bash
   cp .env.example .env
   ```

   Set `FLASK_SECRET_KEY`, `DB_HOST`, `DB_PORT`, `DB_USER`, and `DB_PASSWORD`. Keep `.env` private; it is ignored by git.
4. Load the values into your shell. One simple option is:

   ```bash
   set -a
   source .env
   set +a
   ```

5. Run the web application:

   ```bash
   python run.py
   ```

   Open <http://127.0.0.1:5001> (port 5000 is commonly occupied by macOS AirPlay Receiver).

## First account and admin access

Register a new customer through the sign-up page. New accounts get a Werkzeug password hash in the existing `users.password` field. The existing 28 demo accounts were given unique temporary passwords during connection setup. Their emails and passwords are in the owner-only, git-ignored `demo_account_credentials.csv` file. The admin account email is `admin@smartparking.example`.

To reset any one account later, run:

```bash
flask --app run.py set-password admin@smartparking.example
```

Flask prompts for the password (minimum eight characters). The account retains its existing `user_type`. This command updates only that row's password and does not change the schema.

## Workflow notes

- Position availability is determined by the existing `lift_position.status` and lift operational state.
- The reservation procedure validates vehicle ownership, type, position status, and overlapping reservations. The supplied trigger changes a position to `RESERVED` after a confirmed reservation.
- Admin entry changes a `NOT_STARTED` session to `ACTIVE` and marks its position `OCCUPIED`. Admin exit calls `sp_complete_parking_session`; its trigger frees the position and completes the reservation.
- Bills/penalties can be marked paid for demonstration. No payment processor is connected.
- Facility and lift creation use existing columns. Admins can add lift positions explicitly from the admin console; configure only the lift's actual capacity.
- The SQL examples use dated sample activity and placeholder passwords. Register a fresh user for authentication and check current position state in your database before demonstrating reservations.

## Major feature verification

The configured MySQL connection was verified against `automated_parking_db`; it contains 28 existing user accounts, and every generated demo credential was checked against its stored password hash. Complete browser verification by signing in with the credentials in `demo_account_credentials.csv` and exercising registration, vehicle management, reservations, admin entry/exit, billing, and violations.
