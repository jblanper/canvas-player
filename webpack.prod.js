const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const TransformGlslPlugin = require('./transform-glsl-plugin');

module.exports = {
    mode: "production",
    entry: "./src/index.js",
    output: {
        filename: `[name].[hash].js`,
        path: path.resolve(__dirname, "dist")
    },
    module: {
        rules: [
            {
                test: /\.css$/,
                use: [
                    {
                        loader: MiniCssExtractPlugin.loader
                    },
                    "css-loader"
                ]
            },
            {
                test: /\.m?js$/,
                exclude: /(node_modules|bower_components)/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env'],
                        plugins: ['@babel/plugin-transform-runtime']
                    }
                }
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            title: 'Canvas Player',
        }),
        new CleanWebpackPlugin({
            cleanAfterEveryBuildPatterns: ['dist']
        }),
        new MiniCssExtractPlugin({
            filename: "[name].[contenthash].css"
        }),
        new TransformGlslPlugin({
            srcPath: path.resolve(__dirname, 'glsl/src'),
            distPath: path.resolve(__dirname, 'glsl/dist')
        })
    ],
    devtool: "source-map"
  };