-- PART 1: 

-- QUERY 1: Monthly revenue summary for dentists
-- Explanation: It is relevant business wise because clinic managers need to track how much revenue each dentist makes
-- per month to evaluate performance and spread resources effectively.
SELECT d.dentist_id, d.d_fname + ' ' + d.d_lname AS dentist_name, d.d_specialty, FORMAT(b.bill_date, 'yyyy-MM') AS bill_month, COUNT(b.bill_id) AS total_bills,
    SUM(b.total_amount) AS total_billed, SUM(b.total_amount - b.bill_balance) AS total_collected, SUM(b.bill_balance) AS total_outstanding
FROM dentist d
JOIN appointment a ON d.dentist_id = a.dentist_id
JOIN visit v ON a.appointment_id = v.appointment_id
JOIN bill b ON v.visit_id = b.visit_id
GROUP BY d.dentist_id, d.d_fname, d.d_lname, d.d_specialty, FORMAT(b.bill_date, 'yyyy-MM')
ORDER BY bill_month DESC, total_billed DESC;

-- QUERY 2: Patients with outstanding balances above average
-- Explanation: The billing department needs to identify patients who owe more than
-- the clinic average to prioritise payment reminders towards them.
SELECT p.patient_id, p.p_fname + ' ' + p.p_lname AS patient_name, p.p_phone_num, SUM(b.bill_balance) AS total_balance_owing
FROM patient p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN visit v ON a.appointment_id = v.appointment_id
JOIN bill b ON v.visit_id = b.visit_id
WHERE b.bill_balance > 0
GROUP BY p.patient_id, p.p_fname, p.p_lname, p.p_phone_num
HAVING SUM(b.bill_balance) > (SELECT AVG(bill_balance) FROM bill WHERE bill_balance > 0)
ORDER BY total_balance_owing DESC;

-- QUERY 3: Full patient visit history with cost
-- Explanation: Dentist or receptionist who needs a complete timeline of every
-- patient's visits, diagnoses, and associated costs to prepare for upcoming appointments
-- and review treatment continuity. As well as to inform patients who reqire information.
SELECT p.patient_id, p.p_fname + ' ' + p.p_lname AS patient_name, v.visit_date, d.d_fname + ' ' + d.d_lname AS treating_dentist, d.d_specialty, mh.diagnosis,
    mh.treatment_description, mh.treatment_cost, b.total_amount AS bill_total, b.bill_balance AS amount_still_owing, cl.claim_status AS insurance_claim_status
FROM patient p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN dentist d ON a.dentist_id = d.dentist_id
JOIN visit v ON a.appointment_id = v.appointment_id
JOIN medical_history mh ON v.visit_id = mh.visit_id
JOIN bill b ON v.visit_id = b.visit_id
LEFT JOIN insurance_claim cl ON b.bill_id = cl.bill_id
ORDER BY p.patient_id, v.visit_date DESC;

-- VIEW 1: vw_patient_billing_summary
-- Explanation: Receptionists and billing staff only need financial and scheduling data,
-- they shouldn't have direct access to diagnosis details or medical histories since it is confidential.
CREATE VIEW vw_patient_billing_summary AS
SELECT p.patient_id, p.p_fname + ' ' + p.p_lname AS patient_name, p.p_phone_num, p.city, ic.company_name AS insurance_company, b.bill_id, b.bill_date,
    b.total_amount, b.bill_balance, cl.claim_status AS insurance_claim_status
FROM patient p
LEFT JOIN insurance_company ic ON p.insurance_id = ic.insurance_id
JOIN appointment a ON p.patient_id = a.patient_id
JOIN visit v ON a.appointment_id = v.appointment_id
JOIN bill b ON v.visit_id = b.visit_id
LEFT JOIN insurance_claim cl ON b.bill_id = cl.bill_id;

-- VIEW 2: vw_dentist_schedule
-- Explanation: A dentist should only see their own upcoming appointments and basic patient
-- contact details.
CREATE VIEW vw_dentist_schedule AS
SELECT d.dentist_id, d.d_fname + ' ' + d.d_lname AS dentist_name, d.d_specialty, a.appointment_id, a.appointment_date, a.appointment_time, a.appointment_status,
    p.patient_id, p.p_fname + ' ' + p.p_lname AS patient_name, p.p_phone_num
FROM dentist d
JOIN appointment a ON d.dentist_id = a.dentist_id
JOIN patient p ON a.patient_id = p.patient_id
WHERE a.appointment_status IN ('Scheduled', 'Completed');


-- PART 2:
select* from payment select* from bill_payment
-- PROCEDURE 1: prc_addPayment
-- Explaination: This procedure allows us to add a payment, autimatically update the bil balance and ensure the payment isn't over the bill
ALTER PROCEDURE proc_addPayment (@payID INT, @payDate DATE, @payAmount MONEY, @payer_type VARCHAR(30), @pay_type VARCHAR(30), @patientID INT, @billID INT)
AS
BEGIN
    BEGIN TRY
           
           DECLARE @totalAmount MONEY, @newBalance MONEY

           SELECT @totalAmount = total_amount FROM bill WHERE bill_id = @billID

           IF @totalAmount IS NULL
           BEGIN
                PRINT 'Bill does not exist'
           END

           SET @newBalance = @totalAmount - @payAmount

           IF @newBalance < 0
           BEGIN
                PRINT 'Payment cannot be more than bill'
           END

           INSERT INTO payment
           VALUES (@payID, @payDate, @payAmount, @payer_type, @pay_type, @patientID)

           UPDATE bill
           SET bill_balance = @newBalance
           WHERE bill_id = @billID

           PRINT'Payment success'
    END TRY
    BEGIN CATCH
        PRINT'AN ERROR OCCURRED'
    END CATCH
