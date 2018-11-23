const mysql = require('mysql');
const logger = require('./LogService');
const config = require('../config/config');
const { database } = config;

class SqlService {
	constructor() {
		this.connection = {};
		this.init();
	}

	//mysql service init
	async init() {
		let mysqlConfig, pool;
		mysqlConfig = Object.assign({}, config.mysql);
		pool = mysql.createPool(mysqlConfig);
		this.connection.getConnection = (cb) => {
			pool.getConnection((err, connection) => {
				if (err) {
					cb(null);
					return;
				}
				logger.info(`mysql connect success`);
				cb(connection);
			})
		}
		//if exist database
		await this.init_database();
		//if exist table
		let querys = [
			{
				tableName: 'test',
				sqls: [
					{ sql: "CREATE TABLE IF NOT EXISTS " + `${database}.test` + " (`id` int(11) NOT NULL AUTO_INCREMENT,`content` text NOT NULL,PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8;", params: [] },
					{ sql: `insert into ${database}.test(content) values(?)`, params: ['hello,i am data from mysql'] },
				]
			},
		]
		await this.init_tables(querys);
	}

	//init database
	async init_database() {
		await this.query(`CREATE DATABASE IF NOT EXISTS ${database} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;`);
	}

	//init tables
	async init_tables(data) {
		for (let i = 0; i < data.length; i++) {
			let { tableName, sqls } = data[i];
			let isExist;
			try {
				isExist = await this.query(`select count(*) from ${database}.${tableName}`);
			} catch (e) {
			}

			if (!isExist) {
				logger.info(`Table ${tableName} is not existed~`);
				for (let j = 0; j < sqls.length; j++) {
					await this.query(sqls[j]['sql'], sqls[j]['params']);
				}
			}
		}
	}

	//mysql single query
	query(sql, params) {
		logger.info(sql)
		logger.info(params)
		return new Promise((resolve, reject) => {
			return this.connection.getConnection((connection) => {
				connection.query(sql, params ? params : [], (error, result) => {
					if (error) {
						//release connection
						connection.release()
						logger.info(error)
						reject(error)
					} else {
						//release connection
						connection.release()
						resolve(result)
					}
				})
			})
		})
	}
}

module.exports = new SqlService()