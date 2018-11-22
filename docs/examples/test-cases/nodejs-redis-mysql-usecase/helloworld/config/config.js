BASE_DIR = __dirname;

module.exports = {
	port: 3000,
	//mysql
	mysql: {
		host: 'localhost',
		user: 'YOUR_MYSQL_USER',
		password: 'YOUR_MYSQL_PASSWORD',
		connectionLimit: 10,
		charset: 'utf8mb4',
	},
	database: 'helloworld',
	//redis
	redis: {
		tokenName: 'helloworld',
		host: '127.0.0.1',
		port: 6379,
		password: 'YOUR_REDIS_PASSWORD',
	},
}