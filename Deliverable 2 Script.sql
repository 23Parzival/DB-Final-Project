CREATE DATABASE dental_clinic_DB
USE dental_clinic_DB

-- DROP TABLES IF THEY EXIST
DROP TABLE IF EXISTS BillPayment;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS InsuranceClaim;
DROP TABLE IF EXISTS InsuranceCompany;
DROP TABLE IF EXISTS Bill;
DROP TABLE IF EXISTS MedicalHistory;
DROP TABLE IF EXISTS Visit;
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Dentist;

-- 3.D
CREATE SEQUENCE seq_bill_id
START WITH 1000
INCREMENT BY 1
NO CACHE
NO CYCLE;

-- CREATE ALL TABlES 3.A

CREATE TABLE dentist (
    dentist_id INT PRIMARY KEY,
    d_fname VARCHAR(20) NOT NULL,
    d_lname VARCHAR(20) NOT NULL,
    d_specialty VARCHAR(25)
);

CREATE TABLE insurance_company (
    insurance_id INT PRIMARY KEY,
    company_name VARCHAR(30) UNIQUE,
    phone_num VARCHAR(15) UNIQUE
);

CREATE TABLE patient (
    patient_id INT IDENTITY(1000,1) PRIMARY KEY,
    p_fname VARCHAR(20) NOT NULL,
    p_lname VARCHAR(20)NOT NULL,
    p_dob DATE,
    p_phone_num VARCHAR(15) UNIQUE,
    city VARCHAR(20),
    province VARCHAR(15),
    street VARCHAR(15),
    postal_code CHAR(6) NOT NULL,
    insurance_id INT,
    CONSTRAINT patient_insurance_id_fk FOREIGN KEY (insurance_id) REFERENCES insurance_company(insurance_id)
);

CREATE TABLE appointment (
    appointment_id INT PRIMARY KEY,
    appointment_date DATE,
    appointment_time TIME,
    appointment_status VARCHAR(16),
    dentist_id INT,
    patient_id INT,
    CONSTRAINT appointment_dentist_id_fk FOREIGN KEY (dentist_id) REFERENCES dentist(dentist_id),
    CONSTRAINT appointment_patient_id_fk FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

CREATE TABLE visit (
    visit_id INT PRIMARY KEY,
    visit_date DATE,
    visit_time TIME,
    appointment_id INT,
    CONSTRAINT visit_appointment_id_fk FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id) ON DELETE CASCADE
);

CREATE TABLE bill (
    bill_id INT PRIMARY KEY DEFAULT NEXT VALUE FOR seq_bill_id,
    bill_date DATE,
    total_amount NUMERIC(10,2) NOT NULL,
    bill_balance NUMERIC(10,2),
    visit_id INT,
    CONSTRAINT bill_visit_id_fk FOREIGN KEY (visit_id) REFERENCES visit(visit_id) ON DELETE CASCADE
);

CREATE TABLE insurance_claim (
    claim_id INT PRIMARY KEY,
    claim_date DATE,
    claim_status VARCHAR(15),
    deductible_amount NUMERIC(10,2),
    bill_id INT,
    insurance_id INT,
    CONSTRAINT insuranceclaim_bill_id_fk FOREIGN KEY (bill_id) REFERENCES bill(bill_id) ON DELETE SET NULL,
    CONSTRAINT insuranceclaim_insurance_id_fk FOREIGN KEY (insurance_id) REFERENCES insurance_company(insurance_id)
);

