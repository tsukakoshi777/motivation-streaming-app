import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "form"]
  //  入力内容を保存する変数を追加 
  savedGoalTitle = ""
  savedGoalDescription = ""
  savedActionPlan = ""


  connect() {
    console.log('Loading controller connected');

    // 既存のイベントリスナーを解除
    if (this.handleStreamRenderBound) {
      document.removeEventListener('turbo:before-stream-render', this.handleStreamRenderBound);
    }

    // 新しいイベントリスナーを登録
    this.handleStreamRenderBound = this.handleStreamRender.bind(this);
    document.addEventListener('turbo:before-stream-render', this.handleStreamRenderBound);

    console.log('✅ turbo:before-stream-render イベントリスナーを登録しました');

    // Turbo Streams の接続を確認
    this.checkTurboStreamConnection()
  }

  checkTurboStreamConnection() {
    const turboStreamElement = document.querySelector('[data-turbo-stream-from]')
    if (turboStreamElement) {
      console.log("✅ Turbo Stream element found:", turboStreamElement)
      console.log("Channel name:", turboStreamElement.getAttribute('data-turbo-stream-from'))
    } else {
      console.log('✅ Turbo Stream element not found (ページ読み込み時は正常)')
    }
  }

  disconnect() {
    // イベントリスナーを解除
    if (this.handleStreamRenderBound) {
      document.removeEventListener('turbo:before-stream-render', this.handleStreamRenderBound);
      console.log('✅ turbo:before-stream-render イベントリスナーを解除しました');
    }
  }

  cancel(event) {
    event.preventDefault();
    console.log('✅ キャンセルボタンがクリックされました');

    // ✅ ジョブIDを送信せず、サーバー側でセッションから取得する
    fetch('/survey_profiles/cancel_ai_suggestion', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      }
    })
      .then(response => {
        if (response.ok) {
          console.log('✅ キャンセルリクエストを送信しました');
        } else {
          console.error('❌ キャンセルリクエストが失敗しました');
        }
      })
      .catch(error => {
        console.error('❌ キャンセルリクエストでエラーが発生しました:', error);
      });

    // グローバル変数を使う
    window.isCancelled = true;

    // 保存した内容を復元
    const goalTitleField = document.querySelector('input[name="survey_result[goal_title]"]');
    const goalDescriptionField = document.querySelector('textarea[name="survey_result[goal_description]"]');
    const actionPlanField = document.querySelector('textarea[name="survey_result[action_plan]"]');

    if (goalTitleField) {
      goalTitleField.value = this.savedGoalTitle;
      console.log('✅ タイトルを復元しました:', this.savedGoalTitle);
    }

    if (goalDescriptionField) {
      goalDescriptionField.value = this.savedGoalDescription;
      console.log('✅ 説明を復元しました');
    }

    if (actionPlanField) {
      actionPlanField.value = this.savedActionPlan;
      console.log('✅ アクションプランを復元しました');
    }

    this.hideLoading();
    console.log('✅ ローディングを非表示にしました');
  }

  handleStreamRender(event) {
    console.log('✅✅✅ turbo:before-stream-render イベントを受信しました ✅✅✅');

    // ★ グローバル変数を使う
    if (window.isCancelled) {
      console.log('✅ キャンセルされているため、処理をスキップします');
      event.preventDefault();
      return;
    }

    // 以下、既存のコード
    const streamElement = event.target;
    const targetId = streamElement.getAttribute('target');
    console.log('✅ target ID:', targetId);

    if (targetId === 'ai_suggestion_form') {
      console.log('✅ ai_suggestion_form フレームが更新されます');

      setTimeout(() => {
        const dataElement = document.getElementById('ai-suggestion-data');
        if (dataElement) {
          console.log('✅ ai-suggestion-data を発見しました');

          // ★ ジョブIDをセット
          const jobId = dataElement.dataset.jobId;
          console.log('✅ dataElement.dataset.jobId:', jobId); // ← デバッグ用ログ

          if (jobId) {
            this.element.dataset.jobId = jobId;
            console.log('✅ ジョブIDをセットしました:', jobId);
          } else {
            console.log('❌ ジョブIDが取得できませんでした');
          }

          if (dataElement.dataset.goalTitle) {
            console.log('✅ データがあります。handleAiSuggestion() を実行します。');
            this.handleAiSuggestion();
          } else if (dataElement.dataset.error) {
            console.log('❌ エラーが発生しました:', dataElement.dataset.error);
            this.hideLoading();
            alert(dataElement.dataset.error);
            dataElement.removeAttribute('data-error');
          } else {
            console.log('❌ ai-suggestion-data にはまだデータがありません');
          }
        } else {
          console.log('❌ ai-suggestion-data が見つかりませんでした');
        }
      }, 100);
    } else {
      console.log('ℹ️ 他のフレームが更新されました:', targetId);
    }
  }

  submit(event) {
    event.preventDefault();

    // フラグをリセット
    window.isCancelled = false;

    this.showLoading();
    this.formTarget.submit();
  }

  // ★ AI提案のデータを処理
  handleAiSuggestion() {
    console.log('★★★ handleAiSuggestion() が呼び出されました ★★★');

    const dataElement = document.getElementById('ai-suggestion-data');
    if (!dataElement) {
      console.log('❌ ai-suggestion-data が見つかりませんでした');
      return;
    }

    console.log('✅ ai-suggestion-data を発見しました');
    console.log('✅ dataElement.dataset:', dataElement.dataset);

    // エラーがある場合
    const error = dataElement.dataset.error;
    if (error) {
      console.log('❌ エラーが発生しました:', error);
      this.hideLoading();
      alert(error);
      dataElement.removeAttribute('data-error');
      return;
    }

    // 成功した場合
    const goalTitle = dataElement.dataset.goalTitle;
    const goalDescription = dataElement.dataset.goalDescription;
    const actionPlan = dataElement.dataset.actionPlan;
    const remainingCount = dataElement.dataset.remainingCount;
    const resetDateText = dataElement.dataset.resetDateText;

    console.log('✅ 取得したデータ:');
    console.log('  goalTitle:', goalTitle);
    console.log('  goalDescription:', goalDescription ? '(データあり)' : '(データなし)');
    console.log('  actionPlan:', actionPlan ? '(データあり)' : '(データなし)');

    // ★ データが揃っているか確認
    if (!goalTitle || !goalDescription || !actionPlan) {
      console.log('❌ データが不完全です');
      return;
    }

    console.log('✅ データが揃っています。フォームに自動入力します。');

    // ★ フォームの要素を取得
    const titleElement = document.getElementById('survey_result_goal_title');
    const descriptionElement = document.getElementById('survey_result_goal_description');
    const actionPlanElement = document.getElementById('survey_result_action_plan');
    const resetDateElement = document.getElementById('ai-suggestion-reset-date');

    console.log('✅ フォーム要素の取得結果:');
    console.log('  titleElement:', titleElement);
    console.log('  descriptionElement:', descriptionElement);
    console.log('  actionPlanElement:', actionPlanElement);

    // ★ 要素が見つからない場合
    if (!titleElement) {
      console.log('❌ titleElement が見つかりませんでした');
      return;
    }
    if (!descriptionElement) {
      console.log('❌ descriptionElement が見つかりませんでした');
      return;
    }
    if (!actionPlanElement) {
      console.log('❌ actionPlanElement が見つかりませんでした');
      return;
    }

    // ★ フォームに自動入力
    console.log('✅ フォームに値を設定します');

    titleElement.value = goalTitle;
    console.log('✅ タイトルを設定しました:', goalTitle);

    descriptionElement.value = goalDescription;
    console.log('✅ 説明を設定しました');

    // ★ アクションプランを整形
    const lines = actionPlan.split('\n').filter(line => line.trim() !== '');
    const formattedActionPlan = lines.map(line => {
      const trimmedLine = line.trim();
      if (trimmedLine === '') return '';
      if (trimmedLine.startsWith('◇')) return line;
      return `◇ ${trimmedLine}`;
    }).join('\n');

    actionPlanElement.value = formattedActionPlan;
    console.log('✅ アクションプランを設定しました');

    const statusElement = document.getElementById("ai-suggestion-status");
    if (statusElement) {
      if (Number(remainingCount) > 0) {
        statusElement.innerHTML = `💡 AI提案は <strong class="text-blue-600 font-semibold">あと<span id="ai-suggestion-remaining">${remainingCount}</span>回</strong> 使用できます`;
        console.log('✅ 残り回数を更新しました:', remainingCount);
      } else {
        statusElement.innerHTML = `💡 <strong class="text-red-600 font-semibold">本日のAI提案は利用できません</strong>`;
        console.log('✅ 利用不可メッセージに切り替えました');
      }
    } else {
      console.log('❌ ai-suggestion-status が見つかりませんでした');
    }

    // 追加
    if (resetDateElement) {
      resetDateElement.textContent = resetDateText;
      console.log('✅ リセット日を更新しました:', resetDateText);
    } else {
      console.log('❌ ai-suggestion-reset-date が見つかりませんでした');
    }

    // ★ ローディングを非表示
    this.hideLoading();

    console.log('✅✅✅ すべての処理が完了しました! ✅✅✅');
  }

  showLoading() {
    console.log('✅ showLoading() が呼び出されました');

    // ★★★ 現在の入力内容を保存 ★★★
    const goalTitleField = document.querySelector('input[name="survey_result[goal_title]"]');
    const goalDescriptionField = document.querySelector('textarea[name="survey_result[goal_description]"]');
    const actionPlanField = document.querySelector('textarea[name="survey_result[action_plan]"]');

    this.savedGoalTitle = goalTitleField?.value || "";
    this.savedGoalDescription = goalDescriptionField?.value || "";
    this.savedActionPlan = actionPlanField?.value || "";

    console.log('✅ 入力内容を保存しました:', {
      goalTitle: this.savedGoalTitle,
      goalDescription: this.savedGoalDescription,
      actionPlan: this.savedActionPlan
    });

    // ✅ loading-overlay を探す
    const loadingModal = document.getElementById('loading-overlay');
    if (loadingModal) {
      loadingModal.classList.remove('hidden');
      console.log('✅ ローディングを表示しました');
    } else {
      console.log('❌ loading-overlay が見つかりませんでした');
    }
  }

  hideLoading() {
    console.log('✅ hideLoading() が呼び出されました');

    const loadingModal = document.getElementById('loading-overlay');
    if (loadingModal) {
      loadingModal.classList.add('hidden');
      console.log('✅ ローディングを非表示にしました');
    } else {
      console.log('❌ loading-overlay が見つかりませんでした');
    }
  }

}