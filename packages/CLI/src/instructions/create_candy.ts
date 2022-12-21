import * as fs from "fs"
export async function create_candy(alice,fileStream,client,makeid,AptosClient) {
    let collection_mutable = [false,false,false,false,false]
    let token_mutable = [false,false,false]
    if(fileStream["mutable"]){
      collection_mutable = [true,true,true,true,true,]
      token_mutable = [true,true,true,]
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
        ""+makeid(5),
    ]
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
