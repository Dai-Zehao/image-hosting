import { createApp } from 'vue'
import App from './App.vue'

const manifest = document.createElement('link')
manifest.rel = 'manifest'
manifest.href = '/care/app/manifest.webmanifest'
document.head.appendChild(manifest)

const icon = document.createElement('link')
icon.rel = 'icon'
icon.type = 'image/png'
icon.href = '/care/app/assets/r6care-app-icon.png'
document.head.appendChild(icon)

const appleIcon = document.createElement('link')
appleIcon.rel = 'apple-touch-icon'
appleIcon.href = '/care/app/assets/r6care-app-icon.png'
document.head.appendChild(appleIcon)

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/care/app/sw.js').catch(() => {})
  })
}

createApp(App).mount('#app')

