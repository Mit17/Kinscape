import Vue from 'vue'
import vuetify from '../plugins/vuetify'
import router from './router'
import { store } from '../store'
import VueResource from 'vue-resource'
import i18n from '../plugins/i18n'
import eventBus from '@/plugins/eventBus'
import directUploadPath from '../plugins/directUploadPath'
import directUploadAllowedTypes from '@/plugins/directUploadAllowedTypes'
import fontAwesome from '../plugins/fontAwesome'
import globalComponents from '../plugins/globalComponents'
import globalUtils from '../plugins/globalUtils'
import globalDirectives from '../plugins/globalDirectives'
import showcase from '../plugins/showcase'
import simpleLightbox from '../plugins/simpleLightbox'
import casl from '../plugins/casl'
import { globalMixin } from '@/mixins/globalMixin'
import App from './App'

Vue.config.ignoredElements = ['trix-editor']
Vue.config.devtools = true
Vue.use(VueResource)
Vue.mixin(globalMixin)

document.addEventListener('DOMContentLoaded', () => {
  i18n()
  eventBus()
  directUploadPath()
  directUploadAllowedTypes()
  fontAwesome()
  showcase()
  simpleLightbox()
  globalComponents()
  globalUtils()
  globalDirectives()
  casl()
  // eslint-disable-next-line no-new
  new Vue({
    el: '#app',
    components: { App },
    router,
    store,
    vuetify
  })
})
