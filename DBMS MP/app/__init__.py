import os
from datetime import datetime
from decimal import Decimal

import click
import mysql.connector
from flask import Flask, abort, flash, g, redirect, render_template, request, session, url_for
from mysql.connector import Error
from werkzeug.security import check_password_hash, generate_password_hash


def create_app():
    app = Flask(__name__)
    app.config.update(
        SECRET_KEY=os.environ.get("FLASK_SECRET_KEY", "change-this-development-secret"),
        MYSQL_HOST=os.environ.get("DB_HOST", "127.0.0.1"),
        MYSQL_PORT=int(os.environ.get("DB_PORT", "3306")),
        MYSQL_USER=os.environ.get("DB_USER", "root"),
        MYSQL_PASSWORD=os.environ.get("DB_PASSWORD", ""),
        MYSQL_DATABASE=os.environ.get("DB_NAME", "automated_parking_db"),
        SESSION_COOKIE_HTTPONLY=True,
        SESSION_COOKIE_SAMESITE="Lax",
        SESSION_COOKIE_SECURE=os.environ.get("SESSION_COOKIE_SECURE", "false").lower() == "true",
    )

    def connect():
        return mysql.connector.connect(
            host=app.config["MYSQL_HOST"], port=app.config["MYSQL_PORT"],
            user=app.config["MYSQL_USER"], password=app.config["MYSQL_PASSWORD"],
            database=app.config["MYSQL_DATABASE"], charset="utf8mb4",
        )

    def query(sql, params=(), one=False):
        conn = connect()
        cur = conn.cursor(dictionary=True)
        try:
            cur.execute(sql, params)
            rows = cur.fetchone() if one else cur.fetchall()
            return rows
        finally:
            cur.close()
            conn.close()

    def execute(sql, params=(), commit=True):
        conn = connect()
        cur = conn.cursor(dictionary=True)
        try:
            cur.execute(sql, params)
            if commit:
                conn.commit()
            return cur.lastrowid, cur
        except Exception:
            conn.rollback()
            raise
        finally:
            cur.close()
            conn.close()

    def current_user():
        if "user" not in g:
            g.user = query("SELECT user_id,name,email,user_type FROM users WHERE user_id=%s", (session.get("user_id"),), one=True) if session.get("user_id") else None
        return g.user

    @app.before_request
    def load_user():
        g.user = current_user()

    @app.context_processor
    def inject_user():
        return {"current_user": current_user(), "now": datetime.now}

    def login_required(fn):
        from functools import wraps
        @wraps(fn)
        def wrapped(*args, **kwargs):
            if not current_user():
                return redirect(url_for("login", next=request.path))
            return fn(*args, **kwargs)
        return wrapped

    def admin_required(fn):
        from functools import wraps
        @wraps(fn)
        def wrapped(*args, **kwargs):
            user = current_user()
            if not user:
                return redirect(url_for("login", next=request.path))
            if user["user_type"] != "ADMIN":
                abort(403)
            return fn(*args, **kwargs)
        return wrapped

    @app.errorhandler(Error)
    def database_error(error):
        app.logger.exception("Database operation failed", exc_info=error)
        flash("Could not complete the database request. Check the Flask Terminal output, .env connection settings, MySQL service, and existing database tables.", "danger")
        return redirect(request.referrer or url_for("dashboard"))

    @app.route("/")
    def index():
        return redirect(url_for("dashboard")) if current_user() else redirect(url_for("login"))

    @app.route("/register", methods=["GET", "POST"])
    def register():
        if request.method == "POST":
            name, email = request.form.get("name", "").strip(), request.form.get("email", "").strip().lower()
            password, phone = request.form.get("password", ""), request.form.get("phone", "").strip()
            if not name or not email or len(password) < 8:
                flash("Enter your name and email, and choose a password with at least 8 characters.", "warning")
            else:
                execute("INSERT INTO users (name,email,phone,password,user_type) VALUES (%s,%s,%s,%s,'CUSTOMER')",
                        (name, email, phone, generate_password_hash(password)))
                flash("Account created. Sign in to continue.", "success")
                return redirect(url_for("login"))
        return render_template("auth.html", mode="register")

    @app.route("/login", methods=["GET", "POST"])
    def login():
        if request.method == "POST":
            user = query("SELECT user_id,name,email,password,user_type FROM users WHERE email=%s", (request.form.get("email", "").strip().lower(),), one=True)
            password_matches = False
            if user and user.get("password"):
                try:
                    password_matches = check_password_hash(user["password"], request.form.get("password", ""))
                except (ValueError, TypeError):
                    # Seed scripts contain demo_hash_* placeholders, not password hashes.
                    password_matches = False
            if user and password_matches:
                session.clear()
                session["user_id"] = user["user_id"]
                return redirect(request.args.get("next") or url_for("dashboard"))
            flash("Email or password is incorrect. Existing demo accounts need a password reset by an admin.", "danger")
        return render_template("auth.html", mode="login")

    @app.route("/logout", methods=["POST"])
    def logout():
        session.clear()
        return redirect(url_for("login"))

    @app.route("/dashboard")
    @login_required
    def dashboard():
        user = current_user()
        is_admin = user["user_type"] == "ADMIN"
        if is_admin:
            stats = query("""SELECT (SELECT COUNT(*) FROM lift_position WHERE status='AVAILABLE') available,
              (SELECT COUNT(*) FROM lift_position) total_positions,
              (SELECT COUNT(*) FROM reservation WHERE status='CONFIRMED') active_reservations,
              (SELECT COUNT(*) FROM parking_session WHERE status='ACTIVE') active_sessions,
              (SELECT COUNT(*) FROM violation WHERE penalty_status='UNPAID') open_violations,
              (SELECT COUNT(*) FROM users) total_users""", one=True)
            reservations = query("""SELECT r.reservation_id,u.name customer,v.registration_no,lp.position_number,r.start_time,r.end_time,r.status
              FROM reservation r JOIN users u ON u.user_id=r.user_id JOIN vehicle v ON v.vehicle_id=r.vehicle_id
              JOIN lift_position lp ON lp.position_id=r.position_id ORDER BY r.booking_time DESC LIMIT 8""")
        else:
            stats = query("""SELECT (SELECT COUNT(*) FROM lift_position WHERE status='AVAILABLE') available,
              (SELECT COUNT(*) FROM lift_position) total_positions,
              (SELECT COUNT(*) FROM reservation WHERE user_id=%s AND status='CONFIRMED') active_reservations,
              (SELECT COUNT(*) FROM parking_session ps JOIN vehicle v ON v.vehicle_id=ps.vehicle_id WHERE v.user_id=%s AND ps.status='ACTIVE') active_sessions,
              (SELECT COUNT(*) FROM violation vi JOIN vehicle v ON v.vehicle_id=vi.vehicle_id WHERE v.user_id=%s AND vi.penalty_status='UNPAID') open_violations,
              (SELECT COUNT(*) FROM vehicle WHERE user_id=%s) total_users""", (user["user_id"],)*4, one=True)
            reservations = query("""SELECT r.reservation_id,v.registration_no,lp.position_number,r.start_time,r.end_time,r.status
              FROM reservation r JOIN vehicle v ON v.vehicle_id=r.vehicle_id JOIN lift_position lp ON lp.position_id=r.position_id
              WHERE r.user_id=%s ORDER BY r.booking_time DESC LIMIT 8""", (user["user_id"],))
        positions = query("""SELECT lp.position_id,lp.position_number,lp.vehicle_type,lp.status,pl.lift_code,pl.lift_status,
          pz.zone_name,pf.facility_name FROM lift_position lp JOIN parking_lift pl ON pl.lift_id=lp.lift_id
          JOIN parking_zone pz ON pz.zone_id=pl.zone_id JOIN parking_facility pf ON pf.facility_id=pz.facility_id
          ORDER BY pf.facility_name,pz.zone_name,pl.lift_code,lp.position_number LIMIT 12""")
        lifts = query("""SELECT pl.lift_id,pl.lift_code,pl.lift_status,pz.zone_name,
          SUM(lp.status='AVAILABLE') available,SUM(lp.status IN ('OCCUPIED','RESERVED')) in_use,COUNT(lp.position_id) capacity
          FROM parking_lift pl JOIN parking_zone pz ON pz.zone_id=pl.zone_id LEFT JOIN lift_position lp ON lp.lift_id=pl.lift_id
          GROUP BY pl.lift_id,pl.lift_code,pl.lift_status,pz.zone_name ORDER BY pl.lift_code""")
        return render_template("dashboard.html", stats=stats, reservations=reservations, positions=positions, lifts=lifts, is_admin=is_admin)

    @app.route("/vehicles", methods=["GET", "POST"])
    @login_required
    def vehicles():
        user = current_user()
        if request.method == "POST":
            try:
                execute("INSERT INTO vehicle (user_id,registration_no,vehicle_type,brand,model,color,weight_kg) VALUES (%s,%s,%s,%s,%s,%s,%s)",
                        (user["user_id"], request.form["registration_no"].strip().upper(), request.form["vehicle_type"], request.form.get("brand", "").strip(), request.form.get("model", "").strip(), request.form.get("color", "").strip(), request.form.get("weight_kg") or None))
                flash("Vehicle added to your account.", "success")
                return redirect(url_for("vehicles"))
            except Error as e:
                if getattr(e, "errno", None) == 1062:
                    flash("That registration number is already registered.", "warning")
                else:
                    raise
        rows = query("SELECT * FROM vehicle WHERE user_id=%s ORDER BY vehicle_id DESC", (user["user_id"],))
        return render_template("vehicles.html", vehicles=rows)

    @app.post("/vehicles/<int:vehicle_id>/delete")
    @login_required
    def delete_vehicle(vehicle_id):
        execute("DELETE FROM vehicle WHERE vehicle_id=%s AND user_id=%s", (vehicle_id, current_user()["user_id"]))
        flash("Vehicle removed if it had no linked parking history.", "info")
        return redirect(url_for("vehicles"))

    @app.route("/reservations", methods=["GET", "POST"])
    @login_required
    def reservations():
        user = current_user()
        if request.method == "POST":
            start = datetime.fromisoformat(request.form["start_time"])
            end = datetime.fromisoformat(request.form["end_time"])
            if end <= start or start < datetime.now():
                flash("Choose a future start time and a later end time.", "warning")
            else:
                conn = connect(); cur = conn.cursor()
                try:
                    cur.callproc("sp_create_reservation", (user["user_id"], int(request.form["vehicle_id"]), int(request.form["position_id"]), start, end))
                    conn.commit()
                    flash("Reservation confirmed.", "success")
                finally:
                    cur.close(); conn.close()
                return redirect(url_for("reservations"))
        rows = query("""SELECT r.reservation_id,v.registration_no,lp.position_number,pl.lift_code,pf.facility_name,pz.zone_name,
          r.start_time,r.end_time,r.booking_time,r.status FROM reservation r JOIN vehicle v ON v.vehicle_id=r.vehicle_id
          JOIN lift_position lp ON lp.position_id=r.position_id JOIN parking_lift pl ON pl.lift_id=lp.lift_id
          JOIN parking_zone pz ON pz.zone_id=pl.zone_id JOIN parking_facility pf ON pf.facility_id=pz.facility_id
          WHERE r.user_id=%s ORDER BY r.start_time DESC""", (user["user_id"],))
        vehicle_rows = query("SELECT vehicle_id,registration_no,vehicle_type FROM vehicle WHERE user_id=%s ORDER BY registration_no", (user["user_id"],))
        available = query("""SELECT lp.position_id,lp.position_number,lp.vehicle_type,pl.lift_code,pz.zone_name,pf.facility_name
          FROM lift_position lp JOIN parking_lift pl ON pl.lift_id=lp.lift_id JOIN parking_zone pz ON pz.zone_id=pl.zone_id
          JOIN parking_facility pf ON pf.facility_id=pz.facility_id WHERE lp.status='AVAILABLE' AND pl.lift_status='OPERATIONAL'
          ORDER BY pf.facility_name,pz.zone_name,pl.lift_code,lp.position_number""")
        return render_template("reservations.html", reservations=rows, vehicles=vehicle_rows, positions=available)

    @app.post("/reservations/<int:reservation_id>/prepare")
    @login_required
    def prepare_lift(reservation_id):
        item = query("SELECT reservation_id,user_id,status FROM reservation WHERE reservation_id=%s", (reservation_id,), one=True)
        if not item or (current_user()["user_type"] != "ADMIN" and item["user_id"] != current_user()["user_id"]): abort(404)
        conn = connect(); cur = conn.cursor()
        try:
            cur.callproc("sp_prepare_lift_for_reservation", (reservation_id,)); conn.commit()
        finally:
            cur.close(); conn.close()
        flash("Lift state updated to simulated positioning.", "info")
        return redirect(url_for("reservations"))

    @app.post("/reservations/<int:reservation_id>/cancel")
    @login_required
    def cancel_reservation(reservation_id):
        execute("UPDATE reservation SET status='CANCELLED' WHERE reservation_id=%s AND user_id=%s AND status='CONFIRMED' AND start_time>NOW()", (reservation_id, current_user()["user_id"]))
        flash("Reservation cancelled if it was confirmed and scheduled in the future.", "info")
        return redirect(url_for("reservations"))

    @app.route("/sessions")
    @login_required
    def sessions():
        user = current_user()
        where, params = ("", ()) if user["user_type"] == "ADMIN" else ("WHERE v.user_id=%s", (user["user_id"],))
        rows = query(f"""SELECT ps.session_id,ps.reservation_id,v.registration_no,u.name customer,ps.position_id,lp.position_number,pl.lift_code,ps.entry_time,ps.exit_time,ps.status
          FROM parking_session ps JOIN vehicle v ON v.vehicle_id=ps.vehicle_id JOIN users u ON u.user_id=v.user_id
          JOIN lift_position lp ON lp.position_id=ps.position_id JOIN parking_lift pl ON pl.lift_id=lp.lift_id {where} ORDER BY ps.session_id DESC""", params)
        return render_template("sessions.html", sessions=rows)

    @app.post("/sessions/<int:session_id>/entry")
    @admin_required
    def session_entry(session_id):
        item = query("SELECT session_id,position_id,status FROM parking_session WHERE session_id=%s", (session_id,), one=True)
        if not item or item["status"] != "NOT_STARTED": abort(404)
        conn = connect(); cur = conn.cursor()
        try:
            cur.execute("UPDATE parking_session SET entry_time=NOW(),status='ACTIVE' WHERE session_id=%s", (session_id,))
            cur.execute("UPDATE lift_position SET status='OCCUPIED' WHERE position_id=%s", (item["position_id"],))
            conn.commit()
        except Exception:
            conn.rollback(); raise
        finally:
            cur.close(); conn.close()
        flash("Vehicle entry recorded.", "success")
        return redirect(url_for("sessions"))

    @app.post("/sessions/<int:session_id>/exit")
    @admin_required
    def session_exit(session_id):
        conn = connect(); cur = conn.cursor()
        try:
            cur.callproc("sp_complete_parking_session", (session_id,)); conn.commit()
        finally:
            cur.close(); conn.close()
        flash("Vehicle exit recorded and position released.", "success")
        return redirect(url_for("sessions"))

    @app.route("/bills")
    @login_required
    def bills():
        user = current_user()
        where, params = ("", ()) if user["user_type"] == "ADMIN" else ("WHERE v.user_id=%s", (user["user_id"],))
        rows = query(f"""SELECT b.*,ps.session_id,v.registration_no,u.name customer FROM billing b
          JOIN parking_session ps ON ps.session_id=b.session_id JOIN vehicle v ON v.vehicle_id=ps.vehicle_id
          JOIN users u ON u.user_id=v.user_id {where} ORDER BY b.bill_id DESC""", params)
        return render_template("bills.html", bills=rows)

    @app.post("/bills/<int:bill_id>/pay")
    @login_required
    def pay_bill(bill_id):
        if current_user()["user_type"] == "ADMIN":
            where, params = "", ()
        else:
            where, params = "AND v.user_id=%s", (current_user()["user_id"],)
        conn = connect(); cur = conn.cursor()
        try:
            cur.execute(f"""UPDATE billing b JOIN parking_session ps ON ps.session_id=b.session_id JOIN vehicle v ON v.vehicle_id=ps.vehicle_id
              SET b.payment_status='PAID',b.payment_time=NOW() WHERE b.bill_id=%s AND b.payment_status='PENDING' {where}""", (bill_id, *params))
            conn.commit()
        finally:
            cur.close(); conn.close()
        flash("Payment marked as paid for demonstration.", "success")
        return redirect(url_for("bills"))

    @app.route("/admin", methods=["GET", "POST"])
    @admin_required
    def admin():
        if request.method == "POST":
            action = request.form.get("action")
            if action == "facility":
                execute("INSERT INTO parking_facility (facility_name,location,operating_hours,contact_number) VALUES (%s,%s,%s,%s)", (request.form["facility_name"], request.form["location"], request.form.get("operating_hours", ""), request.form.get("contact_number", "")))
                flash("Facility added.", "success")
            elif action == "lift":
                execute("INSERT INTO parking_lift (zone_id,lift_code,lift_type,capacity,max_load_kg,lift_status) VALUES (%s,%s,%s,%s,%s,'OPERATIONAL')", (request.form["zone_id"], request.form["lift_code"], request.form["lift_type"], request.form["capacity"], request.form.get("max_load_kg") or None))
                flash("Lift added. Add its configured positions below.", "success")
            elif action == "position":
                execute("INSERT INTO lift_position (lift_id,position_number,vehicle_type,status) VALUES (%s,%s,%s,'AVAILABLE')", (request.form["lift_id"], request.form["position_number"], request.form["vehicle_type"]))
                flash("Lift position added.", "success")
            return redirect(url_for("admin"))
        facilities = query("SELECT * FROM parking_facility ORDER BY facility_id")
        zones = query("SELECT pz.*,pf.facility_name FROM parking_zone pz JOIN parking_facility pf ON pf.facility_id=pz.facility_id ORDER BY pf.facility_name,pz.zone_name")
        lifts = query("""SELECT pl.*,pz.zone_name,pf.facility_name,COUNT(lp.position_id) position_count,
          SUM(lp.status='AVAILABLE') available FROM parking_lift pl JOIN parking_zone pz ON pz.zone_id=pl.zone_id
          JOIN parking_facility pf ON pf.facility_id=pz.facility_id LEFT JOIN lift_position lp ON lp.lift_id=pl.lift_id
          GROUP BY pl.lift_id,pz.zone_name,pf.facility_name ORDER BY pl.lift_id""")
        users = query("SELECT user_id,name,email,phone,user_type FROM users ORDER BY user_id DESC LIMIT 100")
        violations = query("""SELECT vi.*,v.registration_no,u.name reporter FROM violation vi JOIN vehicle v ON v.vehicle_id=vi.vehicle_id
          JOIN users u ON u.user_id=vi.reported_by ORDER BY vi.violation_time DESC""")
        vehicles = query("SELECT vehicle_id,registration_no FROM vehicle ORDER BY registration_no")
        positions = query("SELECT position_id,position_number FROM lift_position ORDER BY position_id")
        return render_template("admin.html", facilities=facilities, zones=zones, lifts=lifts, users=users, violations=violations, vehicles=vehicles, positions=positions)

    @app.post("/admin/violations")
    @admin_required
    def add_violation():
        execute("""INSERT INTO violation (vehicle_id,session_id,position_id,violation_type,description,fine_amount,reported_by,violation_time,status,penalty_status)
          VALUES (%s,%s,%s,%s,%s,%s,%s,NOW(),'OPEN','UNPAID')""", (request.form["vehicle_id"], request.form.get("session_id") or None, request.form["position_id"], request.form["violation_type"], request.form["description"], request.form["fine_amount"], current_user()["user_id"]))
        flash("Violation recorded.", "success")
        return redirect(url_for("admin") + "#violations")

    @app.post("/admin/lifts/<int:lift_id>/status")
    @admin_required
    def update_lift(lift_id):
        status = request.form.get("lift_status")
        if status not in {"OPERATIONAL", "MAINTENANCE"}: abort(400)
        execute("UPDATE parking_lift SET lift_status=%s WHERE lift_id=%s", (status, lift_id))
        flash("Lift status updated.", "success")
        return redirect(url_for("admin"))

    @app.post("/admin/users/<int:user_id>/role")
    @admin_required
    def update_user_role(user_id):
        role = request.form.get("user_type")
        if role not in {"ADMIN", "CUSTOMER"}: abort(400)
        if user_id == current_user()["user_id"] and role != "ADMIN":
            flash("You cannot remove your own admin access.", "warning")
        else:
            execute("UPDATE users SET user_type=%s WHERE user_id=%s", (role, user_id))
            flash("User role updated.", "success")
        return redirect(url_for("admin") + "#users")

    @app.post("/violations/<int:violation_id>/update")
    @admin_required
    def update_violation(violation_id):
        status = request.form.get("status")
        if status not in {"OPEN", "UNDER_REVIEW", "RESOLVED"}: abort(400)
        execute("UPDATE violation SET status=%s WHERE violation_id=%s", (status, violation_id))
        flash("Violation status updated.", "success")
        return redirect(url_for("admin") + "#violations")

    @app.post("/violations/<int:violation_id>/pay")
    @login_required
    def pay_penalty(violation_id):
        if current_user()["user_type"] == "ADMIN":
            where, params = "", ()
        else:
            where, params = "AND v.user_id=%s", (current_user()["user_id"],)
        conn = connect(); cur = conn.cursor()
        try:
            cur.execute(f"""UPDATE violation vi JOIN vehicle v ON v.vehicle_id=vi.vehicle_id
              SET vi.penalty_status='PAID',vi.penalty_payment_method=%s,vi.penalty_payment_date=NOW()
              WHERE vi.violation_id=%s AND vi.penalty_status='UNPAID' {where}""", (request.form.get("method", "ONLINE"), violation_id, *params))
            conn.commit()
        finally:
            cur.close(); conn.close()
        flash("Penalty marked as paid for demonstration.", "success")
        return redirect(request.referrer or url_for("dashboard"))

    @app.route("/violations")
    @login_required
    def violations():
        user = current_user()
        where, params = ("", ()) if user["user_type"] == "ADMIN" else ("WHERE v.user_id=%s", (user["user_id"],))
        rows = query(f"""SELECT vi.*,v.registration_no,u.name reporter,lp.position_number FROM violation vi
          JOIN vehicle v ON v.vehicle_id=vi.vehicle_id JOIN users u ON u.user_id=vi.reported_by
          JOIN lift_position lp ON lp.position_id=vi.position_id {where} ORDER BY vi.violation_time DESC""", params)
        return render_template("violations.html", violations=rows)

    @app.cli.command("set-password")
    @click.argument("email")
    @click.password_option()
    def set_password(email, password):
        """Set a secure password for an existing account."""
        if not password or len(password) < 8:
            raise click.ClickException("Password must be at least 8 characters.")
        execute("UPDATE users SET password=%s WHERE email=%s", (generate_password_hash(password), email.strip().lower()))
        click.echo("Password updated. If the email was not found, no account changed.")

    return app
