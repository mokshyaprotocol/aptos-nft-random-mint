<template>
    <div>
        <v-dialog max-width="400" v-model="choose">
            <v-card color="#2D2C30;" class="py-5">
                <h2 class="text-center">Choose Wallet</h2>
                <v-card class="rounded-lg mx-5 pa-0 my-2" color="#404045" v-for="(item,i) in wallets" :key="i" @click="selectWallet(item)">
                    <v-list-item>
                        <v-list-item-content>
                            <v-list-item-title>{{item.title}}</v-list-item-title>
                        </v-list-item-content>
                        <v-list-item-action>
                            <v-img :src="require(`~/assets/images/${item.icon}`)" width="30"></v-img>
                        </v-list-item-action>
                    </v-list-item>
                </v-card>
            </v-card>
        </v-dialog>
    </div>
    </template>
    
    <script>
    export default {
        data(){
            return{
               wallets:[
                {icon:'martian.svg',title:'Martian'},
                {icon:'petra.svg',title:'Petra'},
               ]
            }
        },
        computed: {
            choose: {
                get() {
                    return this.$store.state.wallet.choose
                },
                set(value) {
                    this.$store.commit('wallet/chooseWallet', value)
                }
            }
        },
        methods:{
            async selectWallet(item){
                await this.$store.commit('wallet/selectWalletType',item.title)
                this.$store.commit('wallet/setDisabled',true)
                this.$store.dispatch('wallet/connectWallet')
            }
        }
    }
    </script>
    