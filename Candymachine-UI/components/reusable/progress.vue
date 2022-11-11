<template>
  <v-progress-linear v-if="candyMachine" :value="power" color="#96131D" height="40" rounded>
    <v-progress-circular
      :size="20"
      color="#96131D"
      indeterminate
      v-if="mintLoaded == false"
    ></v-progress-circular>
    <strong v-else>{{ power }}% ({{ minted }}/{{ supply }})</strong>
  </v-progress-linear>
</template>

<script>
export default {
  data() {
    return {
      power: 0,
      supply: "",
      minted: 0,
      mintLoaded: false,
    };
  },
  watch: {
    candyMachine() {
      this.checkMintStatus();
    },
  },
  computed: {
    candyMachine() {
      return this.$store.state.wallet.candyMachine;
    },
  },
  methods: {
    checkMintStatus() {
      this.minted = this.candyMachine.minted;
      if (parseInt(this.minted) == 10000) {
        this.$store.commit("mint/setSoldTrue");
      }
      this.supply = this.candyMachine.supply
      this.power = (
        (parseInt(this.minted) / parseInt(this.supply)) *
        100
      ).toFixed(2);
      this.mintLoaded = true;
    },
  },
};
</script>

<style>
.progress-box {
  display: inline-block;
  border: 2px solid #96131d;
}

.v-progress-linear {
  border: 1px solid #96131d;
  background-color: transparent;
  width: 80%;
  border-radius: 40px;
  height: 30px;
}

.v-progress-linear__background {
  opacity: 0 !important;
  border-radius: 40px !important;
}
</style>
