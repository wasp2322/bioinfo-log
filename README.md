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
