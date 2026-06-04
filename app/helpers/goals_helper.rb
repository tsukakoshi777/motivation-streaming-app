# frozen_string_literal: true

module GoalsHelper
  # 星の絵文字を返すメソッド
  def star_emoji(goal)
    spark_count = goal.sparks_count

    case spark_count
    when 0..3
      '✦☆☆☆☆'
    when 4..7
      '✦✦☆☆☆'
    when 8..11
      '✦✦✦☆☆'
    when 12..15
      '✦✦✦✦☆'
    else # 16件以上
      '✦✦✦✦✦'
    end
  end

  # 達成率を返すメソッド
  def achievement_rate(goal)
    spark_count = goal.sparks_count
    total_required = 20 # 完成に必要な件数

    rate = (spark_count.to_f / total_required * 100).round
    [rate, 100].min # 100%を超えないようにする
  end

  # 星のGIFアニメーションを返すメソッド
  def star_gif(goal)
    spark_count = goal.sparks_count

    case spark_count
    when 0..3
      'star_stage_1.gif'
    when 4..7
      'star_stage_2.gif'
    when 8..11
      'star_stage_3.gif'
    when 12..15
      'star_stage_4.gif'
    else # 16件以上
      'star_stage_5.gif'
    end
  end
end
