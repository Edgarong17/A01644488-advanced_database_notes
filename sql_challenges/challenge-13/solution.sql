--CREATE TABLE
CREATE TABLE tickets (
    ticket_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR2(200),
    status VARCHAR2(50),
    priority VARCHAR2(50),
    created_at TIMESTAMP,
    resolved_at TIMESTAMP,
    assigned_to VARCHAR2(100)
);


CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER,
    assigned_to VARCHAR2(100),
    assigned_by VARCHAR2(100),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    
    CONSTRAINT fk_ticket
        FOREIGN KEY (ticket_id)
        REFERENCES tickets(ticket_id)
);

--SAMPLE DATA
INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Login Isue', 'OPEN', 'HIGH',
 SYSTIMESTAMP - INTERVAL '5' DAY,
 NULL,
 'Juan'); --Diferent

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Test2', 'RESOLVED', 'LOW',
 SYSTIMESTAMP - INTERVAL '4' DAY,
 SYSTIMESTAMP - INTERVAL '1' DAY,
 'Bob');

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Test3', 'RESOLVED', 'CRITICAL',
 SYSTIMESTAMP - INTERVAL '3' DAY,
 SYSTIMESTAMP,
 'Edgar');

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Test4', 'OPEN', 'MEDIUM',
 SYSTIMESTAMP - INTERVAL '2' DAY,
 NULL,
 'Juan');

INSERT INTO tickets
(title, status, priority, created_at, resolved_at, assigned_to)
VALUES
('Test5', 'RESOLVED', 'HIGH',
 SYSTIMESTAMP - INTERVAL '6' DAY,
 SYSTIMESTAMP - INTERVAL '2' DAY,
 'David');

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(1, 'Edgar', 'SYSTEM',
 SYSTIMESTAMP - INTERVAL '5' DAY,
 NULL); --Diferent

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(2, 'Bob', 'SYSTEM',
 SYSTIMESTAMP - INTERVAL '4' DAY,
 NULL);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(3, 'Edgar', 'SYSTEM',
 SYSTIMESTAMP - INTERVAL '3' DAY,
 NULL);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(4, 'Juan', 'SYSTEM',
 SYSTIMESTAMP - INTERVAL '2' DAY,
 NULL);

INSERT INTO ticket_assignments
(ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES
(5, 'David', 'SYSTEM',
 SYSTIMESTAMP - INTERVAL '6' DAY,
 NULL);

--TRIGGER

CREATE OR REPLACE TRIGGER trg_ticket_assignment
AFTER INSERT OR UPDATE OF assigned_to
ON tickets
FOR EACH ROW
BEGIN

    UPDATE ticket_assignments
    SET valid_to = SYSTIMESTAMP
    WHERE ticket_id = :NEW.ticket_id
      AND valid_to IS NULL;

    INSERT INTO ticket_assignments (
        ticket_id,
        assigned_to,
        assigned_by,
        valid_from,
        valid_to
    )
    VALUES (
        :NEW.ticket_id,
        :NEW.assigned_to,
        'SYSTEM',
        SYSTIMESTAMP,
        NULL
    );
END;
/

--Test
UPDATE tickets
SET assigned_to = 'Juan'
WHERE ticket_id = 1;

SELECT *
FROM ticket_assignments
WHERE ticket_id = 1
ORDER BY valid_from;

--Data Warehouse

CREATE TABLE dim_agent (
    agent_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name VARCHAR2(100),
    team VARCHAR2(100)
);

CREATE TABLE fact_ticket_daily (
    date_key DATE,
    agent_key NUMBER,
    status VARCHAR2(50),
    priority VARCHAR2(50),
    tickets_created NUMBER,
    tickets_resolved NUMBER,

    CONSTRAINT fk_fact_agent
        FOREIGN KEY (agent_key)
        REFERENCES dim_agent(agent_key)
);

--— Populate dim_agent

INSERT INTO dim_agent (agent_name, team)
VALUES ('Juan', 'Support');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Bob', 'Front');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Edgar', 'Back');

