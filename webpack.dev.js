const path = require('path');
const HtmlWebpackPlugin = require("html-webpack-plugin");
const TransformGlslPlugin = require('./transform-glsl-plugin');

module.exports = {
    mode: 'development',
    entry: './src/index.js',
    plugins: [
        new HtmlWebpackPlugin({
            title: 'Canvas Player',
        }),
        new TransformGlslPlugin({
            srcPath: path.resolve(__dirname, 'glsl/src'),
            distPath: path.resolve(__dirname, 'glsl/dist')
        })
    ],
    output: {
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'dist'),
        clean: true
    },
    devServer: {
        contentBase: './dist',
        host: "0.0.0.0",
        disableHostCheck: true,
        historyApiFallback: true,
        stats: "minimal"
    },
    devtool: 'inline-source-map',
    module: {
        rules: [
            {
                test: /\.css$/i,
                use: ['style-loader', 'css-loader'],
            },
            {
                test: /\.m?js$/,
                exclude: /(node_modules|bower_components)/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env'],
                        plugins: [
                            '@babel/plugin-transform-runtime'
                        ]
                    }
                }
            }
        ],
    },
};