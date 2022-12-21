#!/usr/bin/env node
"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const aptos_1 = require("aptos");
const fs = __importStar(require("fs"));
const create_candy_1 = require("./instructions/create_candy");
const create_whitelist_1 = require("./instructions/create_whitelist");
const seedGenerate_1 = require("./utils/seedGenerate");
const commander_1 = require("commander");
commander_1.program
    .version('0.0.1')
    .description("Candy machine smart contract for Aptos Blockchain.")
    .option('-c, --create_candy', 'create_candy')
    .option('-w, --create_whitelist', 'create_whitelist')
    .option('-w, --config', 'config')
    .option('-p, --pause_mint', 'pause_mint')
    .parse(process.argv);
const fileStream = JSON.parse(fs.readFileSync('config.json', "utf8"));
const options = commander_1.program.opts();
const client = new aptos_1.AptosClient(fileStream['NODE_URL']);
// const fileStream = JSON.parse(fs.readFileSync('config.json',"utf8"));
if (options.create_candy) {
    let argIndex = process.argv.indexOf('--config');
    const alice = new aptos_1.AptosAccount(aptos_1.HexString.ensure(fileStream['creator_private_key']).toUint8Array(), undefined);
    (0, create_candy_1.create_candy)(alice, fileStream, client, seedGenerate_1.makeid, aptos_1.AptosClient);
}
if (options.create_whitelist) {
    let argIndex = process.argv.indexOf('--config');
    const alice = new aptos_1.AptosAccount(aptos_1.HexString.ensure(fileStream['creator_private_key']).toUint8Array(), undefined);
    const client = new aptos_1.AptosClient(fileStream['NODE_URL']);
    (0, create_whitelist_1.create_whitelist)(alice, fileStream, client, seedGenerate_1.makeid, aptos_1.AptosClient);
}
if (!process.argv.slice(1).length) {
    commander_1.program.outputHelp();
}
//# sourceMappingURL=index.js.map