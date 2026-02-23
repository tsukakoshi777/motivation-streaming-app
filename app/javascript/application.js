// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
// import "./controllers"  //
import * as bootstrap from "bootstrap"

// Bootstrap の Collapse を初期化する関数
function initializeBootstrapComponents() {
  // すべての navbar-toggler ボタンを取得
  const toggleButtons = document.querySelectorAll('.navbar-toggler');
  
  toggleButtons.forEach((button) => {
    // クリックイベントを追加
    button.addEventListener('click', function(e) {
      e.preventDefault();
      
      // data-bs-target の値を取得
      const targetId = this.getAttribute('data-bs-target');
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        // Bootstrap の Collapse インスタンスを取得または作成
        let collapseInstance = bootstrap.Collapse.getInstance(targetElement);
        
        if (!collapseInstance) {
          collapseInstance = new bootstrap.Collapse(targetElement, {
            toggle: false
          });
        }
        
        // トグル実行
        collapseInstance.toggle();
      }
    });
  });
}

// Turbo のページ読み込み時に初期化
document.addEventListener("turbo:load", () => {
  initializeBootstrapComponents();
});

// 通常のページ読み込み時にも初期化
document.addEventListener("DOMContentLoaded", () => {
  initializeBootstrapComponents();
});
