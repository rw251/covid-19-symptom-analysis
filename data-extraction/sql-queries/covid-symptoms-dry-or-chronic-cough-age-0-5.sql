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

--dry or chronic cough



PRINT 'Date,DryOrChronicCough-AGE-0-5'
select [date], ISNULL(DryOrChronicCough, 0) as DryOrChronicCough from #AllDates d left outer join (
select EntryDate, count(*) as DryOrChronicCough from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where ReadCode in ('1712.00','171A.00','171F.00','171K.00','R062100','1712.','171A.','171F.','171K.','R0621')
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 0
	and year(EntryDate) - year_of_birth < 5
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
