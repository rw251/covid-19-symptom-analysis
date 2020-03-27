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

--all cough
PRINT 'Date,AnyCough'
select [date], ISNULL(AnyCough, 0) as AnyCough from #AllDates d left outer join (
select EntryDate, count(*) as AnyCough from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('171..00','171..11','171Z.00','171K.00','171J.00','171F.00','171E.00','171D.00','171C.00','171B.00','171A.00','1719.00','1719.11','1717.00','1715.00','1714.00','1713.00','1712.00','1716.11','1716.00','R062.00','R062100','173B.00','R063000','171..','171Z.','171K.','171J.','171F.','171E.','171D.','171C.','171B.','171A.','1719.','1717.','1715.','1714.','1713.','1712.','1716.','R062.','R0621','173B.','R0630')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;


