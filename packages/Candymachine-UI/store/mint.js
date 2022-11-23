export const state = () => ({
  live: false,
  presale: false,
  whitelisted: true,
  publicMint:false,
  sold:false
});

export const mutations = {
  setLiveTrue(state) {
    state.live = true;
  },
  setLiveFalse(state){
    state.live=false
  },
  setPresaleTrue(state) {
    state.presale = true;
  },
  setWhitelistedTrue(state,payload) {
    state.whitelisted = payload;
  },
  setPublicMintTrue(state){
    state.publicMint=true
  },
  setSoldTrue(state){
    state.sold=true
  }
};
export const actions = {
  
};
