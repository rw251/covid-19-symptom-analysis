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

--blocked nose

PRINT 'Date,BlockedNose'
select [date], ISNULL(BlockedNose, 0) as BlockedNose from #AllDates d left outer join (
select EntryDate, count(*) as BlockedNose from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('1C86.00','H01..00','H01..11','H010.00','H010.11','H011.00','H012.00','H013.00','H014.00','H01y.00','H01y000','H01yz00','H01z.00','H130.12','H131.11','H13y100','Hyu0000','1C86.','H01..','H010.','H011.','H012.','H013.','H014.','H01y.','H01y0','H01yz','H01z.','H13y1','Hyu00')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;


