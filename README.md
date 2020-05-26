# COVID-19 symptoms Nov-Dec 2019

Evaluating if the increase in flu-like symptoms at the end of 2019 in Salford is explained by an unusually early flu season - or if COVID-19 was circulating earlier than believed.

## Instructions

1. Updated codesets are placed in `data-extraction/codesets`
2. Run `npm start` to create the SQL queries necessary for data extraction
3. When on the server execute `data-extraction/RunToExtractData.bat` to extract the data
4. Data ends up in `data-extraction/data`

## Analysis

### Pre-requisites

1. R installed and bin directory added to the PATH variable - e.g. so that `Rscript` entered at a command prompt actually does something
2. nodejs installed
3. In root of project execute `npm i` to install dependencies (none at present but you never know)

### Execution

Navigate to the root of the project and execute:

```
npm run analyse
```

All outputs appear in the `./outputs` directory.
