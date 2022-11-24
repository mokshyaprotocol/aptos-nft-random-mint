import { Button, Dialog, List, ListItem } from "@mui/material";
import React from "react";
import { useState } from "react";
import "./Wallet.css";

export const Wallet = ({
  setWalletConnected,
  setWalletAddress,
  setWalletType,
  walletType,
  setPublicKey,
}) => {
  const [profile, setProfile] = useState(null);
  const [disabled, setDisabled] = useState(false);
  const [flipStart, setFlipStart] = useState(false);
  const [open, setOpen] = useState(false);
  function handleClickOpen() {
    setOpen(true);
  }
  function handleClose() {
    setOpen(false);
  }

  async function connectPetra() {
    setWalletType("Petra");
    if ("aptos" in window) {
      try {
        const wallet = await window.aptos.connect();
        const network = await window.aptos.network();
        if (network === process.env.REACT_APP_NETWORK) {
          console.log(network);
          setWalletAddress(wallet.address);
          setWalletConnected(true);

          // login();
        } else {
          logout();

          console.error(
            "Please change network to " + process.env.REACT_APP_NETWORK
          );
        }
      } catch (error) {
        logout();
      }
    } else {
      console.error("Install petra wallet");
    }
  }

  async function connectMartian() {
    setWalletType("Martian");
    if ("martian" in window) {
      try {
        const wallet = await window.martian.connect();
        const network = await window.martian.network();
        console.log(network);
        if (network === process.env.REACT_APP_NETWORK) {
          setWalletAddress(wallet.address);
          setWalletConnected(true);
          // login();
        } else {
          logout();
          console.log("throw error");
        }
      } catch (error) {
        logout();
        console.log(" :: error");
      }
    } else {
      console.log("Install martian wallet");
    }
  }
  async function login() {
    try {
      let wallet = null;
      console.log("wallettype in login", walletType);
      if (walletType === "Martian") {
        // localStorage.setItem("apt-wallet-type", "Martian");
        wallet = await window.martian.connect();
      } else if (walletType === "Petra") {
        // localStorage.setItem("apt-wallet-type", "Petra");
        wallet = await window.aptos.connect();
      } else {
        console.log("elseeee");
        logout();
        return;
      }
      // context.commit("setPublicKey", wallet.address);
      // context.commit("setWallet", wallet.address);
      // context.commit("setDisabled", false);
      // localStorage.setItem("apt-wallet", wallet.address);
      setPublicKey(wallet.address);
      setWalletAddress(wallet.address);
      setDisabled(false);
    } catch (error) {
      // context.dispatch("logout");
      // this.$toast
      //   .error("Connection refused", {
      //     iconPack: "mdi",
      //     icon: "mdi-wallet",
      //     theme: "outline",
      //   })
      //   .goAway(3000);
      logout();
      console.log(error);
    }
  }
  async function logout() {
    if (walletType === "Martian") {
      window.martian.disconnect();
    } else if (walletType === "Petra") {
      window.aptos.disconnect();
    }
    setFlipStart(false);
    setWalletAddress(null);
    setProfile(null);
    setWalletType(null);
    setDisabled(false);
  }
  return (
    //connectwallet funcn on button
    <section className="connect-wallet-container">
      <div className="connect-wallet">
        <Button variant="contained" onClick={handleClickOpen}>
          CONNECT WALLET
        </Button>
        <Dialog open={open} onClose={handleClose}>
          <List>
            <ListItem
              autoFocus
              button
              onClick={function () {
                connectPetra();
                handleClose();
              }}
            >
              Petra
            </ListItem>
            <ListItem
              sx={{ width: "100%" }}
              autoFocus
              button
              onClick={function () {
                connectMartian();
                handleClose();
              }}
            >
              Martian
            </ListItem>
          </List>
        </Dialog>
      </div>
      <span style={{ color: "red" }}>
        Please ensure you have enough balance
      </span>
    </section>
  );
};
