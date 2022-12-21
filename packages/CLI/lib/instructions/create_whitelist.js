"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.create_whitelist = void 0;
async function create_whitelist(alice, fileStream, client, makeid, AptosClient) {
    for (let i = 0; i < fileStream['whitelist'].length; i += 1000) {
        const create_whitelist_payloads = {
            type: "entry_function_payload",
            function: "0x589db8bafed425239e1671313cabc182d23d2f952c1a512a0af81eae0085e293::candymachine::create_whitelist",
            type_arguments: [],
            arguments: [fileStream['resource_account'], fileStream['whitelist'].slice(i, i + 1000), "" + makeid(5)],
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        let check_txn = await client.waitForTransactionWithResult(transactionRes.hash);
        if (check_txn['success']) {
            console.log('Whitelist Created - Transaction Hash: ' + transactionRes.hash);
        }
    }
}
exports.create_whitelist = create_whitelist;
//# sourceMappingURL=create_whitelist.js.map