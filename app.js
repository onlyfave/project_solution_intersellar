const express = require('express');
const AWS = require('aws-sdk');

const app = express();
const port = 3000;

AWS.config.update({region: 'us-east-1'});
const sns = new AWS.SNS({apiVersion: '2010-03-31'});

const topicArn = 'arn:aws:sns:us-east-1:123456789012:mission-control-alerts';

app.use(express.json());

app.post('/alert', (req, res) => {
    const { message, severity } = req.body;

    const params = {
        Message: `Alert: ${severity} - ${message}`,
        TopicArn: topicArn
    };

    sns.publish(params, (err, data) => {
        if (err) {
            console.error("Error publishing to SNS", err);
            res.status(500).send("Error publishing alert");
        } else {
            console.log("Alert published successfully", data);
            res.status(200).send("Alert published successfully");
        }
    });
});

app.listen(port, () => {
    console.log(`Alert system listening at http://localhost:${port}`);
});
