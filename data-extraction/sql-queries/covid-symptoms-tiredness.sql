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

--tiredness
PRINT 'Date,Tiredness'
select [date], ISNULL(Tiredness, 0) as Tiredness from #AllDates d left outer join (
select EntryDate, count(*) as Tiredness from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('168..11','168..12','168..','168..00','168Z.00','168Z.','1688.00','1688.','1684.00','1684.','1683.00','1683.','1683.11','1682.00','1682.','R007.00','R007.','R007100','R0071','R007z11','R007z00','R007z','R007300','R0073','R007200','R0072','R007500','R0075','E205.12')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;