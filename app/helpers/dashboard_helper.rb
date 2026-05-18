# frozen_string_literal: true

module DashboardHelper
  # 円グラフのデータを生成
  def goal_sparks_chart_data(goal_sparks_data)
    labels = goal_sparks_data.keys.pluck(1)
    data = goal_sparks_data.values

    {
      labels: labels,
      datasets: [{
        label: '輝きメモ件数',
        data: data,
        backgroundColor: [
          '#ebffb3', # 薄い黄色
          '#7a9ec8', # 青グレー
          '#6ba3e9', # 明るい青
          '#5a8fd4', # 青
          '#4a7bbf'  # 濃い青
        ],
        borderWidth: 2,
        borderColor: '#ffffff'
      }]
    }.to_json
  end

  # 円グラフのオプションを生成
  def goal_sparks_chart_options
    {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          position: 'bottom'
        },
        title: {
          display: false
        }
      }
    }.to_json
  end

  # 棒グラフのデータを生成
  def monthly_sparks_chart_data(monthly_sparks_data)
    labels = monthly_sparks_data.keys
    data = monthly_sparks_data.values

    {
      labels: labels,
      datasets: [{
        label: '輝きメモ件数',
        data: data,
        backgroundColor: '#ebffb3', # 明るい青 (半透明)
        borderColor: '#6ba3e9', # 明るい青
        borderWidth: 2
      }]
    }.to_json
  end

  # 棒グラフのオプションを生成
  def monthly_sparks_chart_options
    {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: false
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            stepSize: 1
          }
        }
      }
    }.to_json
  end
end
