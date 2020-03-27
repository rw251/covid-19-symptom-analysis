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

--{{SYMPTOM_LOWER_SPACED}}
PRINT 'Date,{{SYMPTOM_CAPITAL_NO_SPACE}}'
select [date], ISNULL({{SYMPTOM_CAPITAL_NO_SPACE}}, 0) as {{SYMPTOM_CAPITAL_NO_SPACE}} from #AllDates d left outer join (
select EntryDate, count(*) as {{SYMPTOM_CAPITAL_NO_SPACE}} from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('{{CLINICAL_CODES}}')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;