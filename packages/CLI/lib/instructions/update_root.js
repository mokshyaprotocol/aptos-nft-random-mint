"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.update_root = void 0;
const token_utils_1 = require("@saberhq/token-utils");
const keccak256_1 = __importDefault(require("keccak256"));
const merkletreejs_1 = __importDefault(require("merkletreejs"));
const aptos_1 = require("aptos");
const to_buf = (account, amount) => {
    return Buffer.concat([
        account,
        new token_utils_1.u64(amount).toArrayLike(Buffer, "le", 8),
    ]);
};
async function update_root(alice, fileStream, client, makeid, AptosClient) {
    let whitelistAddresses = [];
    for (let i = 0; i < fileStream['whitelist'].length; i++) {
        whitelistAddresses.push(to_buf(aptos_1.HexString.ensure(fileStream['whitelist'][i][0]).toUint8Array(), fileStream['whitelist'][i][1]));
    }
    let leafNodes = whitelistAddresses.map((address) => (0, keccak256_1.default)(address));
    let rt;
    if (leafNodes[0] <= leafNodes[1]) {
        rt = (0, keccak256_1.default)(Buffer.concat([leafNodes[0], leafNodes[1]]));
    }
    else {
        rt = (0, keccak256_1.default)(Buffer.concat([leafNodes[1], leafNodes[0]]));
    }
    let tree = new merkletreejs_1.default(leafNodes, keccak256_1.default, { sortPairs: true });
    const create_whitelist_payloads = {
        type: "entry_function_payload",
        function: "0x8035a63a18798115679466eef240aca66364707044f0ac7484e4c462c8310ae9::candymachine::set_root",
        type_arguments: [],
        arguments: [fileStream['resource_account'], tree.getRoot()],
    };
    let txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
    let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    let check_txn = await client.waitForTransactionWithResult(transactionRes.hash);
    if (check_txn['success']) {
        console.log('Whitelist Created - Transaction Hash: ' + transactionRes.hash);
    }
}
exports.update_root = update_root;
//# sourceMappingURL=update_root.js.map