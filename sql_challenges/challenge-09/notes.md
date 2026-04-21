## It is necesary to have this structure for a transaction

BEGIN

    SQL

    COMMIT;
END;

## A stored procedure has:

CREATE OR REPLACE PROCEDURE name (
    var NUMBER,
)
AS
BEGIN

    SQL

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/



## Cuando se hace un rollback a un punto especifico
ROLLBACK TO name_savepoint;
