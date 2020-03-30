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

--raised temperature
{{!MAIN}}
PRINT 'Date,HighTemperature'
select [date], ISNULL(HighTemperature, 0) as HighTemperature from #AllDates d left outer join (
select EntryDate, count(*) as HighTemperature from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where (
		--raised temperature from code
		ReadCode in ('{{HIGH_TEMPERATURE_CODES}}')
		OR
		--raised temperature from code value
		(
			ReadCode in ('{{TEMPERATURE_CODES}}')
			and (CodeValue >= 37.8 and CodeValue < 50)
		)
	)
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
{{MAIN}}

{{!AGE}}
PRINT 'Date,HighTemperature-AGE-{{LOWER_AGE}}-{{UPPER_AGE}}'
select [date], ISNULL(HighTemperature, 0) as HighTemperature from #AllDates d left outer join (
select EntryDate, count(*) as HighTemperature from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where (
		--raised temperature from code
		ReadCode in ('{{HIGH_TEMPERATURE_CODES}}')
		OR
		--raised temperature from code value
		(
			ReadCode in ('{{TEMPERATURE_CODES}}')
			and (CodeValue >= 37.8 and CodeValue < 50)
		)
	)
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= {{LOWER_AGE}}
	and year(EntryDate) - year_of_birth < {{UPPER_AGE}}
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
{{AGE}}