const fetch = require("node-fetch");
const $ = require("cheerio");
const { PdfReader } = require("pdfreader");

const getListOfPdfs = (
  url = "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2017-to-2018-season"
) => {
  return fetch(url)
    .then((resp) => resp.text())
    .then((html) => $("#documents", html))
    .then((data) =>
      data
        .find("section")
        .toArray()
        .map((section) => {
          const title = $(section).find(".title").text();
          if (title.indexOf("National flu report:") > -1) {
            return $(section).find(".title a").attr("href");
          }
          return false;
        })
        .filter(Boolean)
    );
};

const readlines = async (buffer, xwidth) => {
  return new Promise((resolve, reject) => {
    var pdftxt = "";
    new PdfReader().parseBuffer(buffer, function (err, item) {
      if (err) console.log("pdf reader error: " + err);
      else if (!item) {
        resolve(pdftxt.replace(/  +/g, " ").replace(/ +,/g, ","));
      } else if (item.text) {
        var t = 0;
        pdftxt += " " + item.text;
      }
    });
  });
};

const nLookup = {
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
  six: 6,
  seven: 7,
  eight: 8,
  nine: 9,
  ten: 10,
  eleven: 11,
};
const n = (x) => {
  if (nLookup[x]) return nLookup[x];
  else return +x;
};
const getFigureFromPdf = async (
  url = "https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/707932/Weekly_national_influenza_report_week_20_2018.pdf"
) => {
  if (url.indexOf("summary") > -1) return null;
  const response = await fetch(url);
  const buffer = await response.buffer();
  const lines = await readlines(buffer);
  let m = lines
    .replace(/ /g, "")
    .match(/Inweek([0-9]+),therewere([^I]+?)hospitalisedconfirmedinfluenza/);
  if (m) {
    const [, week, cases] = m;
    return { week: n(week), cases: n(cases) };
  }
  m = lines
    .replace(/ /g, "")
    .match(/Inweek([0-9]+),nohospitalisedconfirmedinfluenza/);
  if (m) {
    const [, week] = m;
    return { week: n(week), cases: 0 };
  }
  m = lines
    .replace(/ /g, "")
    .match(
      /(.{25})newhospitalisedconfirmedinfluenzacases.*?werereportedthroughtheUSISSsentinel.*?inweek([0-9]+)/
    );
  if (m) {
    const [, cases, week] = m;
    return { week: n(week), cases };
  }
  // console.log(url);
  // console.log(lines);
  // process.exit();
  return null;
};

const urls = [
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2013-to-2014-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2014-to-2015-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2015-to-2016-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2016-to-2017-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2017-to-2018-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2018-to-2019-season",
  "https://www.gov.uk/government/statistics/weekly-national-flu-reports-2019-to-2020-season",
];

getListOfPdfs(urls[2])
  .then((list) => Promise.all(list.map((pdfUrl) => getFigureFromPdf(pdfUrl))))
  .then((x) => x.filter(Boolean))
  .then((x) => console.log(x.map((y) => `${y.week}\t${y.cases}`).join("\n")))
  .catch((err) => console.log(err));
