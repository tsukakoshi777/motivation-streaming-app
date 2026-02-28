# frozen_string_literal: true

module ImageHelper
  def create_test_image(filename = 'test_avatar.png')
    file_path = Rails.root.join('spec', 'fixtures', filename)
    FileUtils.mkdir_p(File.dirname(file_path))

    # 1x1ピクセルのPNG画像データ
    png_data = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01" \
               "\x08\x02\x00\x00\x00\x90wS\xDE\x00\x00\x00\fIDATx\x9cc\x00\x01\x00" \
               "\x00\x05\x00\x01\r\n-\xB4\x00\x00\x00\x00IEND\xAEB`\x82"

    File.binwrite(file_path, png_data)

    file_path
  end

  def create_invalid_file(filename = 'test_file.txt')
    file_path = Rails.root.join('spec', 'fixtures', filename)
    FileUtils.mkdir_p(File.dirname(file_path))

    File.write(file_path, 'This is a test file')

    file_path
  end
end

RSpec.configure do |config|
  config.include ImageHelper
end
