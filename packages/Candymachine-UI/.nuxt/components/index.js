export const ReusableProgress = () => import('../../components/reusable/progress.vue' /* webpackChunkName: "components/reusable-progress" */).then(c => wrapFunctional(c.default || c))
export const ReusableTimer = () => import('../../components/reusable/timer.vue' /* webpackChunkName: "components/reusable-timer" */).then(c => wrapFunctional(c.default || c))
export const WalletChoose = () => import('../../components/wallet/choose.vue' /* webpackChunkName: "components/wallet-choose" */).then(c => wrapFunctional(c.default || c))
export const ReusableButtonConnect = () => import('../../components/reusable/button/connect.vue' /* webpackChunkName: "components/reusable-button-connect" */).then(c => wrapFunctional(c.default || c))
export const ReusableButtonMint = () => import('../../components/reusable/button/mint.vue' /* webpackChunkName: "components/reusable-button-mint" */).then(c => wrapFunctional(c.default || c))

// nuxt/nuxt.js#8607
function wrapFunctional(options) {
  if (!options || !options.functional) {
    return options
  }

  const propKeys = Array.isArray(options.props) ? options.props : Object.keys(options.props || {})

  return {
    render(h) {
      const attrs = {}
      const props = {}

      for (const key in this.$attrs) {
        if (propKeys.includes(key)) {
          props[key] = this.$attrs[key]
        } else {
          attrs[key] = this.$attrs[key]
        }
      }

      return h(options, {
        on: this.$listeners,
        attrs,
        props,
        scopedSlots: this.$scopedSlots,
      }, this.$slots.default)
    }
  }
}
