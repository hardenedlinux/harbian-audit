const redis = require("redis")
const logger = require('./LogService')
const config = require('../config/config')

class RedisService {
	constructor() {
		this.client = null
		this.init()
		this.set(config.redis.tokenName, 'hello,i am data from redis')
	}

	//redis service init
	init() {
		let option = {}
		option['host'] = config.redis.host
		option['port'] = config.redis.port
		if (config.redis.password) {
			option['password'] = config.redis.password
		}
		this.client = redis.createClient(option)

		this.client.on("error", function (err) {
			console.log('Redis connect fail!')
			logger.info(err)
		});
	}

	/*
	* get value
	* redis.get('tokens','object') /  redis.get('tokens')
	*/
	get(key, type) {
		return new Promise((resolve, reject) => {
			this.client.get(key, (err, reply) => {
				if (err) {
					logger.info(err)
					reject(err)
				} else {
					if (type === 'object') {
						resolve(JSON.parse(reply))
					} else {
						resolve(reply)
					}
				}
			})
		})
	}

	//
	/*
	* set value
	* redis.set('tokens',tokens,'object') / redis.set('tokens',tokens)
	*/
	set(key, value, type) {
		return new Promise((resolve, reject) => {
			this.client.set(key, (type === 'object' ? JSON.stringify(value) : value), (err, reply) => {
				if (err) {
					logger.info(err)
					reject(err)
				} else {
					resolve(reply)
				}
			})
		})
	}
}

module.exports = new RedisService()