END

--Test:
EXEC dbo.proc_addPayment @payID = 2000, @payDate = '2026-05-09', @payAmount = 100.00, @payer_type = 'Patient', @pay_type = 'Credit', @patientID = 1000, @billID = 1000
SELECT* FROM payment
SELECT* FROM bill WHERE bill_id = 1000


-- PROCEDURE 2: prc_deletePayment
-- Explaination: Allows us to delete a payment and while updating the bil balance
ALTER PROCEDURE prc_deletePay (@payID INT, @billID INT)
AS
BEGIN
    BEGIN TRY
        
        DECLARE @payAmount MONEY, @balance MONEY, @newBalance MONEY

        SELECT @payAmount = payment_amount FROM payment WHERE payment_id = @payID

        IF @payAmount IS NULL
        BEGIN
            PRINT'Payment does not exist'
        END

        SELECT @balance = bill_balance FROM bill WHERE bill_id = @billID

        SET @newBalance = @balance + @payAmount

        DELETE FROM bill_payment
        WHERE payment_id = @payID AND bill_id =@billID

        DELETE FROM payment
        WHERE payment_id = @billID

        UPDATE bill
        SET bill_balance = @newBalance
        where bill_id = @billID
        PRINT'Payemnt successfully deleted'

    END TRY
    BEGIN CATCH
           PRINT'AN ERROR OCCURED'
    END CATCH
END

--Test:
SELECT* FROM payment
SELECT* FROM bill
SELECT* FROM bill_payment

EXEC dbo.prc_deletePay @payID = 1010, @billID = 1000


-- PART 3:

ALTER TABLE patient
ADD p_balance NUMERIC(8,2) NOT NULL DEFAULT 0 CHECK(p_balance >= 0)

CREATE TRIGGER bill_insert ON bill 
INSTEAD OF INSERT
AS
BEGIN
    BEGIN TRY
        IF (SELECT total_amount FROM INSERTED) IS NULL
            RAISERROR('Total bill amount cannot be null.', 16, 1);
        ELSE IF (SELECT total_amount FROM INSERTED) <= 0
            RAISERROR('Total bill amount must be above zero.', 16, 1);
        ELSE IF (SELECT visit_id FROM INSERTED) NOT IN (SELECT visit_id FROM visit)
            RAISERROR('Visit does not exist.', 16, 1);
        ELSE
        BEGIN
            DECLARE @p_id INT;
            SELECT @p_id = a.patient_id FROM appointment a WHERE a.appointment_id = (SELECT v.appointment_id FROM visit v WHERE v.visit_id = (SELECT visit_id FROM INSERTED));
            IF @p_id NOT IN (SELECT patient_id FROM patient)
                RAISERROR('Patient does not exists.',16,1);
            ELSE 
            BEGIN
                INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id) SELECT bill_date, total_amount, bill_balance, visit_id FROM INSERTED;
                UPDATE patient
                SET p_balance = p_balance + (SELECT bill_balance FROM INSERTED)
                WHERE patient_id = @p_id;
            END;
        END;
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH;
END;

-- visit 1010 should succeed and update balance
INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id)
VALUES ('2026-05-06', 500.00, 500.00, 1010);

SELECT patient_id, p_fname, p_balance FROM patient;

-- null total_amount should fail
INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id)
VALUES ('2026-05-06', NULL, 100.00, 1030);

-- negative total_amount should fail
INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id)
VALUES ('2026-05-06', -50.00, -50.00, 1030);

-- non-existent visit_id should fail
INSERT INTO bill (bill_date, total_amount, bill_balance, visit_id)
VALUES ('2026-05-06', 200.00, 200.00, 9999);


-- PART 4:

CREATE ROLE receptionist
CREATE ROLE dentist

GRANT SELECT, INSERT, UPDATE ON patient TO receptionist
GRANT SELECT, INSERT, UPDATE ON appointment to receptionist

GRANT SELECT ON patient TO dentist
GRANT SELECT ON appointment TO dentist
GRANT SELECT ON medical_history TO dentist

CREATE LOGIN user1 WITH PASSWORD = 'PASSWORD1234'
CREATE USER user1 FOR LOGIN user1

CREATE LOGIN user2 WITH PASSWORD = 'PASSWORD1234'
CREATE USER user2 FOR LOGIN user2


-- PART 5: 

-- We would use a Transaction Log Backup because since the DataBase is about Dentist, it is more relevant to have frequent backup just in case if there's an error in the Database.
-- This backup copy all the log record and you'll be able to restore at any time within the backup which is great.
-- If an error occurs: Restore the latest backup, Restore all transaction log backup, Get the log where the problem happened after.

