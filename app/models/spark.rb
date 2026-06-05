# frozen_string_literal: true

class Spark < ApplicationRecord
  belongs_to :user
  belongs_to :goal, counter_cache: true

  validates :content, presence: true, length: { maximum: 500 }

  # 新しい順に表示
  default_scope -> { order(created_at: :desc) }
end
