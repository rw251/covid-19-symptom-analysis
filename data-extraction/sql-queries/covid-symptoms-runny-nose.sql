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

--runny nose

PRINT 'Date,RunnyNose'
select [date], ISNULL(RunnyNose, 0) as RunnyNose from #AllDates d left outer join (
select EntryDate, count(*) as RunnyNose from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('1C83.00','1C83.11','1C83.12','1C83.13','1C84.00','2D2..00','2D2..11','2D21.00','2D22.00','2D23.00','2D2Z.00','1C83.','1C84.','2D2..','2D21.','2D22.','2D23.','2D2Z.')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;


