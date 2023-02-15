import { HexString,AptosClient, AptosAccount, FaucetClient,BCS} from "aptos";
import invariant from 'tiny-invariant';
import keccak256 from "keccak256";
import MerkleTree from "merkletreejs";
import { u64 } from "@saberhq/token-utils";

const NODE_URL = "https://aptos-testnet.nodereal.io/v1/81ccb0d76e66433abaf7543d0ff16688/v1";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);
var enc = new TextEncoder(); // always utf-8147e4d3a5b10eaed2a93536e284c23096dfcea9ac61f0a8420e5d01fbd8f0ea80100000000000000

// [debug] 0x147e4d3a5b10eaed2a93536e284c23096dfcea9ac61f0a8420e5d01fbd8f0ea8
// [debug] 0x0100000000000000
// [debug] 0x20147e4d3a5b10eaed2a93536e284c23096dfcea9ac61f0a8420e5d01fbd8f0ea80100000000000000
// [debug] 0x09e5b358aff3346f3d37460102e048dfef6e37603a2fdd34594786554e34af76

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

const pid ="0x7134042079eb2e356b0e254cfbc943de6ccc3bb15ee4dcc01c64d1274409709c"

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
  console.log( to_buf(alice.address().toUint8Array(),1).toString("hex"))
  let whitelistAddresses = [
    to_buf(alice.address().toUint8Array(),1),
    to_buf(notwhitelist.address().toUint8Array(),2),
  ];
  let leafNodes = whitelistAddresses.map((address) => keccak256(address));
  //0xc2ceb2d25df40acafc289fb268a8df82b75a2a9b929c5c0699f12809e468b064
  let rt;
  if (leafNodes[0] <= leafNodes[1])
  {
    rt = keccak256(Buffer.concat([leafNodes[0],leafNodes[1]]));
  }
  else
  {
     rt = keccak256(Buffer.concat([leafNodes[1],leafNodes[0]]));
  }
  console.log("Root : ")
  console.log(rt)
  let tree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });
  console.log(tree.getRoot().toString("hex"))
  it("Whitelist Mint", async () => {
      // let x = new u64(1).toArrayLike(Buffer, "le", 8);
      // console.log(whitelistAddresses[0].toString("hex"));
      //console.log(keccak256(whitelistAddresses[0]))
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
            date+11,
            "1000",
            "2000",
            "100",
            [false,false,false],
            [false,false,false,false,false],
            0,
            tree.getRoot(),
            ""+makeid(5),
        ]
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: "+transactionRes.hash)

        let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
        let addresses = []
      // for (let i=0;i<900;i++){
          addresses.push((new AptosAccount()).address())
      // }
      //   const create_whitelist_payloads = {
      //     type: "entry_function_payload",
      //     function: pid+"::candymachine::create_whitelist",
      //     type_arguments: [],
      //     arguments: [getresourceAccount['changes'][2]['address'],addresses,1],
      //   };
      //   console.log("Resource Address: "+getresourceAccount['changes'][2]['address'])
      //   txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
      //   let bcsTxns = await client.signTransaction(alice, txnRequest);
      //   transactionRes = await client.submitTransaction(bcsTxns);
      //   console.log("Whitelist created: "+transactionRes.hash)
      // await delay(15000)
        const proofs = [];
        const proof = tree.getProof((keccak256(whitelistAddresses[0])));
        console.log("proof")
        console.log(proof)
        let not_whitelist= keccak256(whitelistAddresses[1]);
       // 0x50130b2cf86b99972623f93b979ccfda73494b3bc61128b25c88d734d5547cda
        console.log(not_whitelist.toString("hex"))
         proof.forEach((p) => {
           proofs.push(p.data);
         });

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
        

    const pause_payloads = {
        type: "entry_function_payload",
        function: pid+"::candymachine::resume_mint",
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
    //   it("Public Mint", async () => {
    //     const date = Math.floor(new Date().getTime() / 1000)
    //     const create_candy_machine = {
    //       type: "entry_function_payload",
    //       function: pid+"::candymachine::init_candy",
    //       type_arguments: [],
    //       arguments: [
    //         "Mokshya Test", // collection name
    //         "This is the description of test collection", // collection description
    //         "https://mokshya.io/nft/",  // collection uri 
    //         alice.address(),
    //         "1000",
    //         "42",
    //         date+10,
    //         date+20,
    //         "1000",
    //         "2000",
    //         "10000",
    //         [true,true,true],
    //         [true,true,true,true,true],
    //         0,
    //         ""+makeid(5),
    //     ]
    //     };
    //     let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
    //     let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    //     let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    //     console.log("Candy Machine created: "+transactionRes.hash)

    //     let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
    //     console.log("Resource Address: "+getresourceAccount['changes'][2]['address'])

    //     await delay(15000)

    //     const create_mint_script1 = {
    //       type: "entry_function_payload",
    //       function: pid+"::candymachine::mint_script",
    //       type_arguments: [],
    //       arguments: [
    //         getresourceAccount['changes'][2]['address']
    //       ],
    //     };
    //   txnRequest = await client.generateTransaction(bob.address(), create_mint_script1);
    //   bcsTxn = AptosClient.generateBCSTransaction(bob, txnRequest);
    //   transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    //   console.log("Mint Successfull:  "+transactionRes.hash)
    //   await client.waitForTransaction(transactionRes.hash);
    //   await delay(5000)
    //   const pause_payloads = {
    //     type: "entry_function_payload",
    //     function: pid+"::candymachine::resume_mint",
    //     type_arguments: [],
    //     arguments: [getresourceAccount['changes'][2]['address']]
    //   }
    //   txnRequest = await client.generateTransaction(alice.address(), pause_payloads);
    //   bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    //   transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    //   console.log("Pause mint: "+transactionRes.hash)
    //   await client.waitForTransactionWithResult(transactionRes.hash);
    //   await delay(5000)
    //   const resume_payloads = {
    //     type: "entry_function_payload",
    //     function: pid+"::candymachine::resume_mint",
    //     type_arguments: [],
    //     arguments: [getresourceAccount['changes'][2]['address']]
    //   }
    //   txnRequest = await client.generateTransaction(alice.address(), resume_payloads);
    //   bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
    //   transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
    //   console.log("Resume mint: "+transactionRes.hash)
    //   await client.waitForTransactionWithResult(transactionRes.hash);
    // })
  })