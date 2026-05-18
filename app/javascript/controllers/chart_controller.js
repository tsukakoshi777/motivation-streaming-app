import { Controller } from "@hotwired/stimulus"
import { Chart } from 'chart.js'

export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    console.log("Chart controller connected")
    console.log("Chart Type:", this.typeValue)
    console.log("Chart Data:", this.dataValue)
    console.log("Chart Options:", this.optionsValue)

    // Chart.js でグラフを描画
    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: this.dataValue,
      options: this.optionsValue
    })
  }

  disconnect() {
    // コントローラーが破棄される時にグラフも破棄
    if (this.chart) {
      this.chart.destroy()
    }
  }
}