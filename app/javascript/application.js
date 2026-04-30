import "@hotwired/turbo-rails"

// ========================================
// Bootstrap の Collapse を初期化する関数
// ========================================

function initializeBootstrapCollapse() {
  // Bootstrap が読み込まれているか確認
  if (typeof window.bootstrap === 'undefined') {
    return;
  }

  // すべての Collapse 要素を取得
  const collapseElements = document.querySelectorAll('.collapse');

  collapseElements.forEach((element) => {
    // 既存のインスタンスを破棄
    const existingInstance = window.bootstrap.Collapse.getInstance(element);
    if (existingInstance) {
      existingInstance.dispose();
    }

    // show クラスを削除（メニューを閉じた状態にする）
    element.classList.remove('show');

    // 新しいインスタンスを作成
    const collapseInstance = new window.bootstrap.Collapse(element, {
      toggle: false
    });
  });

  // トグルボタンのイベントリスナーを再設定
  const toggleButtons = document.querySelectorAll('[data-bs-toggle="collapse"]');

  toggleButtons.forEach((button) => {
    // 既存のイベントリスナーを削除するために、クローンを作成
    const newButton = button.cloneNode(true);
    button.parentNode.replaceChild(newButton, button);

    // 新しいイベントリスナーを追加
    newButton.addEventListener('click', function (e) {
      e.preventDefault();

      const targetId = this.getAttribute('data-bs-target');
      const targetElement = document.querySelector(targetId);

      if (targetElement) {
        const collapseInstance = window.bootstrap.Collapse.getInstance(targetElement);
        if (collapseInstance) {
          collapseInstance.toggle();
        }
      }
    });
  });
}

// ========================================
// ページ読み込み時の初期化処理
// ========================================

document.addEventListener("turbo:load", initializeForm);
document.addEventListener("turbo:render", initializeForm);

