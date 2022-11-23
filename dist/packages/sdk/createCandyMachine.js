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
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCandyMAchine = void 0;
const aptos_1 = require("aptos");
const fs = __importStar(require("fs"));
const fileStream = fs.createReadStream('originalnftprivatekey.txt');
console.log(fileStream);
const NODE_URL = "https://fullnode.testnet.aptoslabs.com";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";
const client = new aptos_1.AptosClient(NODE_URL);
const faucetClient = new aptos_1.FaucetClient(NODE_URL, FAUCET_URL);
var enc = new TextEncoder(); // always utf-8
const alice = new aptos_1.AptosAccount();
const bob = new aptos_1.AptosAccount();
const notwhitelist = new aptos_1.AptosAccount();
console.log("Alice Address: " + alice.address());
console.log("Bob Address: " + bob.address());
const pid = "0x40dd8067ef51dfd605b7204cfe72102c4db096a7690e034e683c175213a80e92";
function makeid(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxy';
    var charactersLength = characters.length;
    for (var i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}
function createCandyMAchine() {
    return __awaiter(this, void 0, void 0, function* () {
        const create_candy_machine = {
            type: "entry_function_payload",
            function: pid + "::candymachine::init_candy",
            type_arguments: [],
            arguments: [
                "Mokshya",
                "This is the description of test collection",
                "https://mokshya.io/nft/",
                alice.address(),
                "1000",
                "42",
                1000,
                1000,
                "1000",
                "2000",
                "100",
                [false, false, false],
                [false, false, false, false, false],
                "" + makeid(5),
            ]
        };
        let txnRequest = yield client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        let getresourceAccount = yield client.waitForTransactionWithResult(transactionRes.hash);
        return getresourceAccount;
    });
}
exports.createCandyMAchine = createCandyMAchine;
function create_whitelist(resource_account) {
    return __awaiter(this, void 0, void 0, function* () {
        const create_whitelist_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::create_whitelist",
            type_arguments: [],
            arguments: [resource_account, makeid(5)],
        };
        let txnRequest = yield client.generateTransaction(alice.address(), create_whitelist_payloads);
        let bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Whitelist created: " + transactionRes.hash);
    });
}
//# sourceMappingURL=createCandyMachine.js.map