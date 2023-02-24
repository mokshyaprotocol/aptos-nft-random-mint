import { u64 } from "@saberhq/token-utils";
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import {HexString} from "aptos";

const to_buf = (account:Uint8Array,amount:number): Buffer=>{ 
    return Buffer.concat([
      account,
      new u64(amount).toArrayLike(Buffer, "le", 8),
    ]);
  }
  
export async function update_root(alice,fileStream,client,makeid,AptosClient) {
    let whitelistAddresses = [];
    for(let i=0;i<fileStream['whitelist'].length;i++){
      whitelistAddresses.push(to_buf(HexString.ensure(fileStream['whitelist'][i][0]).toUint8Array(),fileStream['whitelist'][i][1]))
    }
    let leafNodes = whitelistAddresses.map((address) => keccak256(address));
    let rt;
    if (leafNodes[0] <= leafNodes[1])
    {
      rt = keccak256(Buffer.concat([leafNodes[0],leafNodes[1]]));
    }
    else
    {
       rt = keccak256(Buffer.concat([leafNodes[1],leafNodes[0]]));
    }
    let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
    const create_whitelist_payloads = {
        type: "entry_function_payload",
        function: "0x8035a63a18798115679466eef240aca66364707044f0ac7484e4c462c8310ae9::candymachine::set_root",
        type_arguments: [],
        arguments: [fileStream['resource_account'],tree.getRoot()],
    };
    let txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
    let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    let check_txn = await client.waitForTransactionWithResult(transactionRes.hash);
    if (check_txn['success']){
        console.log('Whitelist Created - Transaction Hash: ' + transactionRes.hash)
    }
}