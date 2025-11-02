#!/usr/bin/env node

const { program } = require('commander');
const fs = require("fs");

program
    .version("0.1.0")
    .description("An example CLI for processing files")
    .command("process <file>")
    .description("Process the specified file")
    .option("-u, --uppercase", "Output in uppercase")
    .action((file, options) => {
        fs.readFile(file, "utf8", (err, data = '') => {
            if (err) {
                console.error(err);
                return;
            }

            let output = data;

            if (options.uppercase) {
                output = output.toUpperCase();
            }

            console.log(output);
        });
    });

program.parse(process.argv);