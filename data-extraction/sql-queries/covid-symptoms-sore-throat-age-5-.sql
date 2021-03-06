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

--sore throat



PRINT 'Date,SoreThroat-AGE-5-120'
select [date], ISNULL(SoreThroat, 0) as SoreThroat from #AllDates d left outer join (
select EntryDate, count(*) as SoreThroat from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow s
	inner join patients p on p.patid = s.PatID
	where ReadCode in ('1C9..00','1C9..11','1C92.00','1C93.00','1C9Z.00','2DC2.00','AA12.00','H02..00','H02..11','H02..12','H02..13','H020.00','H021.00','H022.00','H024.00','H02z.00','H121200','H121300','H121400','H121500','H271100','Hyu0100','1C9..','1C92.','1C93.','1C9Z.','2DC2.','AA12.','H02..','H020.','H021.','H022.','H024.','H02z.','H1212','H1213','H1214','H1215','H2711','Hyu01')
	and EntryDate >= '2000-01-01'
	and year(EntryDate) - year_of_birth >= 5
	and year(EntryDate) - year_of_birth < 120
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;
