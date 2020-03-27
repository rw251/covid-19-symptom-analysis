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

--itch
PRINT 'Date,Itch'
select [date], ISNULL(Itch, 0) as Itch from #AllDates d left outer join (
select EntryDate, count(*) as Itch from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('M115.00','M18..00','M180.00','M180.11','M180.13','M181.00','M181.11','M181000','M181100','M182.00','M182000','M182100','M182200','M182300','M182z00','M183000','M18y.00','M18y000','M18y100','M18y200','M18yz00','M18z.00','M18z.11','M18z.12','Myu2A00','Myu2B00','Myu2D00','M115.','M18..','M180.','M181.','M1810','M1811','M182.','M1820','M1821','M1822','M1823','M182z','M1830','M18y.','M18y0','M18y1','M18y2','M18yz','M18z.','Myu2A','Myu2B','Myu2D')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;