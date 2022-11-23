#!/usr/bin/env node
import { AptosClient, AptosAccount, FaucetClient,HexString} from "aptos";
import * as fs from "fs"
import {create_candy} from "./instructions/create_candy"
import {create_whitelist} from "./instructions/create_whitelist"
import {makeid} from "./utils/seedGenerate"
import {program} from "commander"

program
  .version('0.0.1')
  .description("Candy machine smart contract for Aptos Blockchain.")
  .option('-c, --create_candy', 'create_candy')
  .option('-w, --create_whitelist', 'create_whitelist')
  .option('-w, --config', 'config')
  .option('-p, --pause_mint', 'pause_mint')
  .parse(process.argv);

const options = program.opts();

const NODE_URL = "https://fullnode.devnet.aptoslabs.com";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);

// const fileStream = JSON.parse(fs.readFileSync('config.json',"utf8"));

if (options.create_candy) {
  let argIndex = process.argv.indexOf('--config')
  const fileStream = JSON.parse(fs.readFileSync('config.json',"utf8"));
  const alice = new AptosAccount(HexString.ensure(fileStream['creator_private_key']).toUint8Array(),undefined);
  create_candy(alice,fileStream,client,makeid,AptosClient);  
}
if (options.create_whitelist) {
  let argIndex = process.argv.indexOf('--config')
  const fileStream = JSON.parse(fs.readFileSync('config.json',"utf8"));
  const alice = new AptosAccount(HexString.ensure(fileStream['creator_private_key']).toUint8Array(),undefined);
  create_whitelist(alice,fileStream,client,makeid,AptosClient);  
}
if (!process.argv.slice(1).length) {
  program.outputHelp();
}

