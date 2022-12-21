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
exports.create_candy = void 0;
const fs = __importStar(require("fs"));
async function create_candy(alice, fileStream, client, makeid, AptosClient) {
    let collection_mutable = [false, false, false, false, false];
    let token_mutable = [false, false, false];
    if (fileStream["mutable"]) {
        collection_mutable = [true, true, true, true, true,];
        token_mutable = [true, true, true,];
    }
    const create_candy_machine = {
        type: "entry_function_payload",
        function: "0x589db8bafed425239e1671313cabc182d23d2f952c1a512a0af81eae0085e293::candymachine::init_candy",
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
        console.log(argIndex);
        fs.writeFileSync(process.argv[argIndex + 1], JSON.stringify(fileStream));
    }
    return transactionRes.hash;
}
exports.create_candy = create_candy;
//# sourceMappingURL=create_candy.js.map