import { AptosClient, AptosAccount, FaucetClient} from "aptos";

const NODE_URL = "https://fullnode.devnet.aptoslabs.com";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);
var enc = new TextEncoder(); // always utf-8


const alice = new AptosAccount();
const bob = new AptosAccount();
const notwhitelist = new AptosAccount()


console.log("Alice Address: "+alice.address())
console.log("Bob Address: "+bob.address())

const pid ="0x4594ff393d29e60fb31b7f4ecba5f992364e35937b111f2d48bddf69f898f987"

function makeid(length) {
  var result           = '';
  var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxy';
  var charactersLength = characters.length;
  for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
  }
  return result;
}

describe("whitelist", () => {
    it("Whitelist Mint", async () => {
        await faucetClient.fundAccount(alice.address(), 1000000000);
        await faucetClient.fundAccount(bob.address(), 1000000000);
        const date = Math.floor(new Date().getTime() / 1000)
        const create_candy_machine = {
          type: "entry_function_payload",
          function: pid+"::candymachine::init_candy",
          type_arguments: [],
          arguments: [
            "Mokshya Test", // collection name
            "This is the description of test collection", // collection description
            "https://mokshya.io/nft/",  // collection uri 
            alice.address(),
            "1000",
            "42",
            date-20,
            date,
            "1000",
            "2000",
            "10000",
            [true,true,true],
            [true,true,true,true,true],
            ""+makeid(5),
        ]
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: "+transactionRes.hash)

        let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
        let addresses = []
        for (let i=0;i<1000;i++){
          addresses.push(bob.address())
        }
        const create_whitelist_payloads = {
          type: "entry_function_payload",
          function: pid+"::candymachine::create_whitelist",
          type_arguments: [],
          arguments: [getresourceAccount['changes'][2]['address'],addresses,""+makeid(5)],
        };
        console.log("Resource Address:"+getresourceAccount['changes'][2]['address'])
        txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
        bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Whitelist created: "+transactionRes.hash)

        const create_mint_script1 = {
          type: "entry_function_payload",
          function: pid+"::candymachine::mint_script",
          type_arguments: [],
          arguments: [
            getresourceAccount['changes'][2]['address']
          ],
        };
      txnRequest = await client.generateTransaction(bob.address(), create_mint_script1);
      bcsTxn = AptosClient.generateBCSTransaction(bob, txnRequest);
      transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
      console.log("Mint Successfull:  "+transactionRes.hash)
      await client.waitForTransaction(transactionRes.hash);
      
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
      it("Public Mint", async () => {
        const date = Math.floor(new Date().getTime() / 1000)
        const create_candy_machine = {
          type: "entry_function_payload",
          function: pid+"::candymachine::init_candy",
          type_arguments: [],
          arguments: [
            "Mokshya Test", // collection name
            "This is the description of test collection", // collection description
            "https://mokshya.io/nft/",  // collection uri 
            alice.address(),
            "1000",
            "42",
            date-20,
            date+10,
            "1000",
            "2000",
            "10000",
            [true,true,true],
            [true,true,true,true,true],
            ""+makeid(5),
        ]
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: "+transactionRes.hash)

        let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
        console.log("Resource Address:"+getresourceAccount['changes'][2]['address'])

        const create_mint_script1 = {
          type: "entry_function_payload",
          function: pid+"::candymachine::mint_script",
          type_arguments: [],
          arguments: [
            getresourceAccount['changes'][2]['address']
          ],
        };
      txnRequest = await client.generateTransaction(bob.address(), create_mint_script1);
      bcsTxn = AptosClient.generateBCSTransaction(bob, txnRequest);
      transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
      console.log("Mint Successfull:  "+transactionRes.hash)
      await client.waitForTransaction(transactionRes.hash);
      
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
  })