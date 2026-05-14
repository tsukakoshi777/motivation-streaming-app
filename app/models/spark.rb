# frozen_string_literal: true

class Spark < ApplicationRecord
  belongs_to :user
  belongs_to :goal

  # Spark（輝きメモ）とのアソシエーション
  has_many :sparks, dependent: :destroy

  validates :content, presence: true, length: { maximum: 500 }

  # 新しい順に表示
  default_scope -> { order(created_at: :desc) }
end
