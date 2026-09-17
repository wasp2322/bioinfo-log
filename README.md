# バイオインフォマティクス学習ログ

臨床ゲノム解析（WGS/WES）のパイプライン構築を目指した学習記録。

## 環境
- MacBook Pro (Apple Silicon / macOS)
- Docker Desktop, Miniforge, Nextflow 25.x

## Day 1
- [x] Homebrew / Docker Desktop / Miniforge / Java 17 / Nextflow
- [x] nextflow run hello
- [x] nf-core/sarek -profile test,docker 完走

### ハマった点
- Apple Silicon Macでの環境構築でXcodeライセンス未同意に阻まれる
- Homebrew自体の問題ではなく、Xcodeのライセンス同意が済んでいないだけ
- Homebrew自体はインストールされたが最後の brew update ステップで失敗
- PATHを通して生存確認したあと、--quiet を外してエラー確認を実行
- Nextflowは各プロセスで docker run -v <作業ディレクトリ>:<同じパス> の形でホストのディレクトリをコンテナにマウントするため、これを許可しないとNextflowは一切動かない

