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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.create_candy = void 0;
const fs = __importStar(require("fs"));
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
async function create_candy(alice, fileStream, client, makeid, AptosClient) {
    let token_mutable = [false, false, false, false, false];
    let collection_mutable = [false, false, false];
    if (fileStream["mutable"]) {
        token_mutable = [true, true, true, true, true,];
        collection_mutable = [true, true, true,];
    }
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
    const create_candy_machine = {
        type: "entry_function_payload",
        function: "0x8035a63a18798115679466eef240aca66364707044f0ac7484e4c462c8310ae9::candymachine::init_candy",
        type_arguments: [],
        arguments: [
            fileStream['collection_name'],
            fileStream['collection_description'],
            fileStream['baseuri'],
            fileStream["royalty_payee_address"],
            fileStream["royalty_points_denominator"],
            fileStream["royalty_points_numerator"],
            fileStream["presale_mint_time"],
            fileStream["public_sale_mint_time"],
            fileStream["presale_mint_price"],
            fileStream["public_sale_mint_price"],
            fileStream["total_supply"],
            collection_mutable,
            token_mutable,
            fileStream["public_mint_limit"],
            tree.getRoot(),
            "" + makeid(5),
        ]
    };
    let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
    let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    let check_txn = await client.waitForTransactionWithResult(transactionRes.hash);
    if (check_txn['success']) {
        fileStream['resource_account'] = check_txn['changes'][2]['address'];
        console.log('Candy Machine Created - Transaction Hash: ' + transactionRes.hash);
        let argIndex = process.argv.indexOf('--config');
        fs.writeFileSync(process.argv[argIndex + 1], JSON.stringify(fileStream));
    }
    return transactionRes.hash;
}
exports.create_candy = create_candy;
//# sourceMappingURL=create_candy.js.map