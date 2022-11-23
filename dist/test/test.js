"use strict";
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
const aptos_1 = require("aptos");
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
describe("whitelist", () => {
    it("Whitelist Mint", () => __awaiter(void 0, void 0, void 0, function* () {
        yield faucetClient.fundAccount(alice.address(), 1000000000);
        yield faucetClient.fundAccount(bob.address(), 1000000000);
        yield faucetClient.fundAccount(notwhitelist.address(), 1000000000);
        const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
        yield delay(200000);
        const date = Math.floor(new Date().getTime() / 1000);
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
                date - 1000,
                date - 1000,
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
        console.log("Candy Machine created: " + transactionRes.hash);
        let getresourceAccount = yield client.waitForTransactionWithResult(transactionRes.hash);
        let addresses = [];
        for (let i = 0; i < 1000; i++) {
            addresses.push(bob.address());
        }
        const create_whitelist_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::create_whitelist",
            type_arguments: [],
            arguments: [getresourceAccount['changes'][2]['address'], addresses, "" + makeid(5)],
        };
        console.log("Resource Address: " + getresourceAccount['changes'][2]['address']);
        txnRequest = yield client.generateTransaction(alice.address(), create_whitelist_payloads);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Whitelist created: " + transactionRes.hash);
        for (let mint = 0; mint < 5; mint++) {
            const create_mint_script1 = {
                type: "entry_function_payload",
                function: pid + "::candymachine::mint_script",
                type_arguments: [],
                arguments: [
                    getresourceAccount['changes'][2]['address']
                ],
            };
            txnRequest = yield client.generateTransaction(bob.address(), create_mint_script1);
            bcsTxn = aptos_1.AptosClient.generateBCSTransaction(bob, txnRequest);
            transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
            console.log("Mint Successfull:  " + transactionRes.hash);
            client.waitForTransaction(transactionRes.hash);
        }
        const pause_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::resume_mint",
            type_arguments: [],
            arguments: [getresourceAccount['changes'][2]['address']]
        };
        txnRequest = yield client.generateTransaction(alice.address(), pause_payloads);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Pause mint: " + transactionRes.hash);
        yield client.waitForTransactionWithResult(transactionRes.hash);
        const resume_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::resume_mint",
            type_arguments: [],
            arguments: [getresourceAccount['changes'][2]['address']]
        };
        txnRequest = yield client.generateTransaction(alice.address(), resume_payloads);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Resume mint: " + transactionRes.hash);
        yield client.waitForTransactionWithResult(transactionRes.hash);
    }));
    it("Public Mint", () => __awaiter(void 0, void 0, void 0, function* () {
        const date = Math.floor(new Date().getTime() / 1000);
        const create_candy_machine = {
            type: "entry_function_payload",
            function: pid + "::candymachine::init_candy",
            type_arguments: [],
            arguments: [
                "Mokshya Test",
                "This is the description of test collection",
                "https://mokshya.io/nft/",
                alice.address(),
                "1000",
                "42",
                date - 20,
                date + 10,
                "1000",
                "2000",
                "10000",
                [true, true, true],
                [true, true, true, true, true],
                "" + makeid(5),
            ]
        };
        let txnRequest = yield client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: " + transactionRes.hash);
        let getresourceAccount = yield client.waitForTransactionWithResult(transactionRes.hash);
        console.log("Resource Address: " + getresourceAccount['changes'][2]['address']);
        const create_mint_script1 = {
            type: "entry_function_payload",
            function: pid + "::candymachine::mint_script",
            type_arguments: [],
            arguments: [
                getresourceAccount['changes'][2]['address']
            ],
        };
        txnRequest = yield client.generateTransaction(bob.address(), create_mint_script1);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(bob, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Mint Successfull:  " + transactionRes.hash);
        yield client.waitForTransaction(transactionRes.hash);
        const pause_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::resume_mint",
            type_arguments: [],
            arguments: [getresourceAccount['changes'][2]['address']]
        };
        txnRequest = yield client.generateTransaction(alice.address(), pause_payloads);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Pause mint: " + transactionRes.hash);
        yield client.waitForTransactionWithResult(transactionRes.hash);
        const resume_payloads = {
            type: "entry_function_payload",
            function: pid + "::candymachine::resume_mint",
            type_arguments: [],
            arguments: [getresourceAccount['changes'][2]['address']]
        };
        txnRequest = yield client.generateTransaction(alice.address(), resume_payloads);
        bcsTxn = aptos_1.AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = yield client.submitSignedBCSTransaction(bcsTxn);
        console.log("Resume mint: " + transactionRes.hash);
        yield client.waitForTransactionWithResult(transactionRes.hash);
    }));
});
//# sourceMappingURL=test.js.map