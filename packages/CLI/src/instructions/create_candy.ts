import * as fs from "fs"
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
export async function create_candy(alice,fileStream,client,makeid,AptosClient) {
    let token_mutable = [false,false,false,false,false]
    let collection_mutable = [false,false,false]
    if(fileStream["mutable"]){
      token_mutable = [true,true,true,true,true,]
      collection_mutable = [true,true,true,]
    }
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
        ""+makeid(5),]
    };
    let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
    let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    let check_txn = await client.waitForTransactionWithResult(transactionRes.hash);
    if (check_txn['success']){
        fileStream['resource_account']= check_txn['changes'][2]['address']
        console.log('Candy Machine Created - Transaction Hash: ' + transactionRes.hash)
        let argIndex = process.argv.indexOf('--config')
        fs.writeFileSync(process.argv[argIndex+1], JSON.stringify(fileStream));
    }
    return transactionRes.hash
  }
