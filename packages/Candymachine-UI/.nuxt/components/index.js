export { default as ReusableProgress } from '../../components/reusable/progress.vue'
export { default as ReusableTimer } from '../../components/reusable/timer.vue'
export { default as WalletChoose } from '../../components/wallet/choose.vue'
export { default as ReusableButtonConnect } from '../../components/reusable/button/connect.vue'
export { default as ReusableButtonMint } from '../../components/reusable/button/mint.vue'

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
