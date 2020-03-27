const { processRawDataFiles, getTableOfResults } = require('./utils');

const processedData = processRawDataFiles();
const results = getTableOfResults(processedData);
console.log(results);

