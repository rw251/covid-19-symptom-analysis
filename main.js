const { 
  createSqlQueries,
  processRawDataFiles, 
  getTableOfResults, 
  drawIndividualBarCharts 
} = require('./utils');

createSqlQueries();

const processedData = processRawDataFiles();
const results = getTableOfResults(processedData);
// console.log(results);

drawIndividualBarCharts(processedData)
  .then((x) => console.log('All charts written'));

