Rails.application.config.dartsass.builds = {
  'application.scss' => 'application.css'
}

# Bootstrap のパスを load_paths に追加
Rails.application.config.dartsass.load_paths = [
  Rails.root.join('node_modules').to_s
]
