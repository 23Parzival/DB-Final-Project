--CREATE DATABASE Deliverable2
--Use Deliverable2

Create table Dentist
(dentist_id char(4) primary key,
d_fname varchar(20),
d_lname varchar(20),
d_specialty varchar(25))

--Drop table if exists Patient
Create table Patient
(patient_id char(5) primary key,
p_fname varchar(20),
p_lname varchar(20),
p_dob date,
P_phone_num varchar(15) unique,
city varchar(20),
street varchar(15),
province varchar(15),
postal_code varchar(10)) --add not null using alter for 3.F

Alter table patient --fk insurence_id
add insurance_id char(4)
Alter table Patient
add constraint Patient_insurance_id_fk foreign key (insurance_id) references InsuranceCompany

Create table Appointment
(appointment_id char(2) primary key,
appoint_date date,
appoint_time time,
appoint_status varchar(16),
dentist_id char(4),
constraint Appointment_dentist_id_fk foreign key (dentist_id) references Dentist,
patient_id char(5),
constraint Appointment_patient_id_fk foreign key (patient_id) references Patient)

Create table Visit
(visit_id char(2) primary key,
visit_date date,
visit_time time,
appointment_id char(2),
constraint Visit_appointment_id_fk foreign key (appointment_id) references Appointment)

Create table MedicalHistory
(history_id char(4),
diagnosis varchar(20),
treatment_description varchar(60),
treatment_cost numeric(10,2),
record_date date,
patient_id char(5),
constraint MedicalHistory_patient_id_fk foreign key (patient_id) references Patient,
visit_id char(2),
constraint MedicalHistory_visit_id_fk foreign key (visit_id) references Visit)

--Drop table if exists Bill
Create table Bill
(bill_id char(6) primary key,
bill_date date,
total_amount numeric(10,2) not null,
bill_balance numeric(10,2),
visit_id char(2),
constraint Bill_visit_id_fk foreign key (visit_id) references Visit)

--Drop table if exists InsuranceCompany
Create table InsuranceCompany
(insurance_id char(4) primary key,
company_name varchar(14) unique,
phone_num varchar(15) unique)

Create table InsuranceClaim
(claim_id char(5) primary key,
claim_date date,
claim_status varchar(15),
deductible_amount numeric(10,2),
bill_id char(6),
constraint InsuranceClaim_bill_id_fk foreign key (bill_id) references Bill,
insurance_id char(4),
constraint InsuranceClaim_insurance_id_fk foreign key (insurance_id) references InsuranceCompany)

Create table Payment
(payment_id char(4) primary key,
payment_date date,
payment_amount numeric(10,2),
payer_type varchar(15),
patient_id char(5),
constraint Payment_patient_id_fk foreign key (patient_id) references Patient)

--Drop table if exists BillPayment
Create table BillPayment
(bill_id char(6),
payment_id char(4),
primary key(bill_id, payment_id),
amount_applied numeric(10,2) not null,
constraint BillPayment_bill_id_fk foreign key (bill_id) references Bill,
constraint BillPayment_payment_id_fk foreign key (payment_id) references Payment)


--3.B
--Because if we take Patient and Appointment (linked to patient).
--If we delete a patient then we have to delete a appointment because appointment is dependant to patient.


--3.C
Insert into Dentist values('0011', 'Cha', 'Kuria', 'Orthodontist')
Insert into Dentist values('0022', 'Laureat', 'Mush', 'Periodontists')
Insert into Dentist values('0033', 'Guck', 'Goose', 'Dental Public Health')

Insert into InsuranceCompany values('1100', 'FirstCompany', '514-111-1111')
Insert into InsuranceCompany values('2200', 'SecondCompany','514-222-2222')

Insert into Patient values('00001','Sony', 'Jr', '1998-03-23','514-324-7643', 'Montreal', 'Queen Mary', 'Quebec', 'HW1Y89', '1100')--must fix
Insert into Patient values('00002','Jones', 'DaSec', '1997-04-16','514-574-7868','Montreal','Saint-Luc', 'Quebec', 'FW5K90','2200')

Insert into Appointment values('01', '2026-05-20', '14:30:00', 'Scheduled', '0033', '00002')--fix patient fix
Insert into Appointment values('02', '2026-07-14', '13:00:00', 'Scheduled', '0011', '00001')

Insert into Visit values('10', '2026-03-23', '12:40:00', '01')--Check Appointment 1st
Insert into Visit values('20', '2026-02-14', '16:05:00', '02')

Insert into Bill values('000111', '2026-4-23', 200.00, 200.00, '10')--check above first
Insert into Bill values('000222', '2026-3-14', 300.00, 250.00, '20')

Insert into InsuranceClaim values('11', '2026-3-10', 'Claimed', '000111', '1100')
Insert into InsuranceClaim values('22', '2026-4-23', 'Claimed', '000222', '2200')

Insert into Payment values('1010', '2026-4-20', 200.00, 'Patient', 'Credit', '00001')
Insert into Payment values('2020', '2026-3-10', 300.00, 'Insurance Company', 'Credit', '00002')

Insert into BillPayment values('000111', '1010', 200.00)
Insert into BillPayment values('000222', '2020', 300.00)