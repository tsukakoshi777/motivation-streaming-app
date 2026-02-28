# frozen_string_literal: true

class AvatarUploader < CarrierWave::Uploader::Base
  # 画像のリサイズを行う場合は mini_magick を使用
  include CarrierWave::MiniMagick

  # 開発環境ではローカルストレージ、本番環境ではS3を使用
  if Rails.env.production?
    storage :fog
  else
    storage :file
  end

  # アップロード先のディレクトリ
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # デフォルト画像の設定（オプション）
  # def default_url(*args)
  #   "/images/fallback/default.png"
  # end

  # 許可する画像の拡張子
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  # ファイルサイズの制限（5MBまで）
  def size_range
    1..(5.megabytes)
  end

  # 画像のリサイズ（必要に応じて）
  version :thumb do
    process resize_to_fit: [200, 200]
  end
end
