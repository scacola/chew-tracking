import type { Copy } from './types'

export const ja: Copy = {
  locale: 'ja',
  nav: {
    how: '仕組み',
    pricing: 'ベータ版',
    faq: 'FAQ',
    cta: 'ベータ版に登録',
  },
  hero: {
    personaChip: {
      stomach: '早食い',
      diet: '食事ペース',
      checkup: '習慣づくり',
    },
    title: ['気づくと、昼食がすぐ終わっている。', 'AirPodsで、食べる速さを視覚化。'],
    accents: ['AirPods', '視覚化'],
    bodyDesktop: [
      '早食いに気づき、食事のペースを無理なく整える。',
      '毎日2〜3分で続ける、食習慣のセルフケア。',
    ],
    bodyMobile: [
      '早食いに気づき、',
      '食事のペースを無理なく整える。',
      '毎日2〜3分の小さなセルフケア。',
    ],
    primaryCta: 'ベータ版に登録する',
    secondaryCta: '仕組みを見る',
    trustSignals: ['ベータ版', '食事ペースの記録', '精度検証中'],
  },
  problem: {
    title: ['早食いは、', '自分では気づきにくい。'],
    paragraphs: [
      '忙しい昼休み、動画を見ながらのひとりご飯。急いでいるつもりはなくても、食事は思ったより早く終わっていることがあります。',
      '問題は、意志が弱いことではありません。食べる速さを、ふだん見る機会がないことです。',
      '早食いを「責める」のではなく、「少しずつ整える」アプローチです。',
    ],
    clocks: [
      { minutes: 10, target: 20, variant: 'fast', label: 'よくある短い昼食' },
      { minutes: 20, target: 20, variant: 'target', label: 'ゆっくり食べる目安' },
    ],
    evidence: [
      {
        text: '食べる速さは、満腹感に気づくタイミングと関係します。',
        accent: 'まずは自分のペースを知ることから。',
        source: '— 公開研究を参考にしたセルフケア設計',
      },
      {
        text: '食事ペースの変化は、毎日の小さな習慣づくりの手がかりになります。',
        accent: '大きく変える前に、視覚化。',
        source: '— Chew & Calm Coach ベータ版',
      },
    ],
    quotes: [
      { quote: '気づくと、昼食がいつもすぐ終わっています。', label: '佐藤 xx (早食い, 34歳)' },
      { quote: '食べる量だけでなく、速さにも目を向けたい。', label: '中村 xx (食事ペース, 29歳)' },
      { quote: '大きく変える前に、毎日の食べ方から整えたい。', label: '山本 xx (習慣づくり, 43歳)' },
    ],
    closing: '見えない習慣は、責めるより先に、見えるようにする。',
  },
  solution: {
    title: 'AirPodsで記録し、短い振り返りで整える。',
    cards: [
      {
        label: 'AIRPODSで記録',
        header: '1. 記録',
        accent: 'clinical',
        body: ['AirPodsのモーションデータで、食事中の動きを推定します。', 'ボタンを押し続ける必要はありません。'],
        highlight: 'ベータ版では精度を検証中です。',
      },
      {
        label: 'ペースに気づく',
        header: '2. 気づき',
        accent: 'cta',
        body: ['食べる速さやペースの変化を、あとから見返せる形にします。', '自分を責めるためではなく、気づくための記録です。'],
        highlight: '「今日は少し早めでした。次の一口だけ、ゆっくり。」',
      },
      {
        label: '小さく続ける',
        header: '3. 習慣化',
        accent: 'coaching',
        body: ['毎日2〜3分の小さな振り返りで、食事のペースを無理なく整えます。', '数週間で、食べ方を少しずつ整えるセルフケアです。'],
      },
    ],
  },
  demo: {
    label: 'How it works',
    title: ['AirPodsの動きから、', '食事ペースのヒントへ。'],
    body: ['AirPodsのモーションデータから食事中の動きを推定し、', '食べる速さやペースの変化を視覚化します。', 'ベータ版では精度を検証中です。'],
    rows: [
      { time: '12:32:08', label: '食事開始を推定' },
      { time: '12:32:18', label: 'ペース: やや早め' },
      { time: '12:33:42', label: 'ペース: 早め → 平均', emphasis: true },
      { time: '12:39:47', label: '食事終了 (7分39秒)' },
    ],
    finaleLabel: '食事ペース →',
    gaugeLabel: '食事ペース',
    gaugeAria: (score, change) => `食事ペーススコア ${score}, 前回比 ${change > 0 ? '+' : ''}${change}`,
  },
  how: {
    title: ['AirPodsの記録 + 短い振り返り +', 'やさしいセルフケア。'],
    columns: [
      {
        title: '数週間で、食べ方を少しずつ整える',
        items: [
          { label: 'Step 1', text: 'まずは、ふだんの食事ペースを知る。' },
          { label: 'Step 2', text: '食べ始めの一口だけ、少しゆっくり。' },
          { label: 'Step 3', text: '食後に短く振り返り、変化を見る。' },
          { label: 'Step 4', text: '無理なく続く小さな習慣にする。' },
        ],
      },
      {
        title: '対応AirPodsで記録',
        body: ['ヘッドトラッキング対応モデルを対象に、食事中の動きを推定します。', '初期ベータ版はiPhoneと対応AirPodsが対象です。'],
        chips: ['AirPods Pro', 'AirPods 4', 'AirPods Max'],
      },
      {
        title: '自分を責めないコーチング',
        quote: ['今日は少し早めでした。', '次の食事では、最初の一口だけゆっくり。', '小さく整えていきましょう。'],
        quoteFooter: '— コーチカード例',
        body: ['冷たい数字ではなく、次に試せる小さな行動へ。', '評価ではなく、気づきと継続を支えるトーンです。'],
      },
    ],
    closing: '対応AirPodsがあれば、専用デバイスは必要ありません。',
  },
  differentiation: {
    title: ['タイマーでも、カメラでもなく、', 'いつものAirPodsから。'],
    cards: [
      { id: 'c', size: 'lg', accent: 'clinical', title: '食事ペースの視覚化', body: '噛む回数だけを数えるのではなく、食べる速さと変化に気づくための設計です。' },
      { id: 'd', size: 'lg', accent: 'coaching', title: 'セルフケアとして続けやすい', body: '早食いを責めるのではなく、少しずつ整える。毎日2〜3分で続けられる軽さを優先します。' },
      { id: 'b', size: 'sm', accent: 'cta', title: 'ベータ版で検証中', body: '対応AirPodsでどこまで自然に食事ペースを推定できるか、段階的に検証します。' },
      { id: 'e', size: 'sm', accent: 'coaching', title: 'プライバシーに配慮', body: '食事ペースの記録は、まず端末内で扱う設計を前提にします。' },
    ],
    closing: '大きく変える前に、まずは食べる速さを視覚化。',
  },
  trust: {
    title: ['安心して試せるように、', '見えるところから整えています。'],
    cards: [
      {
        status: 'live',
        statusLabel: 'プライバシー',
        title: 'プライバシーに配慮した設計',
        body: ['食事ペースの記録は、まず端末内で扱います。', '明示的な書き出し・匿名化・いつでも削除できる設計を前提にします。'],
      },
      {
        status: 'inProgress',
        statusLabel: '対応確認',
        title: '対応モデルを事前に確認',
        body: ['AirPods Proシリーズ / AirPods 4 / AirPods Maxなど、ヘッドトラッキング対応モデルを対象に検証します。', 'ベータ参加時に、お使いの端末で対応状況を確認します。'],
      },
      {
        status: 'beta',
        statusLabel: 'ベータ版',
        title: 'ベータ版で精度検証中',
        body: ['AirPodsのモーションデータから、どこまで食事ペースを自然に推定できるか検証しています。', '大げさな約束ではなく、検証しながら進めます。'],
      },
    ],
    closing: ['医療の言葉で大きく約束するのではなく、', '食習慣のセルフケアとして、安心して試せる体験をつくります。'],
  },
  pricing: {
    enabled: false,
    title: ['ベータ版は無料で参加できます。', '正式版の料金は、検証後にご案内します。'],
    tiers: [],
    note: [],
    refundNote: '',
  },
  faq: {
    title: 'よくある質問',
    footer: 'そのほかの質問は、ベータ版のご案内時にお知らせします。',
    items: [
      { id: 'q1', q: '医療アプリですか？', a: '医療アプリではなく、食習慣のセルフケアを支援するツールです。体調に不安がある場合は、医療機関にご相談ください。' },
      { id: 'q2', q: 'すべての食事を正確に測れますか？', a: 'いいえ。ベータ版では、AirPodsのモーションデータから食事中の動きを推定しています。姿勢・会話・歩行などの影響を受けるため、精度を検証中です。', highlight: 'trust-core' },
      { id: 'q3', q: 'AirPodsが必要ですか？', a: 'AirPodsのモーションデータを使うため、対応モデルが必要です。AirPods Proシリーズ / AirPods 4 / AirPods Maxなど、ヘッドトラッキング対応モデルを対象に検証します。' },
      { id: 'q4', q: 'データはどこに保存されますか？', a: 'ベータ版では、食事ペースの記録をまず端末内で扱う設計を前提にします。書き出しが必要な場合は、ユーザーが明示的に操作したときだけ行います。', highlight: 'trust-core' },
      { id: 'q5', q: 'AirPodsをつけずに食事した日はどうなりますか？', a: '自動記録は行われません。必要に応じて、あとから簡単なメモとして残せる導線を検討します。' },
      { id: 'q6', q: 'iPhone以外でも使えますか？', a: '初期ベータ版はiPhoneと対応AirPodsを対象にします。Android版は未定です。' },
      { id: 'q7', q: '噛む回数を毎回見る必要がありますか？', a: 'いいえ。目的は回数で自分を責めることではなく、食べるペースに気づくことです。' },
    ],
  },
  finalCta: {
    title: ['気づくと、昼食がすぐ終わっている。', 'まずは食べる速さを視覚化してみませんか。'],
    datePrefix: '',
    letter: ['ベータ版は無料で参加できます。', '正式版の料金は、検証後にご案内します。', '大げさな約束ではなく、検証しながら一緒に進めます。'],
    formCta: 'ベータ版に登録する',
    formPlaceholder: 'メールアドレス',
    formHelper: 'ご案内以外の目的では使用しません。',
  },
  footer: {
    links: [
      { label: '仕組み', target: 'how-it-works' },
      { label: 'FAQ', target: 'faq' },
      { label: '運営者情報', target: '#' },
      { label: 'Privacy', target: '#' },
      { label: 'Terms', target: '#' },
    ],
    formLabel: 'ベータ版の案内を受け取る',
    formCta: '登録',
    formPlaceholder: 'メール',
  },
  form: {
    submitting: '送信中...',
    success: 'ご登録ありがとうございます。ベータ版の案内をお送りします。',
    invalidEmail: 'メールアドレスの形式を確認してください。',
  },
  common: {
    scroll: 'スクロール',
    minute: '分',
  },
}
