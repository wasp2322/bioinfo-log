# バイオインフォマティクス学習ログ

臨床ゲノム解析（WGS/WES）のパイプライン構築を目指した学習記録。
公開データ（GIAB, 1000 Genomes）のみを使用し、患者由来データは一切扱わない。

## 環境
- MacBook Pro (Apple Silicon / macOS)
- Docker Desktop / Miniforge (conda, mamba) / Temurin JDK 17 / Nextflow 25.x

## Day 1 — 2026-09-17
- [x] Homebrew / Docker Desktop / Miniforge / JDK 17 / Nextflow のセットアップ
- [x] `nextflow run hello` 完走
- [x] `nf-core/sarek -r 3.10.0 -profile test,docker` 完走
- [x] MultiQC レポートを確認

### ハマった点

#### 1. Homebrew インストールが Xcode ライセンス未同意で中断
`You have not agreed to the Xcode license.` で停止。
→ `sudo xcodebuild -license` を実行し、スペースキーで本文を末尾までスクロール後、
`agree` とフルスペル入力する（`y` / `yes` では通らない）。

#### 2. Homebrew 本体は入ったが `brew update --force --quiet` で失敗
`Failed during: /opt/homebrew/bin/brew update --force --quiet` と表示されるが、
本体は `/opt/homebrew` に設置済みだった。`--quiet` を外して `brew update --force` を
再実行したところ `Already up-to-date.` で、一時的な失敗と判明。
→ 教訓：インストーラの最終ステップで落ちても、まず `brew --version` で本体の生存を確認する。
`--quiet` は原因を隠すので外して再実行する。

#### 3. Apple Silicon では Rosetta 設定が必須
Docker Desktop → Settings → General →
`Use Rosetta for x86/amd64 emulation on Apple Silicon` を有効化する。
バイオインフォ系のコンテナは大半が amd64 向けにしかビルドされておらず、
未設定だとパイプライン実行中に原因の分かりにくいエラーで停止する。
併せて `~/.nextflow/config` に以下を追加した。
docker.runOptions = '--platform=linux/amd64'


#### 4. Miniforge インストーラの初期化プロンプトの既定値が `no`
`Proceed with initialization? [yes|no]` で Enter だけ押すと `[no]` が採用され、
`conda` / `mamba` が PATH に入らない。
→ `yes` とフルスペルで入力する。

#### 5. Docker のホームディレクトリ共有警告がプロセスごとに表示される
Nextflow はプロセスごとに独立した `docker run` を発行するため、
`You have opted to share your home directory with a container` が繰り返し出る。
→ Docker Desktop の設定で当該通知を無効化する。
または作業ディレクトリをホーム配下の外（例：`/opt/bioinfo`）に置き、
Settings → Resources → File sharing に追加する。

#### 6. GitHub への push が `Invalid username or token` で失敗
Fine-grained token の `Only select repositories` に対象リポジトリが出てこなかった。
原因は GitHub 側にリポジトリを作成していなかったこと。
`git remote add` はローカルに送信先を記録するだけで、リモートのリポジトリは作られない。
→ 先に GitHub 上でリポジトリを作成してから、トークンのスコープに追加する。
または `gh repo create <name> --public --source=. --push` で一括処理する方が早い。

## 次の予定
- GIAB HG002 (chr21) を用いた FASTQ → BAM → VCF の手動実行
- `hap.py` によるベンチマーク（recall / precision の測定）

## Day 2 — GIAB HG002 を用いた手動パイプラインとベンチマーク
対象: GRCh38 chr21:14,000,000-24,000,000（約10 Mb）、約30x に間引き
FASTQ → bwa mem → samtools sort → GATK MarkDuplicates
→ GATK HaplotypeCaller → VariantFiltration → rtg vcfeval

### 結果（GIAB v4.2.1 信頼領域内、PASS コール）

| | Precision | Sensitivity | F-measure | FP | FN |
|---|---|---|---|---|---|
| SNP | 0.9995 | 0.9905 | 0.9950 | 7 | 132 |
| INDEL | 0.9933 | 0.9776 | 0.9854 | 16 | 54 |

### 考察
- フィルタ前の INDEL 数（3,644）は SNP の約24%と、ゲノム全体の目安（約15%）より多かった。
  偽陽性過多を疑ったが、信頼領域内の INDEL precision は 99.3% で偽陽性は少なかった。
  評価対象になった INDEL は約2,370件で、残り約1,200件は GIAB の信頼領域外
  （反復配列・セントロメア近傍など）にあり、本ベンチマークでは正誤を判定できない。
- 上記の数値は「信頼領域内・10 Mb 窓」での成績であり、全ゲノムの精度を示すものではない。
- 重複率は 0.23% と低く出たが、1/10 ダウンサンプリング後の値であり、
  重複ペアの両方が残る確率が約1%に下がるため過小評価されている。
  ライブラリ品質の指標としては使えない（QC は間引き前に取るべき）。

### 今回の簡略化・限界
- リファレンスを chr21 のみに限定（他領域由来リードの誤マップを許容する学習上の割り切り）
- 元データは novoalign + decoy 入り GRCh38（`GRCh38_full_plus_hs38d1_analysis_set_minus_alts`）、
  再解析は bwa + GIAB no_alt analysis set の chr21 のみ。再アライメントで 0.3% がアンマップに
- BQSR 未実施
- ハードフィルタは SNP / INDEL を分離せず単一閾値
- 複数ライブラリ由来のリードを単一の LB に統合（MarkDuplicates の判定に影響しうる）
- Apple Silicon のため bwa-mem2 ではなく bwa を使用（Rosetta は AVX 非対応）

### ハマった点
- ターミナルが bash だったため、`~/.zshrc` に書いた PATH が読まれず `nextflow: command not found`。
  `chsh -s /bin/zsh` で zsh に統一し、`conda init zsh` で conda を再初期化
- 別タブは作業ディレクトリと conda 環境を引き継がない。
  タブを開いたら `conda activate wgs && cd ~/bioinfo/day2` を最初に実行する
- リモート BAM の領域抽出サイズを事前に見積もれなかった（300x × 10 Mb で約 1.8 GB）
- リモート BAM から抽出したファイルは `samtools quickcheck` で完全性を確認する
