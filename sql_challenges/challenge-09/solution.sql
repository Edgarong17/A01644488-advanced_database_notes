-- Lesson 04: Class Exercises
-- Students: work through these in order. Don't skip the verify steps.

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:

select * from accounts;

BEGIN
    UPDATE ACCOUNTS
    SET balance = balance - 50
    WHERE owner_name = 'Charlie';

    UPDATE ACCOUNTS
    SET balance = balance + 50
    WHERE owner_name = 'Alice';

    COMMIT;
END;
/

SELECT * FROM ACCOUNTS;


-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:

DECLARE
    charBal NUMBER;
BEGIN
    UPDATE ACCOUNTS
    SET balance = balance - 10000
    WHERE owner_name = 'Bob';

    UPDATE ACCOUNTS
    SET balance = balance + 10000
    WHERE owner_name = 'Charlie';

    SELECT balance INTO charBal
    FROM ACCOUNTS
    WHERE account_id = 3;

    IF charBal < 0 THEN
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;
END;
/

SELECT * FROM ACCOUNTS;

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:
DECLARE
    charBal NUMBER;
BEGIN
    UPDATE ACCOUNTS
    SET balance = balance + 25
    WHERE owner_name = 'Alice';
    SAVEPOINT al1;

    UPDATE ACCOUNTS
    SET balance = balance - 25
    WHERE owner_name = 'Charlie';

    ROLLBACK TO al1;

    UPDATE ACCOUNTS
    SET balance = balance - 25
    WHERE owner_name = 'Bob';

    COMMIT;
END;
/

SELECT * FROM ACCOUNTS;

-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:

CREATE OR REPLACE PROCEDURE deposit_funds (
    p_account_id NUMBER,
    p_amount NUMBER
)
AS
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid amount');
    END IF;

    UPDATE ACCOUNTS
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

EXEC deposit_funds(3, 75);


-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?
-- Inside the transaction should be the a and b because these are critical operations for the system and they should follow the atomicity principle
-- which means all or nothing. The confirmation notification can be outside, because this is not critical and is usually handled by another system.

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?
-- The problem is that if after the stored procedure there is an error then the changes of the stored procedure are already made and cannot be reverted.

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?
-- They can use the calculate_copay as it is a function and operates with select statements, on the other hans it cannot use the post_payment procedure
-- as this alter the database data. Also because a stored procedure does not return a direct value.
