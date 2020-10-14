--Just want the output, not the messages
SET NOCOUNT ON; 

--populate table with all dates from 2000-01-01
IF OBJECT_ID('tempdb..#AllDates') IS NOT NULL DROP TABLE #AllDates;
CREATE TABLE #AllDates ([date] date);
declare @dt datetime = '2000-01-01'
declare @dtEnd datetime = GETDATE();
WHILE (@dt < @dtEnd) BEGIN
    insert into #AllDates([date])
        values(@dt)
    SET @dt = DATEADD(day, 1, @dt)
END;

--anosmia



PRINT 'Date,Anosmia-AGE-5-120'
select [date], ISNULL(Anosmia, 0) as Anosmia from #AllDates d left outer join (
select EntryDate, count(*) as Anosmia from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where ReadCode in ('﻿R011.00','R011z00','R011200','R011100','R011000','1B45.11','1B45.12','1B45.00','ZV41511','ZV41512','ZV41500','1924.11','1924.00','2BK3.00','2BK2.00','2BP3.00','2BP2.00','Ryu5200','SJ1y011','R011z','R0112','R0111','R0110','1B45.','ZV415','1924.','2BK3.','2BK2.','2BP3.','2BP2.','Ryu52')
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 5
	and year(EntryDate) - year_of_birth < 120
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
