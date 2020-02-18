'use strict';

var dateFormat = require('dateformat');
var now = new Date();
const table = process.env.TABLE

module.exports.absent = async event => {
  const today = dateFormat(now, "yyyy-mm-dd")
  return new Promise(function(resolve, reject) {
    
    var AWS = require("aws-sdk");

    var docClient = new AWS.DynamoDB.DocumentClient();
    
    var xyz = Date.now();

    var params = {
        TableName: table,
        KeyConditionExpression: "#Absent_Date = :Absent_Date",
        ExpressionAttributeNames:{
            "#Absent_Date": "Absent_Date"
        },
        ExpressionAttributeValues: {
            ":Absent_Date": today
        },
        Limit: 1,
        ScanIndexForward: false,
    };   
    
    docClient.query(params, function(err, res) { 
      if(err == null) {
        if (res.Items.length == 0) {
          resolve({statusCode: 200, body: JSON.stringify([])})
          return
        }

        const items = res.Items[0].Absent.map(function(item) {
          return {name: item["Name"], type: item["Type"], until: item["Until"], approved: item["Approved"]}
        })
        resolve({statusCode: 200, body: JSON.stringify(items)})
      } else {
        reject(err)
      }
    });
    
  });
};