function initializeForm() {
  // Bootstrap Collapse を初期化
  initializeBootstrapCollapse();

  // ========================================
  // アクションプラン用の自動箇条書き機能
  // ========================================

  const textarea = document.querySelector('.action-plan-textarea');
  const goalSourceAi = document.querySelector('#goal_source_ai');
  const goalSourceManual = document.querySelector('input[name="survey_result[goal_source]"][value="1"]');

  //  以下の3つを追加・修正 
  const goalTitleField = document.querySelector('input[name="survey_result[goal_title]"]');
  const goalDescriptionField = document.querySelector('textarea[name="survey_result[goal_description]"]');
  const actionPlanField = document.querySelector('textarea[name="survey_result[action_plan]"]');

  // ========================================
  // RailsのAPIからAI提案を取得する関数
  // ========================================

  async function fetchAiSuggestion() {
    //  data-* 属性から翻訳済みメッセージを取得 
    const messages = document.querySelector('#ai-messages');
    const loadingMessage = messages?.dataset.loading || 'AI提案を取得中...';
    const limitReachedMessage = messages?.dataset.limitReached || 'AI提案の利用回数が上限に達しました。';
    const fetchFailedMessage = messages?.dataset.fetchFailed || 'AI提案の取得に失敗しました。もう一度お試しください。';

    try {
      console.log('AI提案を取得中...');

      //  ローディング表示
      if (goalTitleField) goalTitleField.value = loadingMessage;
      if (goalDescriptionField) goalDescriptionField.value = '';
      if (actionPlanField) actionPlanField.value = '';

      // フォームで選択した値を取得 
      const formData = {
        streaming_platform_id: document.querySelector('select[name="survey_profile[streaming_platform_id]"]')?.value,
        streaming_category_id: document.querySelector('select[name="survey_profile[streaming_category_id]"]')?.value,
        streaming_experience_id: document.querySelector('select[name="survey_profile[streaming_experience_id]"]')?.value,
        weekly_frequency: document.querySelector('input[name="survey_profile[weekly_frequency]"]')?.value,
        average_listeners: document.querySelector('input[name="survey_profile[average_listeners]"]')?.value,
        total_listeners: document.querySelector('input[name="survey_profile[total_listeners]"]')?.value,
        listener_dropout_rate: document.querySelector('input[name="survey_profile[listener_dropout_rate]"]')?.value,
        motivation_level: document.querySelector('input[name="survey_profile[motivation_level]"]')?.value,
        happy_moment: document.querySelector('textarea[name="survey_profile[happy_moment]"]')?.value,
        sad_moment: document.querySelector('textarea[name="survey_profile[sad_moment]"]')?.value,
        desired_streaming_style: document.querySelector('textarea[name="survey_profile[desired_streaming_style]"]')?.value,
        desired_listener: document.querySelector('textarea[name="survey_profile[desired_listener]"]')?.value,
        desired_monthly_income: document.querySelector('input[name="survey_profile[desired_monthly_income]"]')?.value,
        streaming_reasons: Array.from(document.querySelectorAll('input[name="survey_profile[streaming_reasons][]"]:checked')).map(cb => cb.value),
        streaming_reasons_other: document.querySelector('input[name="survey_profile[streaming_reasons_other]"]')?.value
      };

      console.log('送信するデータ:', formData);

      //  CSRF tokenを安全に取得 
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || '';

      console.log('CSRF Token:', csrfToken ? '取得成功' : '取得失敗(空文字列を使用)');

      // バックエンドに POST リクエストを送信 
      const response = await fetch('/survey_profiles/fetch_ai_suggestion', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken  // ← 安全に取得したCSRF tokenを使用
        },
        body: JSON.stringify(formData)
      });

      // 利用回数制限に達した場合 
      if (response.status === 403) {
        const errorData = await response.json();

        // フォームをクリア
        if (goalTitleField) goalTitleField.value = '';
        if (goalDescriptionField) goalDescriptionField.value = '';
        if (actionPlanField) actionPlanField.value = '';

        // エラーメッセージを表示
        alert(limitReachedMessage);
        return; // ここで終了
      }


      if (!response.ok) {
        throw new Error('AI提案の取得に失敗しました');
      }

      const data = await response.json();

      console.log('受信したデータ:', data);

      // フォームに挿入
      if (goalTitleField) {
        goalTitleField.value = data.goal_title || '';
      }

      if (goalDescriptionField) {
        goalDescriptionField.value = data.goal_description || '';
      }

      if (actionPlanField) {
        // アクションプランに ◇ を挿入 
        const actionPlan = data.action_plan || '';

        // 改行で分割して、各行の先頭に ◇ を追加
        const formattedActionPlan = actionPlan.split('\n').map(line => {
          const trimmedLine = line.trim();

          // 空行はそのまま
          if (trimmedLine === '') return '';

          // 既に ◇ が付いている場合はそのまま
          if (trimmedLine.startsWith('◇')) return line;

          // 数字で始まる場合は、数字の前に ◇ を追加
          // 例: "1. ステップ1" → "◇ 1. ステップ1"
          return `◇ ${trimmedLine}`;
        }).join('\n');

        actionPlanField.value = formattedActionPlan;

        console.log('フォーマット後のアクションプラン:', formattedActionPlan);
      }

      console.log('AI提案のデータを挿入しました!');

    } catch (error) {
      console.error('AI提案の取得に失敗しました:', error);

      //  エラー時はフォームをクリア 
      if (goalTitleField) goalTitleField.value = '';
      if (goalDescriptionField) goalDescriptionField.value = '';
      if (actionPlanField) actionPlanField.value = '';

      alert(fetchFailedMessage); 
    }
  }


  // ========================================
  // アクションプラン用の自動箇条書き機能
  // ========================================

  if (textarea) {
    // 初回入力時に◇を自動挿入
    textarea.addEventListener('focus', (e) => {
      if (textarea.value === '') {
        textarea.value = '◇ ';
        textarea.selectionStart = textarea.selectionEnd = 2;
      }
    });

    // Enterキーが押されたとき
    textarea.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();

        const cursorPos = textarea.selectionStart;
        const textBeforeCursor = textarea.value.substring(0, cursorPos);
        const textAfterCursor = textarea.value.substring(cursorPos);

        textarea.value = textBeforeCursor + '\n◇ ' + textAfterCursor;
        textarea.selectionStart = textarea.selectionEnd = cursorPos + 3;
      }
    });
  }

  // ========================================
  // AI提案のラジオボタン選択時の処理
  // ========================================

  if (goalSourceAi) {
    //  既存のイベントリスナーを削除してから新しいものを追加 
    const newGoalSourceAi = goalSourceAi.cloneNode(true);
    goalSourceAi.parentNode.replaceChild(newGoalSourceAi, goalSourceAi);

    // 新しいイベントリスナーを追加 
    newGoalSourceAi.addEventListener('change', (e) => {
      if (e.target.checked) {
        fetchAiSuggestion();
      }
    });
  }

  // ========================================
  // 自分で設定するラジオボタン選択時の処理
  // ========================================

  if (goalSourceManual) {
    // 既存のイベントリスナーを削除してから新しいものを追加 
    const newGoalSourceManual = goalSourceManual.cloneNode(true);
    goalSourceManual.parentNode.replaceChild(newGoalSourceManual, goalSourceManual);

    // 新しいイベントリスナーを追加 
    newGoalSourceManual.addEventListener('change', (e) => {
      if (e.target.checked) {
        // フォームをクリア(任意)
        // clearFormFields();
      }
    });
  }



  // ========================================
  // フォームをクリアする関数(任意)
  // ========================================

  function clearFormFields() {
    if (goalTitleField) {
      goalTitleField.value = '';
    }

    if (goalDescriptionField) {
      goalDescriptionField.value = '';
    }

    if (textarea) {
      textarea.value = '';
    }
  }
}  // ← initializeForm() の終了

// ========================================
// 最初のページ読み込み時にも初期化
// ========================================

document.addEventListener("DOMContentLoaded", initializeBootstrapCollapse);