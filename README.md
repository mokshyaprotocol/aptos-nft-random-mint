Candy machine smart contract for Aptos Blockchain.

# Deploy contract

```
aptos init
```
```
 aptos move publish --named-addresses candymachine=your_address
```
copy the account address
```javascript
import {AptosClient, AptosAccount, FaucetClient, TxnBuilderTypes} from "aptos";

# Set up candy machine 

const NODE_URL = "https://fullnode.devnet.aptoslabs.com";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";
const alice = new AptosAccount()
await faucetClient.fundAccount(alice.address(), 1000000000);
const create_candy_machine = {
  type: "entry_function_payload",
  function: "0xdf5d131a5be0a5c8b795f4bb4c4f6a19b160b24eae6e269396acb69f1bf4c0a8::candymachine::set_up_candy",
  type_arguments: [],
  arguments: [
  collection_name,
  collection_description,
  "https://arweave.net/{data_tx_id}/",
  royalty_address,
  royalty_points_denominator,
  royalty_points_numerator,
  presale_time,
  public_time,
  presale_price,
  public_price,
  total_supply,
  collection_mutate_setting,
  token_mutate_setting,
  any_random_number,
  ]
   };
let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
console.log("Candy Machine created: "+transactionRes.hash)
```

# Create Whitelist
```javascript
const whitelist_list = [] //add all the addresses you want to whitelist.
const create_whitelist_payloads = {
  type: "entry_function_payload",
  function: pid+"::candymachine::create_whitelist",
  type_arguments: [],
  arguments: [getresourceAccount['changes'][2]['address'],whitelist_list,any_random_number],
};
txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
console.log("Whitelist created: "+transactionRes.hash)
```
# Mint NFT 
```javascript
const create_mint_script = {
 type: "entry_function_payload",
 function: pid+"::candymachine::mint_script",
 type_arguments: [],
 arguments: [
  getresourceAccount['changes'][2]['address'],
  1,
 ],
};
txnRequest = await client.generateTransaction(bob.address(), create_mint_script);
bcsTxn = AptosClient.generateBCSTransaction(bob, txnRequest);
transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
console.log("Mint Successfull: "+i+" "+transactionRes.hash)
await client.waitForTransaction(transactionRes.hash);
```
