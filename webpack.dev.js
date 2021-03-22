const path = require('path');
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CopyPlugin = require("copy-webpack-plugin");

module.exports = {
    mode: 'development',
    entry: './src/index.js',
    plugins: [
        new HtmlWebpackPlugin({
            title: 'Canvas Player',
        }),
        new CopyPlugin({
            patterns: [
                { from: 'glsl/dist/', to: 'glsl' }
            ]
        })
    ],
    output: {
        filename: '[name].bundle.js',
        path: path.resolve(__dirname, 'dist'),
        clean: true
    },
    devServer: {
        contentBase: './dist',
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

                test: /\.glsl/,
                type: 'asset',
            }
        ],
    },
};