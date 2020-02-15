'use strict';

var dateFormat = require('dateformat');
const https = require('https');
const request = require('request');
const AWS = require("aws-sdk");


module.exports.fetch = async event => {
  const now = new Date();
  const bambooToken = process.env.BAMBOO_TOKEN
  const table = process.env.TABLE
  const today = dateFormat(now, "yyyy-mm-dd")
  return new Promise(function(resolve, reject) {

    request.get('https://api.bamboohr.com/api/gateway.php/miquido/v1/time_off/requests?start=' + today + '&end=' + today, { json: true }, (err, res, body) => {
      if (err) { return console.log(err); }

      const mapped = body.filter(function(absence) {
        return absence.status.status != "canceled"
      }).map(function(absence) {
          return {
            Name: absence.name,
            Type: absence.type.name,
            Until: absence.end
          }
      })
      
      const putRequest = {
        TableName: table,
        Item: {
          Absent_Date: today,
          Absent: mapped,
          Id: + now + "",
          TTL: 24*60*60 + (+ (new Date()))
        }
      }

    let documentClient = new AWS.DynamoDB.DocumentClient();

    documentClient.put(putRequest, function(err, data) {
      if (err) reject(err)
      else resolve()
    });
    

    }).auth(bambooToken, 'xD', false);
});
};
