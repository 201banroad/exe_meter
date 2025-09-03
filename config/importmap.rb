pin "application"
pin "@hotwired/turbo-rails",       to: "turbo.min.js",          preload: true
pin "@hotwired/stimulus",          to: "stimulus.min.js",       preload: true
pin "@hotwired/stimulus-loading",  to: "stimulus-loading.js",   preload: true

# ★ これが無いと import "controllers" が 404 になる
pin "controllers",             to: "controllers/index.js"
pin "controllers/application", to: "controllers/application.js"

# controllers/ 以下の *_controller.js を全部公開
pin_all_from "app/javascript/controllers", under: "controllers"
