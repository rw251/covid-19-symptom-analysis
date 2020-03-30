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

--muscle pain

PRINT 'Date,MusclePain'
select [date], ISNULL(MusclePain, 0) as MusclePain from #AllDates d left outer join (
select EntryDate, count(*) as MusclePain from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('N241000','N241011','N241012','N241300','N2410','N2413')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;


