
export const state = () => ({
  walletAddr: null,
  profile: null,
  secret: null,
  publicKey: null,
  disabled: false,
  resource: null,
  walletType: null,
  choose: false,
  mintStart: false,
  candyMachine: null,
  whitelist: [],
});

export const mutations = {
  setCandyMachine(state, payload) {
    state.candyMachine = payload;
  },
  mintStart(state, payload) {
    state.mintStart = payload;
  },
  chooseWallet(state, payload) {
    state.choose = payload;
  },
  selectWalletType(state, payload) {
    state.walletType = payload;
    state.choose = false;
  },
  setResource(state, payload) {
    state.resource = payload;
  },
  setWallet(state, payload) {
    state.walletAddr = payload;
  },
  setDisabled(state, payload) {
    state.disabled = payload;
  },
  setProfile(state, payload) {
    state.profile = payload;
  },
  setmintSecret(state, payload) {
    state.secret = payload;
  },
  setPublicKey(state, payload) {
    state.publicKey = payload;
  },
  setWhitelistFromCandy(state, payload) {
    state.whitelist = state.whitelist.concat(payload);
  },
};

export const actions = {
  async checkBalance(context) {
    try {
      let lamports = null;
      lamports = await window.martian.getAccountResources(
        context.state.walletAddr,
        "0x1::AptosAccount::Coin"
      );
      let balance = lamports[0].data.coin.value / 100000000;

      return balance.toFixed(4);
    } catch (e) {
      return 0;
    }
  },

  async checkCandymachine(context) {
    let whitesetup=false
    try {
      let candys = null;
      candys = await window.martian.getAccountResources(
        process.env.RESOURCE_ACCOUNT,
        process.env.CANDY_MACHINE_ID + "::candymachine::CandyMachine"
      );
      for (var x = 0; x < candys.length; x++) {
        if (
          candys[x].type ==
          process.env.CANDY_MACHINE_ID + "::candymachine::CandyMachine"
        ) {

          let whitelist = candys[x].data.whitelist;

          if (context.state.candyMachine == null) {
            for (var y = 0; y < whitelist.length; y++) {
              let white = await window.martian.getAccountResources(
                whitelist[y],
                process.env.CANDY_MACHINE_ID + "::candymachine::CandyMachine"
              );
              context.commit("setWhitelistFromCandy", white[1].data.whitelist);
            }
          }
          context.commit("setCandyMachine", candys[x].data);

        }
      }
    } catch (e) {
      console.log(e);
    }
  },

  async connectWallet(context) {
    if (context.state.walletType != null) {
      if (context.state.walletType == "Martian") {
        if ("martian" in window) {
          try {
            await window.martian.connect();
            const network = await window.martian.network();
            if (network == process.env.NETWORK) {
              context.dispatch("login");
            } else {
              context.dispatch("logout");

              this.$toast
                .error("Please change network to " + process.env.NETWORK, {
                  iconPack: "mdi",
                  icon: "mdi-wallet",
                  theme: "outline",
                })
                .goAway(3000);
            }
          } catch (e) {
            context.dispatch("logout");
            this.$toast
              .error("Connection refused", {
                iconPack: "mdi",
                icon: "mdi-wallet",
                theme: "outline",
              })
              .goAway(3000);
          }
        } else {
          this.$toast
            .error("Please install martian wallet first.", {
              iconPack: "mdi",
              icon: "mdi-wallet",
              theme: "outline",
            })
            .goAway(3000);
        }
      } else if (context.state.walletType == "Petra") {
        if ("aptos" in window) {
          try {
            await window.aptos.connect();
            const network = await window.aptos.network();
            if (network == process.env.NETWORK) {
              context.dispatch("login");
            } else {
              context.dispatch("logout");

              this.$toast
                .error("Please change network to " + process.env.NETWORK, {
                  iconPack: "mdi",
                  icon: "mdi-wallet",
                  theme: "outline",
                })
                .goAway(3000);
            }
          } catch (e) {
            context.dispatch("logout");
            this.$toast
              .error("Connection refused", {
                iconPack: "mdi",
                icon: "mdi-wallet",
                theme: "outline",
              })
              .goAway(3000);
          }
        } else {
          this.$toast
            .error("Please install martian wallet first.", {
              iconPack: "mdi",
              icon: "mdi-wallet",
              theme: "outline",
            })
            .goAway(3000);
        }
      } else {
        context.commit("chooseWallet", true);
      }
    } else {
      context.commit("chooseWallet", true);
    }
  },

  async login(context) {
    try {
      let wallet = null;
      if (context.state.walletType == "Martian") {
        localStorage.setItem("apt-wallet-type", "Martian");
        wallet = await window.martian.connect();
      } else if (context.state.walletType == "Petra") {
        localStorage.setItem("apt-wallet-type", "Petra");
        wallet = await window.aptos.connect();
      } else {
        context.dispatch("logout");
        return;
      }

      context.commit("setPublicKey", wallet.address);
      context.commit("setWallet", wallet.address);
      context.commit("setDisabled", false);
      localStorage.setItem("apt-wallet", wallet.address);
    } catch (e) {
      context.dispatch("logout");
      this.$toast
        .error("Connection refused", {
          iconPack: "mdi",
          icon: "mdi-wallet",
          theme: "outline",
        })
        .goAway(3000);
    }
  },

  async logout(context) {
    if (context.state.walletType == "Martian") {
      window.martian.disconnect();
    } else if (context.state.walletType == "Petra") {
      window.aptos.disconnect();
    }
    localStorage.removeItem("apt-wallet");
    localStorage.removeItem("apt-wallet-type");
    context.commit("mintStart", false);
    context.commit("setWallet", null);
    context.commit("setProfile", null);
    context.commit("selectWalletType", null);
    context.commit("setDisabled", false);
  },
};
