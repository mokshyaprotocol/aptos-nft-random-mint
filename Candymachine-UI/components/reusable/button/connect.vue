<template>
<v-menu offset-y>
    <template v-slot:activator="{ on, attrs }">
        <v-btn class="conn-btn px-8 text-capitalize" dark v-bind="attrs" v-on="on" @click="$store.dispatch('wallet/connectWallet')">
            <v-row v-if="walletAddr" justify="center">
                <div class="bg-white mr-2 ml-n2 mt-1">
                    <v-img v-if="walletType=='Martian'" :src="require('~/assets/images/martian.svg')" max-width="30"></v-img>
                    <v-img v-else-if="walletType=='Petra'" :src="require('~/assets/images/petra.svg')" max-width="30"></v-img>
                </div>
                <span class="mt-3">
                    <span v-if="walletAddr">{{walletAddr.slice(0,5)+'...'+walletAddr.slice(-4)}}</span>
                </span>
            </v-row>
            <span v-else>Connect Wallet</span>

        </v-btn>
    </template>
    <v-list v-if="walletAddr" style="background-color:#2F3573" dense>
        <v-list-item @click="$store.dispatch('wallet/logout')">
            <v-list-item-title>Disconnect</v-list-item-title>
        </v-list-item>
    </v-list>
</v-menu>
</template>

<script>
export default {
    data() {
        return {
        }
    },
    computed: {
        profile() {
            return this.$store.state.wallet.profile
        },
        walletAddr() {
            return this.$store.state.wallet.walletAddr
        },
        walletType() {
            return this.$store.state.wallet.walletType
        }

    }
}
</script>

<style>
.conn-btn {
    cursor: pointer;
    height: 45px;
    width: 150px;
    border-radius: 50px;
    background: linear-gradient(180deg, #5A41FF 0.9%, rgba(58, 141, 255, 0.84) 100%);
    box-shadow: 0px 3px 1px 0px #FFFFFF80;

}

.bg-white {
    width: 30px;
    height: 30px;
    padding: 2px;
    background-color: white;
    border-radius: 50%;
}
</style>
