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

--headache

PRINT 'Date,Headache'
select [date], ISNULL(Headache, 0) as Headache from #AllDates d left outer join (
select EntryDate, count(*) as Headache from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('1B1G.00','1B1G.11','1B1G000','1B1G100','1BA..00','1BA2.00','1BA3.00','1BA4.00','1BA5.00','1BA6.00','1BA7.00','1BA8.00','1BA9.00','1BAZ.00','1BB..00','1BB1.00','1BB2.00','1BB3.00','1BB4.00','1BBZ.00','E278100','E278111','F261100','F262600','F262900','F262A00','F2X..00','Fyu5400','Fyu5A00','Fyu5F00','R040.00','1B1G.','1B1G0','1B1G1','1BA..','1BA2.','1BA3.','1BA4.','1BA5.','1BA6.','1BA7.','1BA8.','1BA9.','1BAZ.','1BB..','1BB1.','1BB2.','1BB3.','1BB4.','1BBZ.','E2781','F2611','F2626','F2629','F262A','F2X..','Fyu54','Fyu5A','Fyu5F','R040.')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;


