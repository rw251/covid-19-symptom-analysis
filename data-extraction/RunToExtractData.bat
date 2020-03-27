SET SMASH.DB=PatientSafety_Records

forfiles /p sql-queries /s /m covid*.sql /c "cmd /c sqlcmd -E -d %SMASH.DB% -i @path -W -s^",^" -h -1 -o data\@path.txt"

REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-tiredness.sql -W -s"," -h -1 -o data\covid.tiredness.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-cough.sql -W -s"," -h -1 -o data\covid.cough.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-dry-cough.sql -W -s"," -h -1 -o data\covid.dry-cough.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-dry-or-chronic-cough.sql -W -s"," -h -1 -o data\covid.dry-or-chronic-cough.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-high-temperature.sql -W -s"," -h -1 -o data\covid.high-temperature.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-runny-nose.sql -W -s"," -h -1 -o data\covid.runny-nose.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-blocked-nose.sql -W -s"," -h -1 -o data\covid.blocked-nose.txt
REM sqlcmd -E -d %SMASH.DB% -i sql-queries\covid-symptoms-sore-throat.sql -W -s"," -h -1 -o data\covid.sore-throat.txt

pause