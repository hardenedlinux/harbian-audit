const express = require('express');
const sql = require('./services/SqlService');
const myredis = require('./services/RedisService');
const { database, redis, port } = require('./config/config');
const app = express();

app.get('/', async (req, res) => {
    //data from mysql
    let data_mysql = await sql.query(`select content from ${database}.test limit 1`);
    //data from redis
    let data_redis = await myredis.get(redis.tokenName);
    res.send(`
        Hello World!<br/><br/>
        <span style="width:160px;font-weight:bold;display:inline-block;">Data from mysql</span>  ${data_mysql[0]['content']}<br/><br/>
        <span style="width:160px;font-weight:bold;display:inline-block;">Data from redis</span> ${data_redis}
    `);
});

app.listen(port, function () {
    console.log('Hello world run on port 3000!');
});

