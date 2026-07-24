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

  cancel(event) {
    console.log('✅ キャンセルボタンがクリックされました');

    // ★ フラグを立てる
    this.isCancelled = true;

    // ★ ローディングを非表示
    this.hideLoading();

    console.log('✅ ローディングを非表示にしました');
  }

  handleStreamRender(event) {
    console.log('✅✅✅ turbo:before-stream-render イベントを受信しました ✅✅✅');
    console.log('✅ event.detail:', event.detail);
    console.log('✅ event.target:', event.target);

    // ★ キャンセルされていたら何もしない
    if (this.isCancelled) {
      console.log('✅ キャンセルされているため、処理をスキップします');
      event.preventDefault(); // ★ Turbo Streamの処理を止める
      return;
    }

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

  submit(event) {
    event.preventDefault();

    // ★ フラグをリセット
    this.isCancelled = false;

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

}