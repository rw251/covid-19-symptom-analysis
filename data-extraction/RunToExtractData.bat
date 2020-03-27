SET SMASH.DB=PatientSafety_Records

sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-tiredness.sql -W -s"," -h -1 -o data\covid.tiredness.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-cough.sql -W -s"," -h -1 -o data\covid.cough.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-dry-cough.sql -W -s"," -h -1 -o data\covid.dry-cough.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-dry-or-chronic-cough.sql -W -s"," -h -1 -o data\covid.dry-or-chronic-cough.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-high-temperature.sql -W -s"," -h -1 -o data\covid.high-temperature.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-runny-nose.sql -W -s"," -h -1 -o data\covid.runny-nose.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-blocked-nose.sql -W -s"," -h -1 -o data\covid.blocked-nose.txt
sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-sore-throat.sql -W -s"," -h -1 -o data\covid.sore-throat.txt

pause