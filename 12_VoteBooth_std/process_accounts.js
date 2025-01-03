async function main() {
	process.env['RICARDO'] = 'Almeida';
	console.log('This works!');
}

main()
	.then(process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
