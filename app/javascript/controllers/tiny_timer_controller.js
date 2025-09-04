
import { Controller } from "@hotwired/stimulus"


console.log("[tiny] file loaded")   

export default class extends Controller {
  static targets = ["elapsed"]
  static values = { initialSeconds: Number }

connect() {
  console.log("[tiny] connect")
  this.seconds = this.initialSecondsValue || 0   // ← サーバーから来た値を使う
  this.intervalId = null
  this.isRunning = false
  this.render()

  this._beforeCacheHandler = () => this.stop()
  document.addEventListener("turbo:before-cache", this._beforeCacheHandler)
}

disconnect() {
  this.stop()
  document.removeEventListener("turbo:before-cache", this._beforeCacheHandler)
}
  start() {
    if (this.isRunning) return   // すでに動いていたら何もしない

    this.isRunning = true
    this.intervalId = setInterval(() => {
      this.seconds += 1
      this.render()
    }, 1000)

    this.render()
    console.log("[tiny] start", this.intervalId)
  }

  stop() {
    if (!this.isRunning && !this.intervalId) return

    this.isRunning = false
    if (this.intervalId) {
      clearInterval(this.intervalId)
      console.log("[tiny] stop", this.intervalId)
      this.intervalId = null
    }
    this.render()
  }

  render() {
    if (this.hasElapsedTarget) {
      this.elapsedTarget.textContent = this.format(this.seconds || 0)
    }
  }

  format(s) {
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const sec = s % 60
    return `${String(h).padStart(2,"0")}:${String(m).padStart(2,"0")}:${String(sec).padStart(2,"0")}`
  }




}








