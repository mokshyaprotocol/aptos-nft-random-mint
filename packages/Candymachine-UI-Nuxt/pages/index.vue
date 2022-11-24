<template>
<div>
    <client-only>
        <v-container style="margin-top:18%">
            <v-row justify="center">
                <v-col cols="12" lg="6" md="6" align="center">
                    <v-card class="outer-box mt-5">
                        <div class="main-box pa-5" style="position: relative">
                            <small v-if="live" style="position: absolute; top: 0; left: 0">
                                <v-row no-gutters>
                                    <div class="live-dot rounded-circle ma-1"></div>
                                    Live
                                </v-row>
                            </small>

                            <!-- for whitelist user -->
                            <div v-if="whitelisted == true">
                                <p>Whitelist Mint Price: {{ whitelistPrice() }} APT</p>
                                <v-img max-width="20" :src="require('~/assets/images/loader.png')"></v-img>
                                <ReusableProgress class="my-3" />
                                <div v-if="presale == false">
                                    <p>Whitelist Mint is starting in</p>
                                    <ReusableTimer :countDownDate="getWhiteDate()" />
                                </div>
                            </div>
                            <!-- end whitelist user -->

                            <!-- for general public -->
                            <div v-if="whitelisted==false">
                                <p>Public Mint Price: {{publicPrice()}} APT</p>
                                <v-img max-width="20" :src="require('~/assets/images/loader.png')"></v-img>
                                <ReusableProgress class="my-3" />
                                <div v-if="publicMint==false">
                                    <p>Public Mint is starting in</p>
                                    <ReusableTimer :countDownDate="getPublicDate()" />
                                </div>

                            </div>
                            <!-- end general public -->
                        </div>
                    </v-card>
                    <ReusableButtonConnect />

                    <v-row>
                        <v-col>
                            <ReusableButtonMint class="mt-5" />
                        </v-col>
                    </v-row>
                </v-col>
            </v-row>
        </v-container>
    </client-only>
    <WalletChoose />
</div>
</template>

<script>
export default {
    data() {
        return {};
    },
    computed: {
        presale() {
            return this.$store.state.mint.presale;
        },
        live() {
            return this.$store.state.mint.live;
        },
        whitelisted() {
            return this.$store.state.mint.whitelisted;
        },
        candyMachine() {
            return this.$store.state.wallet.candyMachine;
        },
        walletAddr() {
            return this.$store.state.wallet.walletAddr;
        },
        publicMint() {
            return this.$store.state.mint.publicMint
        },
        whitelist(){
            return this.$store.state.wallet.whitelist
        }
    },
    watch: {
        whitelist() {
            this.checkWhitelisted();
        },
        candyMachine(){
            this.checkWhitelisted()
        },
        walletAddr(){
            this.checkWhitelisted()
        }
    },
    mounted() {
        this.checkStatus();
    },
    methods: {
        checkWhitelisted() {
            //whitelist check
            if(this.walletAddr != null){
                if (this.whitelist.includes(this.walletAddr)) {
                    this.$store.commit("mint/setWhitelistedTrue",true);
                }
                else{
                    this.$store.commit("mint/setWhitelistedTrue",false);
                }
            }else{
                this.$store.commit("mint/setWhitelistedTrue",true);
            }
        },
        checkStatus() {
            // console.log(new Date(process.env.WHITELIST_MINT_DATE).getTime())
            // check live
            var whiteDate = process.env.WHITELIST_MINT_DATE
            var now = new Date().getTime();

            if (now > whiteDate) {
                this.$store.commit("mint/setLiveTrue");
                this.$store.commit("mint/setPresaleTrue");
            }

            //mint time check
            var publicDate = process.env.PUBLIC_MINT_DATE

            if (now > publicDate) {
                this.$store.commit("mint/setPublicMintTrue");
            }
        },
        getMint() {
            return this.mint;
        },
        whitelistPrice() {
            return process.env.WHITELIST_MINT_PRICE;
        },
        publicPrice() {
            return process.env.PUBLIC_MINT_PRICE;
        },
        getWhiteDate() {
            return process.env.WHITELIST_MINT_DATE;
        },
        getPublicDate() {
            return process.env.PUBLIC_MINT_DATE;
        },
    },
};
</script>

<style>
.main-box {
    background: linear-gradient(90deg, #000000 0%, #333537 100%),
        linear-gradient(180deg, #6d0509 0%, rgba(109, 5, 9, 0.5) 100%);
    width: 100%;
    position: relative;
}

.live-dot {
    width: 10px;
    height: 10px;
    background: linear-gradient(180deg, #5A41FF 0.9%, rgba(58, 141, 255, 0.84) 100%);
}

.outer-box {
    padding: 2px;
    background: linear-gradient(180deg, #5A41FF 0.9%, rgba(58, 141, 255, 0.84) 100%);
}
</style>
