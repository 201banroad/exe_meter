import { application } from "controllers/application" // ← 裸の識別子OK（pin済み）

// 自動ローダは一旦オフでOK
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

import TinyTimerController from "controllers/tiny_timer_controller" // ← 裸の識別子OK
application.register("tiny-timer", TinyTimerController)
