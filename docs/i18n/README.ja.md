<p align="center"><img src="../images/banner.png" alt="Dockyard" width="100%"></p>

<p align="center">
<a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/-English-2dd4bf?style=flat-square"></a>
<a href="README.vi.md"><img alt="Tiếng Việt" src="https://img.shields.io/badge/-Ti%E1%BA%BFng%20Vi%E1%BB%87t-2dd4bf?style=flat-square"></a>
<a href="README.es.md"><img alt="Español" src="https://img.shields.io/badge/-Espa%C3%B1ol-2dd4bf?style=flat-square"></a>
<a href="README.fr.md"><img alt="Français" src="https://img.shields.io/badge/-Fran%C3%A7ais-2dd4bf?style=flat-square"></a>
<a href="README.de.md"><img alt="Deutsch" src="https://img.shields.io/badge/-Deutsch-2dd4bf?style=flat-square"></a>
<a href="README.pt-BR.md"><img alt="Português (Brasil)" src="https://img.shields.io/badge/-Portugu%C3%AAs%20(Brasil)-2dd4bf?style=flat-square"></a>
<a href="README.ru.md"><img alt="Русский" src="https://img.shields.io/badge/-%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9-2dd4bf?style=flat-square"></a>
<a href="README.ja.md"><img alt="日本語" src="https://img.shields.io/badge/-%E6%97%A5%E6%9C%AC%E8%AA%9E-4b5b70?style=flat-square"></a>
<a href="README.zh-CN.md"><img alt="简体中文" src="https://img.shields.io/badge/-%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-2dd4bf?style=flat-square"></a>
</p>

<h1 align="center">Dockyard</h1>
<p align="center"><b>すべてのコンテナーを整然と。</b><br>速くて美しい<b>Docker / Podman 向け KDE Plasma 6 ウィジェット</b>。コンテナー、イメージ、ボリューム、ログをパネルから監視・管理できます。Fedora KDE 向けに作られています。</p>

<p align="center"><a href="https://phuonghx.github.io/dockyard/"><b>ウェブサイト</b></a> · <a href="#インストール">インストール</a> · <a href="../../CONTRIBUTING.md">貢献</a></p>

<p align="center"><img src="../images/hero.png" alt="Dockyard" width="900"></p>

## Dockyard の特長
- **ひと目で把握:** *マニフェストストリップ* が全コンテナーを1列のセルとして描きます（1コンテナー＝1セル、状態で色分け）。セルをクリックするとそのコンテナーへジャンプします。
- **異常にすぐ気づく:** unhealthy、再起動ループ、クラッシュしたコンテナーを強調し、デスクトップ通知も送ります。
- **よく使う操作をワンクリックで:** 開始、停止、再起動、一時停止、ログ表示、シェル、ポートをブラウザーで開く。
- **Fedora KDE にネイティブ:** Plasma の配色とフォントサイズに従い、Docker、rootless Docker、Podman に対応。必要なのは Python だけです。

## インストール
```bash
git clone https://github.com/phuonghx/dockyard
cd dockyard
./install.sh --restart
```
その後、**パネルを右クリック → ウィジェットを追加 → Dockyard**。先に試すには `plasmawindowed io.dockyard.widget`。

> **Docker に接続できない場合:** グループに追加してログインし直してください: `sudo usermod -aG docker $USER`。Podman は `systemctl --user enable --now podman.socket`。

## クイックツアー
1. **概要:** 実行中すべての CPU とメモリ（履歴付き）、マニフェストストリップ、*実行中 / 要注意 / 停止中 / 一時停止中* のフィルター。コンテナーは Compose プロジェクトごとにグループ化されます。
2. **コンテナー1つ:** 行をクリックすると CPU、メモリ、ネットワーク、ポート、マウントを表示。**ログ**、**シェル**、**再起動**、**一時停止**、**強制停止**、**削除** が使えます。破壊的な操作は2段階で確認します。
3. **イメージ・ボリューム・ネットワーク:** *使用中* / *未使用* のバッジと「未使用のみ」フィルター付き。
4. **空き容量を確保:** 確認の前に、各クリーンアップが何を削除し、どれだけ空くかを表示。名前付きボリュームには触れません。
5. **問題が起きたとき:** スタックトレースではなく、分かりやすい言葉と正確な対処法を表示します。

<p align="center"><img src="../images/overview-dark.png" width="300" alt="Dockyard"> <img src="../images/overview-light.png" width="300" alt="Dockyard"></p>

## 言語
ポップアップの 🌐 ボタンで言語を選べます。**自動** にするとシステムの言語に従います。*Dockyard を設定* からも変更できます。言語を追加するには [CONTRIBUTING](../../CONTRIBUTING.md#translating) の *Translating* を参照してください。ファイル1つで、プログラミングは不要です。

## 貢献
[CONTRIBUTING.md](../../CONTRIBUTING.md) をお読みください。貢献者は [CLA](../../CLA.md) に同意し、[行動規範](../../CODE_OF_CONDUCT.md) に従います。ライセンスは [MIT](../../LICENSE)。

## 作者
**Xuan-Phuong Hoang** · [GitHub @phuonghx](https://github.com/phuonghx) · phuonghx.me@gmail.com · [Facebook](https://facebook.com/phuonghx.me) · [X @phuonghx_](https://x.com/phuonghx_) · WhatsApp @phuonghx.me
