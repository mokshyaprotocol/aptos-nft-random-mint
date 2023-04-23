import { HexString,AptosClient, AptosAccount, FaucetClient,TxnBuilderTypes,BCS} from "aptos";
const {
  AccountAddress,
  TypeTagStruct,
  EntryFunction,
  StructTag,
  TransactionPayloadEntryFunction,
  RawTransaction,
  ChainId,
} = TxnBuilderTypes;

import invariant from 'tiny-invariant';
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import { u64 } from "@saberhq/token-utils";

const NODE_URL = "https://aptos-testnet.nodereal.io/v1/81ccb0d76e66433abaf7543d0ff16688/v1";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);
var enc = new TextEncoder(); 

// This private key is only for test purpose do not use this in mainnet
const alice = new AptosAccount(HexString.ensure("0x1111111111111111111111111111111111111111111111111111111111111111").toUint8Array());
;
// This private key is only for test purpose do not use this in mainnet
const bob = new AptosAccount(HexString.ensure("0x2111111111111111111111111111111111111111111111111111111111111111").toUint8Array());
const notwhitelist = new AptosAccount()

const to_buf = (account:Uint8Array,amount:number): Buffer=>{ 
  return Buffer.concat([
    account,
    new u64(amount).toArrayLike(Buffer, "le", 8),
  ]);
}

console.log("Alice Address: "+alice.address())
console.log("Bob Address: "+bob.address())

const pid ="0xe94aca46d6cf84e2c248b6e4b75a375af5b489064aa6f6f85c737fee4ccc3ff4"

function makeid(length) {
  var result           = '';
  var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxy';
  var charactersLength = characters.length;
  for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
}
const delay = (delayInms) => {
  return new Promise(resolve => setTimeout(resolve, delayInms));
}

describe("whitelist", () => {
  let whitelistAddresses = [
    to_buf(notwhitelist.address().toUint8Array(),2),
  ];
  for(let i=0;i<200;i++){
    whitelistAddresses.push(to_buf(new AptosAccount().address().toUint8Array(),1))
  }
  whitelistAddresses.push(to_buf(alice.address().toUint8Array(),1))
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
  it("Merkle Mint", async () => {
        const date = Math.floor(new Date().getTime() / 1000)
        const create_candy_machine = {
          type: "entry_function_payload",
          function: pid+"::candymachine::init_candy",
          type_arguments: [],
          arguments: [
            "Mokshya", // collection name
            "This is the description of test collection", // collection description
            "https://mokshya.io/nft/",  // collection 
            alice.address(),
            "1000",
            "42",
            date+10,
            date+100,
            "1",
            "1",
            "2000",
            [false,false,false],
            [false,false,false,false,false],
            0,
            ""+makeid(5),
        ]
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: "+transactionRes.hash)
        let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
        await delay(15000)
        const proofs = [];
        const proof = tree.getProof((keccak256(whitelistAddresses[(whitelistAddresses.length)-1])));
        let not_whitelist= keccak256(whitelistAddresses[1]);
       // 0x50130b2cf86b99972623f93b979ccfda73494b3bc61128b25c88d734d5547cda
         proof.forEach((p) => {
           proofs.push(p.data);
         });
         const create_mint_script3 = {
          type: "entry_function_payload",
          function: pid+"::candymachine::set_root",
          type_arguments: [],
          arguments: [
            getresourceAccount['changes'][2]['address'],
            tree.getRoot()
          ],
        };
      txnRequest = await client.generateTransaction(alice.address(), create_mint_script3);
      bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
      transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
      console.log("merkle root Successfull:  "+transactionRes.hash)
      client.waitForTransaction(transactionRes.hash);
      await delay(10000)

        const create_mint_script1 = {
          type: "entry_function_payload",
          function: pid+"::candymachine::mint_from_merkle",
          type_arguments: [],
          arguments: [
            getresourceAccount['changes'][2]['address'],
            proofs,
            BigInt(1)
          ],
        };
      txnRequest = await client.generateTransaction(alice.address(), create_mint_script1);
      bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
      transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
      console.log("Mint Successfull:  "+transactionRes.hash)
      client.waitForTransaction(transactionRes.hash);
      await delay(150000)
      
      const create_mint_script2 = {
        type: "entry_function_payload",
        function: pid+"::candymachine::mint_script",
        type_arguments: [],
        arguments: [
          getresourceAccount['changes'][2]['address'],
          // proofs,
          // BigInt(1)
        ],
      };
    txnRequest = await client.generateTransaction(alice.address(), create_mint_script2);
    bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    console.log("Mint Successfull:  "+transactionRes.hash)
    client.waitForTransaction(transactionRes.hash);

    const pause_payloads = {
        type: "entry_function_payload",
        function: pid+"::candymachine::pause_mint",
        type_arguments: [],
        arguments: [getresourceAccount['changes'][2]['address']]
      }
      txnRequest = await client.generateTransaction(alice.address(), pause_payloads);
      bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
      transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
      console.log("Pause mint: "+transactionRes.hash)
      await client.waitForTransactionWithResult(transactionRes.hash);

      const resume_payloads = {
          type: "entry_function_payload",
          function: pid+"::candymachine::resume_mint",
          type_arguments: [],
          arguments: [getresourceAccount['changes'][2]['address']]
        }
        txnRequest = await client.generateTransaction(alice.address(), resume_payloads);
        bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Resume mint: "+transactionRes.hash)
        await client.waitForTransactionWithResult(transactionRes.hash);
      })
    })