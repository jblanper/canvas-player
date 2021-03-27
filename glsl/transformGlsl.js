#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const SRC_PATH = path.join(__dirname, 'src');
const DIST_PATH = path.join(__dirname, 'dist');

function applyToAllFiles(callback) {
    fs.readdirSync(SRC_PATH).forEach(file => {
        const filePath = path.resolve(SRC_PATH, file);
        const stats = fs.lstatSync(filePath);
    
        if (stats.isFile()) {
            callback(filePath, file);
        }
    });
}

function transform(inputFile) {
    let glsl = fs.readFileSync(inputFile).toString();

    // example "#include <lib/noise.glsl>"
    const importExp = glsl.match(/#include.+/g);

    if (importExp) {
        console.log(`Found ${importExp.length} import/s in ${path.relative('.', inputFile)} (${importExp.join(', ')})`)
        importExp.forEach(expr => {
            const fileName = expr.match(/<(.+)>/)[1];
            const imporFile = path.resolve(SRC_PATH, fileName)
            const content = fs.readFileSync(imporFile).toString();
    
            glsl = glsl.replace(expr, content);
        });
        
        const outputFile= path.resolve(DIST_PATH, path.basename(inputFile))
        console.log(`Writing file ${path.relative('.', outputFile)}`)
        console.log('----------------------------------------')
        fs.writeFileSync(outputFile, glsl);
    }
}

function main() {
    applyToAllFiles(transform);
}

main()