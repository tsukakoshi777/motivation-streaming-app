# frozen_string_literal: true

class User < ApplicationRecord
  authenticates_with_sorcery!

  # 外部認証の関連付けを追加
  has_many :authentications, dependent: :destroy
  accepts_nested_attributes_for :authentications

  has_many :survey_profiles, dependent: :destroy
  has_many :goals, dependent: :destroy
  has_many :sparks, dependent: :destroy

  mount_uploader :avatar, AvatarUploader

  validates :nickname, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }

  # ファイルサイズのバリデーション
  # validate :avatar_size_validation

  #  AI提案の利用回数制限
  AI_SUGGESTION_LIMIT = 3

  #  AI提案を使用できるかチェック
  def can_use_ai_suggestion?
    reset_ai_suggestion_count_if_needed
    ai_suggestion_count < AI_SUGGESTION_LIMIT
  end

  #  AI提案の残り回数を取得
  def remaining_ai_suggestion_count
    reset_ai_suggestion_count_if_needed
    [AI_SUGGESTION_LIMIT - ai_suggestion_count, 0].max
  end

  #  AI提案を使用したらカウントを増やす
  def increment_ai_suggestion_count
    update!(ai_suggestion_count: ai_suggestion_count + 1)
  end

  #  日付が変わっていたらカウントをリセット
  def reset_ai_suggestion_count_if_needed
    today = Date.current

    # 最後にリセットした日付が今日でない場合、リセット
    return unless ai_suggestion_reset_date != today

    update!(
      ai_suggestion_count: 0,
      ai_suggestion_reset_date: today
    )
  end

  # private

  # def avatar_size_validation
  #   return unless avatar.present? && avatar.file.present?
  #   return unless avatar.file.size > 5.megabytes
  #
  #   errors.add(:avatar, :max_size_error, size: '5MB')
  # end
end
