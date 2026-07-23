import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "form"]

  connect() {
    console.log('Loading controller connected');

    // ★ 既存のイベントリスナーを解除
    if (this.handleStreamRenderBound) {
      document.removeEventListener('turbo:before-stream-render', this.handleStreamRenderBound);
    }

    // ★ 新しいイベントリスナーを登録
    this.handleStreamRenderBound = this.handleStreamRender.bind(this);
    document.addEventListener('turbo:before-stream-render', this.handleStreamRenderBound);

    console.log('✅ turbo:before-stream-render イベントリスナーを登録しました');
  }

  disconnect() {
    // ★ イベントリスナーを解除
    if (this.handleStreamRenderBound) {
      document.removeEventListener('turbo:before-stream-render', this.handleStreamRenderBound);
      console.log('✅ turbo:before-stream-render イベントリスナーを解除しました');
    }
  }

  handleStreamRender(event) {
    console.log('✅✅✅ turbo:before-stream-render イベントを受信しました ✅✅✅');
    console.log('✅ event.detail:', event.detail);
    console.log('✅ event.target:', event.target);

    // ★ Turbo Stream の内容を取得
    const streamElement = event.target;

    // ★ ai_suggestion_form フレームが更新されるか確認
    const targetId = streamElement.getAttribute('target');
    console.log('✅ target ID:', targetId);

    if (targetId === 'ai_suggestion_form') {
      console.log('✅ ai_suggestion_form フレームが更新されます');

      // ★ 少し遅延させてからデータを取得（DOMの更新を待つ）
      setTimeout(() => {
        const dataElement = document.getElementById('ai-suggestion-data');
        if (dataElement) {
          console.log('✅ ai-suggestion-data を発見しました');
          console.log('✅ dataElement.dataset:', dataElement.dataset);

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
      }, 100); // ★ 100ms 遅延
    } else {
      console.log('ℹ️ 他のフレームが更新されました:', targetId);
    }
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

    console.log('✅ 取得したデータ:');
    console.log('  goalTitle:', goalTitle);
    console.log('  goalDescription:', goalDescription ? '(データあり)' : '(データなし)');
    console.log('  actionPlan:', actionPlan ? '(データあり)' : '(データなし)');
    console.log('  remainingCount:', remainingCount);

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
    const remainingElement = document.getElementById('ai-suggestion-remaining');

    console.log('✅ フォーム要素の取得結果:');
    console.log('  titleElement:', titleElement);
    console.log('  descriptionElement:', descriptionElement);
    console.log('  actionPlanElement:', actionPlanElement);
    console.log('  remainingElement:', remainingElement);

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

    if (remainingElement) {
      remainingElement.textContent = remainingCount;
      console.log('✅ 残り回数を更新しました:', remainingCount);
    }

    // ★ ローディングを非表示
    this.hideLoading();

    console.log('✅✅✅ すべての処理が完了しました! ✅✅✅');
  }

  showLoading() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden');
    }
  }

  hideLoading() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden');
    }
  }

  submit(event) {
    event.preventDefault();
    console.log('✅ 送信ボタンがクリックされました');

    // ★ 現在のフォームの内容を保存
    this.previousValues = {
      title: document.getElementById('survey_result_goal_title')?.value || '',
      description: document.getElementById('survey_result_goal_description')?.value || '',
      actionPlan: document.getElementById('survey_result_action_plan')?.value || ''
    };

    console.log('✅ 現在の値を保存しました:', this.previousValues);

    this.showLoading();
    this.formTarget.submit();
  }

  // ★ AI提案ボタン用のメソッドを追加
  submitAi(event) {
    event.preventDefault();
    console.log('✅ AI提案ボタンがクリックされました!');

    // ★ 現在のフォームの内容を保存
    this.previousValues = {
      title: document.getElementById('survey_result_goal_title')?.value || '',
      description: document.getElementById('survey_result_goal_description')?.value || '',
      actionPlan: document.getElementById('survey_result_action_plan')?.value || ''
    };

    console.log('✅ 現在の値を保存しました:', this.previousValues);

    this.showLoading();

    // ★ 別のエンドポイントに送信
    fetch('/survey_profiles/fetch_ai_suggestions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        // 必要なデータをここに追加
        platform: document.querySelector('select[name="survey_profile[platform]"]')?.value,
        genre: document.querySelector('select[name="survey_profile[genre]"]')?.value,
        experience: document.querySelector('select[name="survey_profile[experience]"]')?.value
      })
    })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.text();
      })
      .then(html => {
        // Turbo Streams のレスポンスを処理
        Turbo.renderStreamMessage(html);
      })
      .catch(error => {
        console.error('Error:', error);
        this.hideLoading();
        alert('エラーが発生しました。もう一度お試しください。');
      });
  }

  cancel(event) {
    event.preventDefault();
    console.log('✅ キャンセルボタンがクリックされました!');

    // ★ 保存しておいた内容を復元
    if (this.previousValues) {
      const titleElement = document.getElementById('survey_result_goal_title');
      const descriptionElement = document.getElementById('survey_result_goal_description');
      const actionPlanElement = document.getElementById('survey_result_action_plan');

      if (titleElement) {
        titleElement.value = this.previousValues.title;
        console.log('✅ タイトルを復元しました:', this.previousValues.title);
      }

      if (descriptionElement) {
        descriptionElement.value = this.previousValues.description;
        console.log('✅ 説明を復元しました');
      }

      if (actionPlanElement) {
        actionPlanElement.value = this.previousValues.actionPlan;
        console.log('✅ アクションプランを復元しました');
      }

      console.log('✅ すべてのフォーム内容を復元しました!');
    } else {
      console.log('⚠️ 保存されたデータがありません');
    }

    // ★ ローディングオーバーレイを非表示にする
    this.hideLoading();

    console.log('✅ キャンセル処理が完了しました!');
  }
}
