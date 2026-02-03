import { application } from "./application"

// controllers ディレクトリ内のすべてのコントローラーを自動で読み込む
const controllers = import.meta.glob('./**/*_controller.js', { eager: true })

for (const path in controllers) {
  const module = controllers[path]
  const name = path
    .replace(/^\.\//, '')
    .replace(/_controller\.js$/, '')
    .replace(/\//g, '--')
  
  application.register(name, module.default)
}
