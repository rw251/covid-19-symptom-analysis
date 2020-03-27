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

--joint pain
PRINT 'Date,JointPain'
select [date], ISNULL(JointPain, 0) as JointPain from #AllDates d left outer join (
select EntryDate, count(*) as JointPain from (
	select PatID, EntryDate from SIR_ALL_Records_Narrow
	where ReadCode in ('1M01.00','1M03.00','1M10.00','1M12.00','N094.00','N094.11','N094000','N094100','N094111','N094200','N094211','N094300','N094311','N094400','N094411','N094500','N094512','N094600','N094611','N094700','N094711','N094800','N094900','N094A00','N094B00','N094C00','N094D00','N094D11','N094E00','N094F00','N094F11','N094G00','N094H00','N094J00','N094K00','N094K12','N094L00','N094M00','N094N00','N094P00','N094Q00','N094R00','N094S00','N094T00','N094U00','N094V00','N094W00','N094z00','1M01.','1M03.','1M10.','1M12.','N094.','N0940','N0941','N0942','N0943','N0944','N0945','N0946','N0947','N0948','N0949','N094A','N094B','N094C','N094D','N094E','N094F','N094G','N094H','N094J','N094K','N094L','N094M','N094N','N094P','N094Q','N094R','N094S','N094T','N094U','N094V','N094W','N094z')
	and EntryDate >= '2000-01-01'
	group by PatID, EntryDate
) sub 
group by EntryDate
) a on a.EntryDate = d.date
order by date;