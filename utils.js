const { readdirSync, readFileSync, createWriteStream } = require('fs');
const { join } = require('path');
const Chart = require('chart.js');
const { createCanvas } = require('canvas')

let output = {};

const processDataFile = (filename) => {
  const symptom = filename.split('.')[1];
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
    title: 'yo',
    data: {
        labels,
        datasets: [{
            label,
            data,
            fill: false,
            backgroundColor: "rgb(91, 155, 213)",
            borderColor: "rgb(75, 192, 192)",
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

