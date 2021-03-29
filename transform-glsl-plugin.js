const fs = require('fs');
const path = require('path');

class TransformGlslPlugin {
    constructor(options) {
        this.srcPath = options.srcPath;
        this.distPath = options.distPath;
    }

    apply(compiler) {
        const self = this;
        compiler.hooks.afterEmit.tap('after-compile', (compilation) => {
            self.applyToAllFiles((inputFile) => {
                self.transform(inputFile);
                const distGlslDir = path.resolve(__dirname, 'dist', 'glsl')
                if (!fs.existsSync(distGlslDir)) {
                    fs.mkdirSync(distGlslDir);
                }
                fs.copyFileSync(path.resolve(self.distPath, path.basename(inputFile)), path.resolve(distGlslDir, path.basename(inputFile)));
            });
            compilation.contextDependencies.add(self.srcPath);
        });
    }

    applyToAllFiles(callback) {
        fs.readdirSync(this.srcPath).forEach(file => {
            const filePath = path.resolve(this.srcPath, file);
            const stats = fs.lstatSync(filePath);
        
            if (stats.isFile()) {
                callback(filePath, file);
            }
        });
    }
    
    transform(inputFile) {
        let glsl = fs.readFileSync(inputFile).toString();
    
        // example "#include <lib/noise.glsl>"
        const importExp = glsl.match(/#include.+/g);
    
        if (importExp) {
            importExp.forEach(expr => {
                const fileName = expr.match(/<(.+)>/)[1];
                const imporFile = path.resolve(this.srcPath, fileName)
                const content = fs.readFileSync(imporFile).toString();
        
                glsl = glsl.replace(expr, content);
            });
            
            const outputFile= path.resolve(this.distPath, path.basename(inputFile))
            fs.writeFileSync(outputFile, glsl);
        }
    }
}

module.exports = TransformGlslPlugin;