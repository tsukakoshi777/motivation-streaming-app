# frozen_string_literal: true

class User < ApplicationRecord
  authenticates_with_sorcery!

  has_many :survey_profiles, dependent: :destroy
  has_many :goals, dependent: :destroy

  validates :nickname, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
end
