
import { Controller } from "@hotwired/stimulus"


console.log("[tiny] file loaded")   

export default class extends Controller {
  static targets = ["elapsed"]
  static values = {
    initialSeconds: Number, // サーバから渡す初期秒
    running: Boolean        // サーバで実行中か
  }
connect() {
  console.log("[tiny] connect")
  this.seconds = this.initialSecondsValue || 0   // ← サーバーから来た値を使う
  this.intervalId = null
  this.isRunning = false
  this.render()

  this._beforeCacheHandler = () => this.stop()
  document.addEventListener("turbo:before-cache", this._beforeCacheHandler)

    // 先にボタン状態を初期化
    this.updateButtons()

   // サーバが実行中なら自動で再開
    if (this.runningValue) this.start()
}

  // --- クリックハンドラ（無効時はPOSTさせない） ---
  handleStartClick(event) {
    if (this.isRunning) { event.preventDefault(); return }
    this.start() // ← JS表示を即更新（POSTはそのまま進む）
  }

    handleStopClick(event) {
    if (!this.isRunning) { event.preventDefault(); return }
    this.stop()
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

    // --- ボタンの有効/無効を切り替え ---
  updateButtons() {
    if (this.hasStartButtonTarget) this._setDisabled(this.startButtonTarget, this.isRunning)
    if (this.hasStopButtonTarget)  this._setDisabled(this.stopButtonTarget, !this.isRunning)
  }

  _setDisabled(el, disabled) {
    el.setAttribute("aria-disabled", disabled ? "true" : "false")
    el.classList.toggle("is-disabled", disabled)
    if (disabled) {
      el.setAttribute("tabindex", "-1")
    } else {
      el.removeAttribute("tabindex")
    }
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








