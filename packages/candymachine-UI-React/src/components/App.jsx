import React, { useState, useEffect } from "react";
import "./App.css";
import { Mint } from "./Mint/Mint";
import HourglassBottomIcon from "@mui/icons-material/HourglassBottom";
import { Wallet } from "./Wallet/Wallet";
import { AptosClient } from "aptos";
import { Timer } from "./Timer/Timer";
import { ToastContainer, toast } from "react-toastify";
import axios from "axios";
import "react-toastify/dist/ReactToastify.css";

export default function App() {
  const [wallet, setWallet] = useState("");
  const [walletType, setWalletType] = useState(null);
  const [walletConnected, setWalletConnected] = useState(false);
  const [publicKey, setPublicKey] = useState(null);
  const [candyMachine, setCandyMachine] = useState(null);
  const [whitelist, setWhitelist] = useState([]);
  const [sold, setSold] = useState(false);
  const [mintStart, setMintStart] = useState(false);

  const [mintInfo, setMintInfo] = useState({
    minted: 0,
    supply: 20000,
    power: 0,
  });

  const [info, setInfo] = useState({
    presale_mint_price: 1,
    presale_mint_time: 1668142066,
    public_sale_mint_price: 1,
    public_sale_mint_time: 1668142066,
  });
  console.log("this is infooooooooo", info);

  useEffect(() => {
    if (candyMachine !== null) {
      checkMintStatus();
      setInfo({
        presale_mint_price: Number(candyMachine.presale_mint_price),
        presale_mint_time: Number(candyMachine.presale_mint_time),
        public_sale_mint_price: Number(candyMachine.public_sale_mint_price),
        public_sale_mint_time: Number(candyMachine.public_sale_mint_time),
      });
    }
  }, [candyMachine]);
  useEffect(() => {
    if (!mintStart && Date.now() > info.presale_mint_time) {
      setMintStart(true);
    }
  }, [candyMachine]);

  // console.log("walletConnected", walletConnected);
  // console.log("walletType", walletType);

  let toDisplay;
  if (walletConnected) {
    toDisplay = <Mint mintStart={mintStart} mint={mint} />;
  } else {
    toDisplay = (
      <Wallet
        setWalletConnected={setWalletConnected}
        setWalletAddress={setWallet}
        setWalletType={setWalletType}
        walletType={walletType}
        setPublicKey={setPublicKey}
      />
    );
  }
  const client = new AptosClient(process.env.REACT_APP_NODE_URL);
  async function checkBalance() {
    try {
      let lamports = null;
      lamports = await window.martian.getAccountResources(
        wallet,
        "0x1::AptosAccount::Coin"
      );
      let balance = lamports[0].data.coin.value / 100000000;

      return balance.toFixed(4);
    } catch (e) {
      return 0;
    }
  }
  setInterval(checkCandymachine, 5000);
  async function checkCandymachine() {
    try {
      let candys = await client.getAccountResources(
        process.env.REACT_APP_RESOURCE_ACCOUNT
      );
      // for (var x = 0; x < candys.length; x++) {
      //   if (
      //     candys[x].type ==
      //     process.env.REACT_APP_CANDY_MACHINE_ID +
      //       "::candymachine::CandyMachine"
      //   ) {
      //     let whitelist = candys[x].data.whitelist;

      //     if (candyMachine == null) {
      //       for (var y = 0; y < whitelist.length; y++) {
      //         let white = await client.getAccountResources(whitelist[y]);
      //         setWhitelist(white[1].data.whitelist);
      //       }
      //     }
      //     setCandyMachine(candys[x].data);
      //   }
      // }
      if (
        candys[2].type ==
        process.env.REACT_APP_CANDY_MACHINE_ID + "::candymachine::CandyMachine"
      ) {
        let candyMachineData = candys[2].data;
        setCandyMachine(candyMachineData);
        setWhitelist(candys[2].data.whitelist);
      }

      console.log("candymachine::::", candyMachine);
    } catch (e) {
      console.log(e);
    }
  }
  function checkMintStatus() {
    if (parseInt(mintInfo.minted) == 10000) {
      setSold(true);
    }
    const power = (
      (parseInt(mintInfo.minted) / parseInt(mintInfo.supply)) *
      100
    ).toFixed(2);
    setMintInfo({
      minted: candyMachine.minted,
      supply: candyMachine.total_supply,
      power: power,
    });
    // this.mintLoaded = true;
  }
  async function mint() {
    if (wallet && walletType) {
      let blncRequired = 0;
      let blnc = 0;
      let repeat = 0;
      blnc = await checkBalance();
      while (repeat < 5 && blnc == 0) {
        blnc = await checkBalance();
        repeat++;
      }
      repeat = 0;
      if (wallet) {
        if (whitelist.includes(wallet)) {
          blncRequired = process.env.REACT_APP_WHITELIST_MINT_PRICE;
        } else {
          blncRequired = process.env.REACT_APP_PUBLIC_MINT_PRICE;
        }
      }
      try {
        // this.minting = true;
        console.log(
          process.env.REACT_APP_CANDY_MACHINE_ID + "::candymachine::mint_script"
        );

        const create_mint_script = {
          type: "entry_function_payload",
          function:
            process.env.REACT_APP_CANDY_MACHINE_ID +
            "::candymachine::mint_script",
          type_arguments: [],

          arguments: [process.env.REACT_APP_RESOURCE_ACCOUNT],
        };

        let txnHash = null;
        if (walletType == "Martian") {
          const transaction = await window.martian.generateTransaction(
            wallet,
            create_mint_script
          );

          const signedTxn = await window.martian.signTransaction(transaction);

          txnHash = await window.martian.submitTransaction(signedTxn);
        } else if (walletType == "Petra") {
          txnHash = await window.aptos.signAndSubmitTransaction(
            create_mint_script
          );
        }

        verifyTransaction(txnHash.hash);
      } catch (e) {
        // this.minting = false;

        if (walletType == "Martian") {
          if (e == "User Rejected the request") {
            toast.error("Connection refused.");
            console.error("connection refused.");
          } else {
            toast.error("Mint failed!");
            console.error("Mint failed.");
          }
        } else {
          toast.error("Connection refused.");
          console.error("Connection refused");
        }
      }
    } else {
      toast.info("Connect wallet.");
      console.error("connect wallet.");
    }
  }

  function verifyTransaction(hash) {
    axios
      .get(
        `https://fullnode.testnet.aptoslabs.com/v1/transactions/by_hash/${hash}`
      )
      .then((res) => {
        if (res.data.success == true) {
          toast.success("Mint successful!");
        } else if (res.data.success == false) {
          alert("Mint failed.");
          toast.error("Mint failed!");
        } else {
          verifyTransaction(hash);
        }
        // this.minting = false;
      })
      .catch((err) => {
        verifyTransaction(hash);
      });
  }
  return (
    <div className="App">
      <header className="App-header">
        <div className="mint-container">
          <p>Whitelist Mint Price : {info.presale_mint_price} APT</p>
          <HourglassBottomIcon />
          <div className="progress-bar">
            <p>
              {mintInfo.power}% {mintInfo.minted}/{mintInfo.supply}
            </p>
          </div>
          <p>Whitelist Mint is starting in</p>
          <Timer countDownDate={info.presale_mint_time} />
          <br />
          <hr />
          <br />
          <p>Public Mint Price : {info.public_sale_mint_price} APT</p>
          <p>Public Mint is starting in</p>
          <Timer countDownDate={info.public_sale_mint_time} />
        </div>
        {toDisplay}
        <ToastContainer
          theme="colored"
          closeOnClick
          hideProgressBar
          position="bottom-right"
          autoClose={2000}
          draggablePercent={60}
        />
      </header>
    </div>
  );
}
