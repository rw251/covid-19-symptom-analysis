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



PRINT 'Date,HighTemperature-AGE-5-120'
select [date], ISNULL(HighTemperature, 0) as HighTemperature from #AllDates d left outer join (
select EntryDate, count(*) as HighTemperature from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where (
		--raised temperature from code
		ReadCode in ('14OS.00','14OT.00','14OV.00','165..11','165..12','1652.00','1653.00','1656.00','171F.00','2E...00','2E...11','2E1..00','2E12.00','2E13.00','2E13.11','2E1Z.00','2E2..00','2E2Z.00','2E34.00','2E35.00','2E4..00','2E41.00','2E42.00','2E43.00','2E44.00','2E45.00','2E46.00','2E47.00','2E48.00','2E49.00','2E4Z.00','2EZ..00','R006.00','R006.11','R006000','R006100','R006200','R006300','R006y00','R006z00','14OS.','14OT.','14OV.','1652.','1653.','1656.','171F.','2E...','2E1..','2E12.','2E13.','2E1Z.','2E2..','2E2Z.','2E34.','2E35.','2E4..','2E41.','2E42.','2E43.','2E44.','2E45.','2E46.','2E47.','2E48.','2E49.','2E4Z.','2EZ..','R006.','R0060','R0061','R0062','R0063','R006y','R006z')
		OR
		--raised temperature from code value
		(
			ReadCode in ('165..00','165Z.00','2923.00','2E21.00','2E21.11','2E22.00','2E23.00','2E24.00','2E25.00','2E26.00','2E27.00','2E3..11','2E4..11','165..','165Z.','2923.','2E21.','2E22.','2E23.','2E24.','2E25.','2E26.','2E27.')
			and (CodeValue >= 37.8 and CodeValue < 50)
		)
	)
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 5
	and year(EntryDate) - year_of_birth < 120
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
