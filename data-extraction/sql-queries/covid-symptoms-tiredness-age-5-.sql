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



PRINT 'Date,Tiredness-AGE-5-120'
select [date], ISNULL(Tiredness, 0) as Tiredness from #AllDates d left outer join (
select EntryDate, count(*) as Tiredness from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where ReadCode in ('168..00','168..11','168..12','1682.00','1683.00','1683.11','1684.00','1688.00','168Z.00','E205.12','R007.00','R007100','R007200','R007300','R007500','R007z00','R007z11','168..','1682.','1683.','1684.','1688.','168Z.','R007.','R0071','R0072','R0073','R0075','R007z')
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 5
	and year(EntryDate) - year_of_birth < 120
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
