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

--dysuria



PRINT 'Date,Dysuria-AGE-5-120'
select [date], ISNULL(Dysuria, 0) as Dysuria from #AllDates d left outer join (
select EntryDate, count(*) as Dysuria from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where ReadCode in ('1A55.00','R081.00','R081000','R081z00','1A55.','R081.','R0810','R081z')
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 5
	and year(EntryDate) - year_of_birth < 120
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
