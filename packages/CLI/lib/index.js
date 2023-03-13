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
const update_root_1 = require("./instructions/update_root");
const seedGenerate_1 = require("./utils/seedGenerate");
const commander_1 = require("commander");
commander_1.program
    .version('0.0.1')
    .description("Candy machine smart contract for Aptos Blockchain.")
    .option('-c, --create_candy', 'create_candy')
    .option('-u, --update_root', 'update_root')
    .option('-w, --config', 'config')
    .option('-p, --pause_mint', 'pause_mint')
    .parse(process.argv);
const options = commander_1.program.opts();
if (options.create_candy) {
    let argIndex = process.argv.indexOf('--config');
    const fileStream = JSON.parse(fs.readFileSync(process.argv[argIndex + 1], "utf8"));
    const client = new aptos_1.AptosClient(fileStream['NODE_URL']);
    const alice = new aptos_1.AptosAccount(aptos_1.HexString.ensure(fileStream['creator_private_key']).toUint8Array(), undefined);
    (0, create_candy_1.create_candy)(alice, fileStream, client, seedGenerate_1.makeid, aptos_1.AptosClient);
}
else if (options.update_root) {
    let argIndex = process.argv.indexOf('--config');
    const fileStream = JSON.parse(fs.readFileSync(process.argv[argIndex + 1], "utf8"));
    const alice = new aptos_1.AptosAccount(aptos_1.HexString.ensure(fileStream['creator_private_key']).toUint8Array(), undefined);
    const client = new aptos_1.AptosClient(fileStream['NODE_URL']);
    (0, update_root_1.update_root)(alice, fileStream, client, seedGenerate_1.makeid, aptos_1.AptosClient);
}
else {
    commander_1.program.outputHelp();
}
//# sourceMappingURL=index.js.map