INSERT INTO dim_agent (agent_name, team)
VALUES ('David', 'Security');

--ETL Logic (Colab)

---- # =1. Extracts `tickets` and `ticket_assignments` from FreeSQL

--tickets = pd.read_sql("SELECT * FROM tickets", engine)

--assignments = pd.read_sql(
--    "SELECT * FROM ticket_assignments",
--    engine
--)

--tickets['created_at'] = pd.to_datetime(tickets['created_at'])
--tickets['resolved_at'] = pd.to_datetime(tickets['resolved_at'])

--assignments['valid_from'] = pd.to_datetime(assignments['valid_from'])
--assignments['valid_to'] = pd.to_datetime(assignments['valid_to'])

--#2. For each ticket, finds who was assigned at `created_at` using:
--#   `valid_from <= created_at AND (valid_to IS NULL OR valid_to > created_at)`

--created_rows = []

--for _, ticket in tickets.iterrows():

--    matches = assignments[
--        (assignments['ticket_id'] == ticket['ticket_id']) &
--        (assignments['valid_from'] <= ticket['created_at']) &
--        (
--            assignments['valid_to'].isna() |
--            (assignments['valid_to'] > ticket['created_at'])
--        )
--    ]

--    if not matches.empty:
--        agent = matches.iloc[0]['assigned_to']

--        created_rows.append({
--            'date_key': ticket['created_at'].date(),
--            'agent_name': agent,
--            'status': ticket['status'],
--            'priority': ticket['priority'],
--            'tickets_created': 1,
--            'tickets_resolved': 0
--        })

--# 3. Same for `resolved_at`

--resolved_rows = []

--resolved = tickets[tickets['resolved_at'].notna()]

--for _, ticket in resolved.iterrows():

--    matches = assignments[
--        (assignments['ticket_id'] == ticket['ticket_id']) &
--        (assignments['valid_from'] <= ticket['resolved_at']) &
--        (
--            assignments['valid_to'].isna() |
--            (assignments['valid_to'] > ticket['resolved_at'])
--        )
--    ]

--    if not matches.empty:

--        agent = matches.iloc[0]['assigned_to']

--        resolved_rows.append({
--            'date_key': ticket['resolved_at'].date(),
--            'agent_name': agent,
--            'status': ticket['status'],
--            'priority': ticket['priority'],
--            'tickets_created': 0,
--            'tickets_resolved': 1
--        })

--# 4. Groups by date, agent, status, priority and counts
--df = pd.DataFrame(created_rows + resolved_rows)

--fact = df.groupby(
--    ['date_key', 'agent_name', 'status', 'priority'],
--    as_index=False
--).sum()

--agents = pd.read_sql("SELECT * FROM dim_agent", engine)

--fact = fact.merge(
--    agents,
--    left_on='agent_name',
--    right_on='agent_name'
--)

--# 5. Inserts into `fact_ticket_daily`
--from sqlalchemy import text

--with engine.begin() as conn:

--    conn.execute(text("DELETE FROM fact_ticket_daily"))

--    for _, row in fact.iterrows():

--        conn.execute(text("""
--            INSERT INTO fact_ticket_daily (
--                date_key,
--                agent_key,
--                status,
--                priority,
--                tickets_created,
--                tickets_resolved
--            )
--            VALUES (
--                :date_key,
--                :agent_key,
--                :status,
--                :priority,
--                :tickets_created,
--                :tickets_resolved
--            )
--        """), {
--            "date_key": row['date_key'],
--            "agent_key": int(row['agent_key']),
--            "status": row['status'],
--            "priority": row['priority'],
--            "tickets_created": int(row['tickets_created']),
--            "tickets_resolved": int(row['tickets_resolved'])
--        })

-- Verify
SELECT
    f.date_key,
    d.agent_name,
    d.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent d
    ON f.agent_key = d.agent_key
ORDER BY f.date_key, d.agent_name;