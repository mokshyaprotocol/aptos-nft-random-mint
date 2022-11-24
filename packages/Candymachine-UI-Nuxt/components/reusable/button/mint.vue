<template>
<div class="mint-btn" v-if="visible">
    <v-btn rounded class="mint-inside px-12 py-6" @click="mint()" :disabled="minting">
        {{ text }}
    </v-btn>
</div>
</template>

<script>
export default {
    data() {
        return {
            minting: false,
            blncRequired: 0,
            text: "MINT",
            visible: false,
        };
    },
    watch: {
        sold() {
            this.checkSold();
        },
    },
    computed: {
        walletType() {
            return this.$store.state.wallet.walletType;
        },
        walletAddr() {
            return this.$store.state.wallet.walletAddr;
        },
        candyMachine() {
            return this.$store.state.wallet.candyMachine;
        },
        sold() {
            return this.$store.state.mint.sold;
        },
        whitelisted() {
            return this.$store.state.mint.whitelisted
        }
    },
    mounted() {
        this.checkSold();
        let checkInterval = null;
        checkInterval = setInterval(() => {
            if (this.visible) {
                clearInterval(checkInterval);
            } else {
                this.checkMintEligibility();
            }
        }, 1000);
    },
    methods: {
        checkMintEligibility() {
            var whiteDate = process.env.WHITELIST_MINT_DATE;
            var publicDate = process.env.PUBLIC_MINT_DATE
            var now = new Date().getTime();
            if (this.whitelisted == true) {
                if (now > whiteDate) {
                    this.visible = true;
                } else {
                    this.visible = false
                }
            } else {
                if (now > publicDate) {
                    this.visible = true;
                } else {
                    this.visible = false
                }
            }
        },
        checkSold() {
            if (this.sold == true) {
                this.text = "SOLD out";
                this.minting = true;
                this.$store.commit("mint/setLiveFalse");
            }
        },
        async mint() {
            if (this.walletAddr && this.walletType) {
                let blncRequired = 0;
                let blnc = 0;
                let repeat = 0;
                blnc = await this.$store.dispatch("wallet/checkBalance");
                while (repeat < 5 && blnc == 0) {
                    blnc = await this.$store.dispatch("wallet/checkBalance");
                    repeat++;
                }
                repeat = 0;
                if (this.walletAddr) {
                    if (this.candyMachine.whitelist.includes(this.walletAddr)) {
                        blncRequired = process.env.WHITELIST_MINT_PRICE;
                    } else {
                        blncRequired = process.env.PUBLIC_MINT_PRICE;
                    }
                }
                try {
                    this.minting = true;
                    const create_mint_script = {
                        type: "entry_function_payload",
                        function: process.env.CANDY_MACHINE_ID + "::candymachine::mint_script",
                        type_arguments: [],

                        arguments: [process.env.RESOURCE_ACCOUNT],
                    };

                    let txnHash = null;
                    if (this.walletType == "Martian") {
                        const transaction = await window.martian.generateTransaction(
                            this.walletAddr,
                            create_mint_script
                        );

                        const signedTxn = await window.martian.signTransaction(transaction);

                        txnHash = await window.martian.submitTransaction(signedTxn);

                    } else if (this.walletType == "Petra") {
                        txnHash = await window.aptos.signAndSubmitTransaction(
                            create_mint_script
                        );
                    }

                    this.verifyTransaction(txnHash.hash)

                } catch (e) {
                    this.minting = false;

                    if (this.walletType == "Martian") {
                        if (e == "User Rejected the request") {
                            this.$toast
                                .error("Connection refused", {
                                    iconPack: "mdi",
                                    icon: "mdi-wallet",
                                    theme: "outline",
                                })
                                .goAway(3000);
                        } else {
                            this.$toast
                                .error("Mint failed.", {
                                    iconPack: "mdi",
                                    icon: "mdi-wallet",
                                    theme: "outline",
                                })
                                .goAway(3000);
                        }
                    } else {
                        this.$toast
                            .error("Connection refused", {
                                iconPack: "mdi",
                                icon: "mdi-wallet",
                                theme: "outline",
                            })
                            .goAway(3000);
                    }
                }
            } else {
                this.$store.dispatch("wallet/connectWallet");
            }
        },
        verifyTransaction(hash) {
            this.$axios.get(`https://fullnode.`+process.env.NETWORK.toLowerCase()+`.aptoslabs.com/v1/transactions/by_hash/${hash}`).then(res => {
                if (res.data.success == true) {
                    this.$toast
                        .success("Mint successful", {
                            iconPack: "mdi",
                            icon: "mdi-wallet",
                            theme: "outline",
                        })
                        .goAway(3000);
                } else if (res.data.success == false) {
                    this.$toast
                        .error("Mint Failed", {
                            iconPack: "mdi",
                            icon: "mdi-wallet",
                            theme: "outline",
                        })
                        .goAway(3000);
                } else {
                    this.verifyTransaction(hash)

                }
                this.minting = false;

            }).catch(err => {
                this.verifyTransaction(hash)
            })
        }
    },
};
</script>

<style>
.mint-inside {
    background: linear-gradient(180deg, #40454a 0%, #000000 100%),
        linear-gradient(228.52deg,
            #af1322 12.54%,
            #423c3d 38.9%,
            #242424 69.02%,
            #af1322 89.67%);
}

.mint-btn {
    display: inline-block;
    padding: 4px;
    border: 4px;
    background: linear-gradient(180deg, #5A41FF 0.9%, rgba(58, 141, 255, 0.84) 100%);
    box-shadow: 0px 5px 0px 1px #0000004d;
    border-radius: 86px;
}
</style>
