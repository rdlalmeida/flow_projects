const { mintFlow } = require('flow-js-testing');

async function main() {
	await mintFlow('0x179b6b1cb6755e31', '1000.0');
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
