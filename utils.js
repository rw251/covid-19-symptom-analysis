const { readdirSync, readFileSync, writeFileSync, createWriteStream } = require('fs');
const { join } = require('path');
const Chart = require('chart.js');
const { createCanvas } = require('canvas')

let output = {};

const processDataFile = (filename) => {
  const symptom = filename.replace('covid-symptoms-', '').split('.')[0];
  output[symptom] = {};
  readFileSync(join('data-extraction', 'data', filename), 'utf8')
    .split('\n')
    .slice(1)
    .forEach(line => {
      const [dateString, count] = line.trim().replace('/\r/g','').split(',');
      if(!dateString) return;
      const date = new Date(dateString);
      if(date.getMonth()<7) return;
      const year = date.getFullYear();
      if(!output[symptom][year]) output[symptom][year] = 0;
      output[symptom][year] += +count;
    });
}

exports.processRawDataFiles = (directory = './data-extraction/data') => {
  output = {};
  readdirSync(directory)
    .filter(x => x.indexOf('.txt') > -1)
    .forEach(file => processDataFile(file));
  return output;
}

const codesFromFile = (pathToFile) => readFileSync(pathToFile, 'utf8')
  .split('\n')
  .map(x => x.split('\t')[0]);

const codesWithoutTermCode = (codes) => {
  const codesWithoutTermExtension = codes
    .filter(x => x.length===7 && x[5] === '0' && x[6] === '0')
    .map(x => x.substr(0,5));
  return codes.concat(codesWithoutTermExtension);
}

const createHighTemperatureQuery = () => {
  const template = readFileSync(join(__dirname, 'data-extraction', 'sql-queries', 'template-high-temperature.sql'), 'utf8');
  const highTempCodes = codesFromFile(join(__dirname, 'data-extraction', 'codesets', 'covid-symptom-high-temperature.txt'), 'utf8');
  const allHighTempCodes = codesWithoutTermCode(highTempCodes);
  const tempCodes = codesFromFile(join(__dirname, 'data-extraction', 'codesets', 'covid-symptom-temperature.txt'), 'utf8');
  const allTempCodes = codesWithoutTermCode(tempCodes);
  let query = template.replace(/\{\{HIGH_TEMPERATURE_CODES\}\}/g, allHighTempCodes.join("','"));
  query = query.replace(/\{\{TEMPERATURE_CODES\}\}/g, allTempCodes.join("','"));
  writeFileSync(join(__dirname, 'data-extraction', 'sql-queries', `covid-symptoms-high-temperature.sql`), query);
}

exports.createSqlQueries = () => {
  createHighTemperatureQuery();
  const template = readFileSync(join(__dirname, 'data-extraction', 'sql-queries', 'template-standard.sql'), 'utf8');
  readdirSync(join(__dirname, 'data-extraction', 'codesets'))
    .filter(x => {
      if(x.indexOf('.json') > -1) return false; // don't want the metadata
      if(x.indexOf('temperature') > -1) return false; // temperature query is different
      return true;
    })
    .map(filename => {
      const symptomDashed = filename.split('.')[0].replace('covid-symptom-','');
      const symptomCapitalCase = symptomDashed.split('-').map(x => x[0].toUpperCase() + x.slice(1)).join('');
      const symptomLowerSpaced = symptomDashed.split('-').map(x => x.toLowerCase()).join(' ');
      const codes = codesFromFile(join(__dirname, 'data-extraction', 'codesets', filename));
      const allCodes = codesWithoutTermCode(codes);
      const codeString = allCodes.join("','");
      let query = template.replace(/\{\{SYMPTOM_LOWER_SPACED\}\}/g, symptomLowerSpaced);
      query = query.replace(/\{\{SYMPTOM_CAPITAL_NO_SPACE\}\}/g, symptomCapitalCase);
      query = query.replace(/\{\{SYMPTOM_DASHED\}\}/g, symptomDashed);
      query = query.replace(/\{\{CLINICAL_CODES\}\}/g, codeString);
      writeFileSync(join(__dirname, 'data-extraction', 'sql-queries', `covid-symptoms-${symptomDashed}.sql`), query);
    })
};

exports.getTableOfResults = (processedData, fieldSeparator = '\t', rowSeparator = '\n') => {
  const header = ['Symptom'];
  for(var i = 2000; i < 2020; i++) {
    header.push(i);
  }
  const tableRows = [header.join(fieldSeparator)];
  Object.keys(output).forEach(key => {
    const row = [key];
    for(var i = 2000; i < 2020; i++) {
      row.push(output[key][i]);
    }
    tableRows.push(row.join(fieldSeparator));
  });
  return tableRows.join(rowSeparator);
}

const createBarChart = (label, rawData) => new Promise((resolve) => {
  const canvas = createCanvas(1600, 900);
  const ctx = canvas.getContext('2d');
  
  const labels = Object.keys(rawData).sort();
  const data = Object.keys(rawData).sort().map(year => rawData[year]);
 
  Chart.defaults.global.defaultFontColor = 'black';
  Chart.defaults.global.defaultFontSize = 24;
  Chart.defaults.global.defaultFontStyle = '600';
  var myChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels,
        datasets: [{
            label,
            data,
            fill: false,
            backgroundColor: "rgb(91, 155, 213)",
            barPercentage: 0.6,
            lineTension: 0.1
        }]
    },
    options: {
      title: {
        display: true,
        text: `Total number of patients reporting the symptom "${label}" in the period 1st August - 31st December every year`,
      },
      legend: {
        display: false,
      },
      responsive:false,
      animation:false,
      width:1024,
      height:768,
      scales: {
        yAxes: [{
            ticks: {
                beginAtZero: true
            },
            gridLines: {
              color: "rgb(30,30,30)",
              zeroLineColor: "rgb(30,30,30)",
            }
        }],
        xAxes: [{
          gridLines: {
            lineWidth: 0,
          }
        }]
      },
    }
  });
   
  const out = createWriteStream(join(__dirname, 'images', `all-years-${label}.png`));
  const stream = canvas.createPNGStream();
  stream.pipe(out);
  out.on('finish', resolve);
});

exports.drawIndividualBarCharts = (processedData) => Promise.all(
  Object
    .keys(processedData)
    .map(label => createBarChart(label, processedData[label]))
);