CREATE TABLE payment (
    payment_id INT PRIMARY KEY,
    payment_date DATE NOT NULL,
    payment_amount NUMERIC(10,2) NOT NULL,
    payer_type VARCHAR(30),
    payment_type VARCHAR(30),
    patient_id INT,
    CONSTRAINT payment_patient_id_fk FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

CREATE TABLE bill_payment (
    bill_id INT,
    payment_id INT,
    amount_applied NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (bill_id, payment_id),
    CONSTRAINT billpayment_bill_id_fk FOREIGN KEY (bill_id) REFERENCES bill(bill_id),
    CONSTRAINT billpayment_payment_id_fk FOREIGN KEY (payment_id) REFERENCES payment(payment_id) ON DELETE CASCADE
);

CREATE TABLE medical_history (
    history_id INT PRIMARY KEY,
    diagnosis VARCHAR(20),
    treatment_description VARCHAR(60),
    treatment_cost NUMERIC(10,2),
    record_date DATE,
    patient_id INT,
    visit_id INT,
    CONSTRAINT medicalhistory_patient_id_fk FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    CONSTRAINT medicalhistory_visit_id_fk FOREIGN KEY (visit_id) REFERENCES visit(visit_id)
);

--3.B
-- Cascade set to patient foreign key in appointment because if the patient is deleted so are his/her appointments.
-- Cascade set to appointment foreign key in visit because if an appointment is deleted so is the visit.
-- Same thing for visit fk in bill because if a visit is deleted so is its bill.
-- Set null to bill fk in insurance claim because if a bill is deleted the claim was still made.
-- Cascade set to patient fk in payment because if a patient is deleted so are its payments.
-- Cascade set to payment fk in bill_payment because if the payment is deleted, so is its reference.
-- Cascade set to patient in medical history because if it is deleted so is its history.

-- INSERT DATA 3.C

INSERT INTO dentist 
VALUES (1001, 'Cha', 'Kuria', 'Orthodontist'),
       (1002, 'Laureat', 'Mush', 'Periodontist'),
       (1003, 'Guck', 'Goose', 'Dental Public Health'),
       (1004, 'Mary', 'Robins', 'Endodontist');

INSERT INTO insurance_company 
VALUES (1100, 'FirstCompany', '514-111-1111'),
       (2200, 'SecondCompany', '514-222-2222'),
       (3300, 'ThirdCompany', '514-333-3333'),
       (4400, 'FourthCompany', '514-444-4444');

INSERT INTO patient (p_fname, p_lname, p_dob, p_phone_num, city, street, province, postal_code, insurance_id) 
VALUES ('Sony', 'Jr', '1998-03-23', '514-324-7643', 'Montreal', 'Queen Mary', 'Quebec', 'H1W1Y8', 1100),
       ('Jones', 'DaSec', '1997-04-16', '514-574-7868', 'Montreal', 'Saint-Luc', 'Quebec', 'H2W5K9', 2200),
       ('Alice', 'Smith', '1999-08-11', '514-876-9900', 'Laval', 'Main', 'Quebec', 'H3R4T6', 3300),
       ('Brian', 'Lee', '2000-12-01', '438-345-2233', 'Saint-Jérôme', 'Cedar', 'Quebec', 'J7Z2B1', 4400);

INSERT INTO appointment 
VALUES (1001, '2026-05-20', '14:30:00', 'Scheduled', 1003, 1000),
       (1002, '2026-07-14', '13:00:00', 'Scheduled', 1001, 1001),
       (1003, '2026-08-10', '15:00:00', 'Completed', 1002, 1002),
       (1004, '2026-09-02', '10:00:00', 'Scheduled', 1004, 1003);

INSERT INTO visit 
VALUES (1010, '2026-03-23', '12:40:00', 1001),
       (1020, '2026-02-14', '16:05:00', 1002),
       (1030, '2026-06-10', '09:15:00', 1003),
       (1040, '2026-07-01', '11:30:00', 1004);

INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id) 
VALUES ('2026-04-23', 200.00, 200.00, 1010),
       ('2026-03-14', 300.00, 250.00, 1020),
       ('2026-07-10', 150.00, 150.00, 1030),
       ('2026-08-05', 400.00, 350.00, 1040);

INSERT INTO insurance_claim 
VALUES (1001, '2026-03-10', 'Claimed', 100.00, 1000, 1100),
       (1002, '2026-04-23', 'Claimed', 200.00, 1001, 2200),
       (1003, '2026-06-20', 'Pending', 120.00, 1002, 3300),
       (1004, '2026-07-25', 'Claimed', 180.00, 1003, 4400);

INSERT INTO payment 
VALUES (1010, '2026-04-20', 200.00, 'Patient', 'Credit', 1000),
       (1020, '2026-03-10', 300.00, 'Insurance Company', null, 1001),
       (1030, '2026-07-12', 150.00, 'Patient', 'Debit', 1002),
       (1040, '2026-08-08', 400.00, 'Insurance Company', null, 1003);

INSERT INTO bill_payment 
VALUES (1000, 1010, 200.00),
       (1001, 1020, 300.00),
       (1002, 1030, 150.00),
       (1003, 1040, 400.00);

INSERT INTO medical_history 
VALUES (1001, 'Cavity', 'Cavity needs to be removed', 50.00, '2025-09-23', 1000, 1010),
       (1002, 'Infection', 'Cure with oral antibiotics', 300.00, '2024-05-07', 1001, 1020), 
       (1003, 'Gum Issue', 'Deep cleaning required', 120.00, '2025-10-11', 1002, 1030),
       (1004, 'Root Canal', 'Requires root canal procedure', 400.00, '2025-12-20', 1003, 1040);

-- 3.E
-- Likely that user will often search appointments by dentist or schedule. 
-- For example, a receptionist looking for all of a dentists appointment for a specific day.
CREATE INDEX idx_appointment_dentist_schedule
ON APPOINTMENT (dentist_id, appointment_date, appointment_time);

-- Likely that user will search payments by patient or date.
-- For example, a receptionist finding which patient made a payment on a specific day.
CREATE INDEX idx_payment_patient_date
ON PAYMENT (patient_id, payment_date);

-- 3.F
ALTER TABLE dentist
ADD salary NUMERIC(10,2);

ALTER TABLE dentist
ADD CONSTRAINT d_salary_ck CHECK (salary > 30000);