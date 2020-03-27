const { processRawDataFiles, getTableOfResults, drawIndividualBarCharts } = require('./utils');

const processedData = processRawDataFiles();
const results = getTableOfResults(processedData);
// console.log(results);

drawIndividualBarCharts(processedData)
  .then((x) => console.log('All charts written'));

