import { HexString,AptosClient, AptosAccount, FaucetClient} from "aptos";

const NODE_URL = "https://aptos-testnet.nodereal.io/v1/81ccb0d76e66433abaf7543d0ff16688/v1";
const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);
const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);
var enc = new TextEncoder(); // always utf-8


// This private key is only for test purpose do not use this in mainnet
const alice = new AptosAccount(HexString.ensure("0x1111111111111111111111111111111111111111111111111111111111111111").toUint8Array());
;
// This private key is only for test purpose do not use this in mainnet
const bob = new AptosAccount(HexString.ensure("0x2111111111111111111111111111111111111111111111111111111111111111").toUint8Array());
const notwhitelist = new AptosAccount()


console.log("Alice Address: "+alice.address())
console.log("Bob Address: "+bob.address())

const pid ="0xe691833c29f78f86cdda4b04d3a254d585ecbed81e759b1fac47b380caa08886"

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
    it("Whitelist Mint", async () => {
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
        const create_whitelist_payloads = {
          type: "entry_function_payload",
          function: pid+"::candymachine::create_whitelist",
          type_arguments: [],
          arguments: [getresourceAccount['changes'][2]['address'],addresses,1],
        };
        console.log("Resource Address: "+getresourceAccount['changes'][2]['address'])
        txnRequest = await client.generateTransaction(alice.address(), create_whitelist_payloads);
        let bcsTxns = await client.signTransaction(alice, txnRequest);
        transactionRes = await client.submitTransaction(bcsTxns);
        console.log("Whitelist created: "+transactionRes.hash)

        await delay(15000)
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
            date+10,
            date+20,
            "1000",
            "2000",
            "10000",
            [true,true,true],
            [true,true,true,true,true],
            0,
            ""+makeid(5),
        ]
        };
        let txnRequest = await client.generateTransaction(alice.address(), create_candy_machine);
        let bcsTxn = AptosClient.generateBCSTransaction(alice, txnRequest);
        let transactionRes = await client.submitSignedBCSTransaction(bcsTxn);
        console.log("Candy Machine created: "+transactionRes.hash)

        let getresourceAccount = await client.waitForTransactionWithResult(transactionRes.hash);
        console.log("Resource Address: "+getresourceAccount['changes'][2]['address'])

        await delay(15000)

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
      await delay(5000)
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
      await delay(5000)
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