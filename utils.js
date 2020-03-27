const { readdirSync, readFileSync} = require('fs');
const { join } = require('path');

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

