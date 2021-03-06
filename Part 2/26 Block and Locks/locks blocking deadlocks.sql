update TableOne
set fname = 'Tom'
where id = 1


Select * from TableOne

--user1

update TableOne
set fname = 'Sam'
where id = 1

--user2

update TableOne
set fname = 'Matt'
where id = 1


--these updates are occuring because in the background, locks are being held and released at a very fast pace by each transaction!!!
--if the locks were slow or and not releasing, then we will have perfomance issues.





/*

STEP TO FOLLOW: DEMONSTRATION OF A BLOCK

1. TURN ON TRACE FOR SQL SERVER LOGS
2. CREATE TWO TABLES IN SQL2 DB AND INSERT DATA
3. CHECK STATUS OF BLOCKED LOCK VIA SP_WHO2
4. RUN TRANSACTION 1 IN SESSION 1 WITHOUT COMMITING
5. ON A SEPERATE SESSION (NEW QUERY) RUN TRANSACTION 2
6. CHECK THE SP_WHO OR ACTIVE DIRECTORY FOR BLOCKING
7. COMMITT THE TRANSACTION 1 AND SEE TRANSACTION 2 IS EXECUTED

*/


--FIND STATUS OF TRACE FOR SQL SERVER ERROR LOG RECORDS

DBCC TRACESTATUS();
GO

--CHECK THE STATUS OF TRACE

DBCC TRACESTATUS(1222);
GO

---TURN ON STATUS

DBCC TRACEON (1222,-1);
GO

---TURN ON STATUS

DBCC TRACEOFF (1222,-1);
GO

--use SQL2
--Go

--Drop table TableOne
--Drop table TableTwo


--RUN THIS SCRIPT TO CREATE A TABLE TableOne AND TableTwo AND INSERT DATA
--THEN, EXECUTE STEP ONE.

use sql2
go

create table TableOne
(ID INT,
Fname varchar (20))

create table TableTwo
(ID INT,
Fname varchar (20))


Insert into TableOne values (1,'Tom')

Insert into TableTwo values (1,'Susan')

Select * from TableOne



--Check the status of lock with sp_who2 

sp_who2

--STEP 1
/*
SQL TRANSACTION 1 WILL UPDATE THE TableOne WITHOUT
COMMITTING THE TRANSACTION, AS SUCH THE TRAN 1 IS STILL
NOT COMMITTED.  THE LOCK IS STILL IN PLACE.
*/

Select * from TableOne


BEGIN TRAN
UPDATE TableOne 
SET FNAME = 'MARY'
WHERE ID = 	1

--THIS SHOWS THAT THE UPDATE WAS SUCCESSFULL, BUT NOT COMMITTED

--Select * from TableOne

--SP_WHO2

/*
SINCE I HAVE NOT SET THE TRANSACTION TO COMMIT, IT IS STILL AN OPEN TRANSACTION
AND ANY ATTEMP TO MODIFY TableOne WILL RESULT IN A BLOCK!!!
*/
-- ROLLBACK COMMAND UNDOS THE UPDATE OF TOM
ROLLBACK

COMMIT TRANSACTION

--VIEW THE BLOCKED SPID VIA SPROC  (NO BLOCKING AS THE SECOND SESSION HAS NOT STARTED)

SP_WHO2


--STEP 3
-- NOTICE THAT TRANSACTION 2 IS STULL RUNNING.
-- AS SOON AS I COMMIT TRNASACTION 1, TRANSACTION 2 WILL COMMIT!!!

Select * from TableOne  --(THIS SHOULD NOW BE UPDATED TO RANDOLPH)



-----------------------------------------------------------------
-----------------------------------------------------------------
----STEP 2  (CUT PASTE THE FOLLOWING BELOW TO ANOTHER SESSION)

--/*

--SQL TRANSACTION 2 WILL NOW TRY TO UPDATE THE SAME TABLE (TableOne)
--WITH AND UPDATE, BUT OBSERVE IT WILL NOT BE ABLE TO UPDATE THE TABLE
--AND AS SUCH WILL CONTINUE TO TRY TO EXECUTE THE TABLE.  THIS IS BECAUSE
--TableOne HAS AN OPEN TRANSACTION TO THE TABLE FOR AN UPDATE THAT HAS NOT
--BEEN COMMITTED!!!!
--AS SOON AS THE COMMITTED TRANSACTION HAS BEEN APPLIED TO TRANSACTION 1
--TRANSACTION 2 WILL UPDATE.


--*/

--BEGIN TRAN
--UPDATE TableOne 
--SET FNAME = 'randolph'
--WHERE ID = 	1

--COMMIT TRANSACTION




