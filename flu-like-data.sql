select YEAR(EntryDate), MONTH(EntryDate), count(*) FROM (
select NHSNo, entrydate as EntryDate from DataFromSIR.dbo.journal
where (
	--raised temperature from code
	--ReadCode like 'H27%'
	ReadCode = 'H27z.'
)
and EntryDate >= '2000-01-01'
group by NHSNo, entrydate) sub
group by YEAR(EntryDate), MONTH(EntryDate)
order by YEAR(EntryDate), MONTH(EntryDate)