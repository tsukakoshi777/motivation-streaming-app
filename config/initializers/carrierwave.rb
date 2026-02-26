require 'carrierwave/storage/abstract'
require 'carrierwave/storage/file'
require 'carrierwave/storage/fog'

CarrierWave.configure do |config|
  if Rails.env.production?
    # 本番環境：S3を使用
    config.storage = :fog
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region:                ENV['AWS_REGION'] || 'ap-northeast-1',
      path_style:            true
    }
    config.fog_directory  = ENV['AWS_S3_BUCKET']
    config.fog_public     = false # プライベートバケットの場合
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  else
    # 開発環境：ローカルストレージを使用
    config.storage = :file
    config.enable_processing = false if Rails.env.test?
  end
end