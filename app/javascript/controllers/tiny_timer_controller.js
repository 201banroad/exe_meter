import { Controller } from "@hotwired/stimulus"

console.log("[tiny] file loaded")   // ← ここ

export default class extends Controller {
  static targets = ["elapsed"]
  connect() {
    console.log("[tiny] connect")   // ← ここ
    this.seconds = 0
    this.render()
    this.timer = setInterval(() => { this.seconds += 1; this.render() }, 1000)
  }
  disconnect(){ if (this.timer) clearInterval(this.timer) }
  render(){ if (this.hasElapsedTarget) this.elapsedTarget.textContent = this.format(this.seconds) }
  format(s){ const h=Math.floor(s/3600), m=Math.floor((s%3600)/60), sec=s%60; return `${String(h).padStart(2,"0")}:${String(m).padStart(2,"0")}:${String(sec).padStart(2,"0")}` }
}
