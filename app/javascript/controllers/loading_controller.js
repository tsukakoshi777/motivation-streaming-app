// app/javascript/controllers/loading_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "form"]

  connect() {
    console.log("Loading controller connected")
    // ✅ addEventListener は不要!data-action で自動的に接続される
  }

  // AI提案取得時にローディングを表示
  showLoading(event) {
    console.log("showLoading called")

    // ローディングオーバーレイを表示
    this.element.classList.remove('hidden')

    // フォームを無効化
    if (this.hasFormTarget) {
      const submitButton = this.formTarget.querySelector('button[type="submit"]')
      if (submitButton) {
        submitButton.disabled = true
      }
    }
  }

  // ローディングを非表示
  hideLoading() {
    console.log("hideLoading called")

    this.element.classList.add('hidden')

    // フォームを有効化
    if (this.hasFormTarget) {
      const submitButton = this.formTarget.querySelector('button[type="submit"]')
      if (submitButton) {
        submitButton.disabled = false
      }
    }
  }

  // キャンセルボタンの処理
  cancel(event) {
    console.log("cancel called")
    event.preventDefault()

    // ✅ fetch リクエストをキャンセル
    if (window.abortController) {
      window.abortController.abort();
      console.log("fetch request aborted");
    }

    this.hideLoading()
  }
}