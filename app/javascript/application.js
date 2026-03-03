import "@hotwired/turbo-rails"

// Bootstrap の Collapse を初期化する関数
function initializeBootstrapCollapse() {
  console.log("Initializing Bootstrap Collapse..."); // デバッグ用
  
  // Bootstrap が読み込まれているか確認
  if (typeof window.bootstrap === 'undefined') {
    console.error('Bootstrap is not loaded');
    return;
  }

  // すべての Collapse 要素を取得
  const collapseElements = document.querySelectorAll('.collapse');
  console.log("Found collapse elements:", collapseElements); // デバッグ用
  
  collapseElements.forEach((element) => {
    // 既存のインスタンスを破棄
    const existingInstance = window.bootstrap.Collapse.getInstance(element);
    if (existingInstance) {
      console.log("Disposing existing instance for:", element); // デバッグ用
      existingInstance.dispose();
    }
    
    // show クラスを削除（メニューを閉じた状態にする）
    element.classList.remove('show');
    
    // 新しいインスタンスを作成
    const collapseInstance = new window.bootstrap.Collapse(element, {
      toggle: false
    });
    
    console.log("Created new Collapse instance for:", element); // デバッグ用
  });
  
  // トグルボタンのイベントリスナーを再設定
  const toggleButtons = document.querySelectorAll('[data-bs-toggle="collapse"]');
  console.log("Found toggle buttons:", toggleButtons); // デバッグ用
  
  toggleButtons.forEach((button) => {
    // 既存のイベントリスナーを削除するために、クローンを作成
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);
    
    // 新しいイベントリスナーを追加
    newButton.addEventListener('click', function(e) {
      e.preventDefault();
      console.log("Toggle button clicked!"); // デバッグ用
      
      const targetId = this.getAttribute('data-bs-target');
      const targetElement = document.querySelector(targetId);
      
      if (targetElement) {
        const collapseInstance = window.bootstrap.Collapse.getInstance(targetElement);
        if (collapseInstance) {
          console.log("Toggling collapse..."); // デバッグ用
          collapseInstance.toggle();
        } else {
          console.error("Collapse instance not found for:", targetElement);
        }
      } else {
        console.error("Target element not found:", targetId);
      }
    });
  });
}

// ページ読み込み時に初期化
document.addEventListener("turbo:load", initializeBootstrapCollapse);

// 最初のページ読み込み時にも初期化
document.addEventListener("DOMContentLoaded", initializeBootstrapCollapse);