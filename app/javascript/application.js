import "@hotwired/turbo-rails"
import "./controllers"

// Chart.js をインポート 
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

window.abortController = null;

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

  // グローバル変数として定義 
  window.isCancelled = false;

  async function fetchAiSuggestion() {

    // フラグをリセット 
    window.isCancelled = false;
    console.log('✅ フラグをリセットしました:', window.isCancelled);

    //  data-* 属性から翻訳済みメッセージを取得 
    const messages = document.querySelector('#ai-messages');
    const loadingMessage = messages?.dataset.loading || 'AI提案を取得中...';
    const limitReachedMessage = messages?.dataset.limitReached || 'AI提案の利用回数が上限に達しました。';
    const fetchFailedMessage = messages?.dataset.fetchFailed || 'AI提案の取得に失敗しました。もう一度お試しください。';

    // ✅ ここで goalTitleField などを定義
    const goalTitleField = document.querySelector('input[name="survey_result[goal_title]"]');
    const goalDescriptionField = document.querySelector('textarea[name="survey_result[goal_description]"]');
    const actionPlanField = document.querySelector('textarea[name="survey_result[action_plan]"]');

    // ✅ AI提案を取得する前の内容を保存
    const previousTitle = goalTitleField?.value || '';
    const previousDescription = goalDescriptionField?.value || '';
    const previousActionPlan = actionPlanField?.value || '';

    try {
      console.log('AI提案を取得中...');

      // ✅ AbortController を作成
      window.abortController = new AbortController();

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
        motivation_level: document.querySelector('input[name="survey_profile[motivation_level]"]:checked')?.value,
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
        body: JSON.stringify(formData),
        signal: window.abortController.signal
      });

      // 利用回数制限に達した場合 
      if (response.status === 403) {
        const errorData = await response.json();

        // フォームを保持
        if (goalTitleField) goalTitleField.value = previousTitle;
        if (goalDescriptionField) goalDescriptionField.value = previousDescription;
        if (actionPlanField) actionPlanField.value = previousActionPlan;

        // ここを追加
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
          overlay.classList.add('hidden');
        }

        // エラーメッセージを表示
        alert(limitReachedMessage);
        return; // ここで終了
      }


      if (!response.ok) {
        throw new Error('AI提案の取得に失敗しました');
      }



    } catch (error) {
      console.error('AI提案の取得に失敗しました:', error);

      // ✅ キャンセルされた場合は元の内容に戻す
      if (error.name === 'AbortError') {
        console.log('リクエストがキャンセルされました');

        // 元の内容に戻す
        if (goalTitleField) goalTitleField.value = previousTitle;
        if (goalDescriptionField) goalDescriptionField.value = previousDescription;
        if (actionPlanField) actionPlanField.value = previousActionPlan;

        // ここを追加
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
          overlay.classList.add('hidden');
        }

        return;
      }

      // ✅ その他のエラーの場合も元の内容に戻す
      if (goalTitleField) goalTitleField.value = previousTitle;
      if (goalDescriptionField) goalDescriptionField.value = previousDescription;
      if (actionPlanField) actionPlanField.value = previousActionPlan;

      // ★ ここを追加
      const overlay = document.getElementById('loading-overlay');
      if (overlay) {
        overlay.classList.add('hidden');
      }

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
  // 「AI提案を取得」ボタンのイベントリスナー
  // ========================================

  const fetchAiButton = document.querySelector('#fetch-ai-button');

  if (fetchAiButton) {
    //  既存のイベントリスナーを削除してから新しいものを追加
    const newFetchAiButton = fetchAiButton.cloneNode(true);
    fetchAiButton.parentNode.replaceChild(newFetchAiButton, fetchAiButton);

    //  新しいイベントリスナーを追加
    newFetchAiButton.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation(); // 🆕 イベントの伝播を停止

      // ローディング表示
      const loadingController = document.querySelector('[data-controller="loading"]');
      if (loadingController) {
        const controller = window.Stimulus.getControllerForElementAndIdentifier(loadingController, 'loading');
        if (controller) {
          controller.showLoading();
        }
      }

      // AI提案を取得（finally で自動的にローディング非表示）
      fetchAiSuggestion();
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