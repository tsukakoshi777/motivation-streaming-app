// app/javascript/controllers/goal_search_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions", "form"]
  static values = { 
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    console.log("Goal search controller connected")
    this.selectedIndex = -1
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // 入力時の処理（デバウンス付き）
  search() {
    // 既存のタイムアウトをクリア
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    const query = this.inputTarget.value.trim()

    // 入力が短い場合は候補を非表示
    if (query.length < this.minLengthValue) {
      this.hideSuggestions()
      return
    }

    // 300ms 後に検索を実行（デバウンス）
    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 300)
  }

  // API から検索候補を取得
  async fetchSuggestions(query) {
    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        headers: {
          "Accept": "application/json"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.displaySuggestions(data)
    } catch (error) {
      console.error("Failed to fetch suggestions:", error)
      this.hideSuggestions()
    }
  }

  // 検索候補を表示
  displaySuggestions(suggestions) {
    if (suggestions.length === 0) {
      this.hideSuggestions()
      return
    }

    this.suggestionsTarget.innerHTML = suggestions.map((suggestion, index) => `
      <div class="suggestion-item ${index === 0 ? 'selected' : ''}" 
           data-action="click->goal-search#select"
           data-goal-id="${suggestion.id}"
           data-index="${index}">
        <div class="suggestion-title">${this.escapeHtml(suggestion.title)}</div>
        <div class="suggestion-description">${this.escapeHtml(suggestion.description)}</div>
      </div>
    `).join('')

    this.showSuggestions()
    this.selectedIndex = 0
  }

  // 検索候補を表示
  showSuggestions() {
    this.suggestionsTarget.classList.remove("d-none")
  }

  // 検索候補を非表示
  hideSuggestions() {
    this.suggestionsTarget.classList.add("d-none")
    this.selectedIndex = -1
  }

  // 候補を選択
  select(event) {
    const goalId = event.currentTarget.dataset.goalId
    window.location.href = `/goals/${goalId}`
  }

  // キーボード操作
  navigate(event) {
    const items = this.suggestionsTarget.querySelectorAll('.suggestion-item')
    if (items.length === 0) return

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.updateSelection(items)
        break
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
      case 'Escape':
        this.hideSuggestions()
        break
    }
  }

  // 選択状態の更新
  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('selected')
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.classList.remove('selected')
      }
    })
  }

  // XSS対策のHTMLエスケープ
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // 検索候補の外をクリックしたら閉じる
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }
}