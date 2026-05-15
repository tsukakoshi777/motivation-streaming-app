# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :require_login

  def index
    # 見つかった成長の星（作成された目標数）
    @total_goals_count = current_user.goals.count

    # 達成した成長の星（輝きメモが20件以上の目標数）
    @completed_stars_count = current_user.goals.joins(:sparks)
                                         .group('goals.id')
                                         .having('COUNT(sparks.id) >= 20')
                                         .count.size

    # 総輝きメモ件数
    @total_sparks_count = current_user.sparks.count

    # きらめきバッジの判定
    @badges = calculate_badges
  end

  private

  def calculate_badges
    badges = []

    # 継続の証（輝きメモが10件以上）
    badges << { name: '継続の証', emoji: '🌠' } if @total_sparks_count >= 10

    # 輝きの達人（輝きメモが30件以上）
    badges << { name: '輝きの達人', emoji: '💫' } if @total_sparks_count >= 30

    # 目標達成者（成長の星が1個以上）
    badges << { name: '目標達成者', emoji: '🌟' } if @completed_stars_count >= 1

    # マルチタスカー（目標が3個以上）
    badges << { name: 'マルチタスカー', emoji: '⭐' } if current_user.goals.count >= 3

    badges
  end
end
