# Research & Design Decisions

---
**Purpose**: MCP Swift SDKを使用したフィジビリティスタディのための技術調査と設計判断の記録

**Usage**: 発見フェーズでの調査結果、アーキテクチャ判断、実装時の参考情報を文書化
---

## Summary

- **Feature**: `mcp-server-feasibility`
- **Discovery Scope**: New Feature（新規プロジェクト - グリーンフィールド）
- **Key Findings**:
    - MCP Swift SDK 0.10.2が利用可能、Swift 6.0+（Xcode 16+）が必須
    - サーバー実装には`Server`クラスとハンドラー登録パターンを使用
    - ツール定義には`Tool`型と`CallTool`ハンドラーが必要
    - StdioTransportが標準入出力通信に最適

## Research Log

### MCP Swift SDK API調査

- **Context**: Swift MCPサーバーの実装可能性とAPI設計の確認
- **Sources Consulted**:
    - [MCP Swift SDK GitHub Repository](https://github.com/modelcontextprotocol/swift-sdk)
    - [MCP Specification 2025-03-26](https://modelcontextprotocol.io/specification/2025-03-26)
- **Findings**:
    - **最新バージョン**: 0.10.2（2024年9月リリース）
    - **Swift要件**: Swift 6.0以上、Xcode 16以上
    - **プラットフォーム**: macOS 13.0以上をサポート
    - **サーバー基本構造**:

    ```swift
    let server = Server(
        name: "MyServer",
        version: "1.0.0",
        capabilities: .init(tools: .init(listChanged: true))
    )
    ```

    - **ツール登録パターン**:
        - `ListTools`ハンドラー: 利用可能なツールのリストを返す
        - `CallTool`ハンドラー: ツール実行リクエストを処理
    - **トランスポート**: `StdioTransport`が標準入出力での通信に対応
    - **型安全性**: すべてのパラメーターと戻り値に明示的な型定義
- **Implications**:
    - ハンドラーベースのアーキテクチャにより、ツールごとの独立した実装が可能
    - `Tool`型の`inputSchema`フィールドでパラメーター検証が可能（今回は不要）
    - async/awaitパターンが全体で使用されており、Swift並行性モデルに準拠

### ツール実装パターン調査

- **Context**: `generate_random_number`ツールの実装方法の確認
- **Sources Consulted**: MCP Swift SDK README - Tools section
- **Findings**:
    - ツールは`Tool`型で定義: `name`, `description`, `inputSchema`
    - `CallTool`ハンドラーで実行ロジックを実装
    - 戻り値は`CallTool.Result`型で、`content`配列と`isError`フラグを含む
    - `content`は`.text()`, `.image()`, `.resource()`などの型を持つ
    - パラメーターなしのツールは`inputSchema`を空のobjectとして定義可能
- **Implications**:
    - 乱数生成は`Int.random(in: 1...10)`で実装可能
    - エラーハンドリングは`isError: true`で対応
    - JSON形式のレスポンスは`.text()`で文字列として返却可能

### Swift Package Manager設定調査

- **Context**: Package.swiftの正しい設定方法の確認
- **Sources Consulted**: MCP Swift SDK README - Installation section
- **Findings**:
    - 依存関係の追加: `swift-sdk`パッケージ、バージョン0.10.0以上
    - プロダクト名: `MCP`
    - ターゲット設定: `executableTarget`として定義
    - プラットフォーム指定: `.platforms([.macOS(.v15)])`
    - swift-tools-version: 5.9以上推奨
- **Implications**:
    - ステアリングで定義されたPackage.swift構造と整合
    - テスト用のQuick/Nimble依存関係は別途testTargetで管理

### エラーハンドリング戦略調査

- **Context**: MCPサーバーのエラー処理パターンの確認
- **Sources Consulted**: MCP Swift SDK README - Error Handling
- **Findings**:
    - `MCPError`型がSDKで提供される
    - サーバー起動エラーはthrowで伝播
    - ツール実行エラーは`CallTool.Result(isError: true)`で返す
    - クライアントへのエラーレスポンスは`content`フィールドで説明
- **Implications**:
    - 起動時エラーは標準エラー出力に記録し、終了コードで示す
    - ツール実行エラーはMCPプロトコルに準拠したエラーレスポンスで返却

### MCP Builder Best Practices調査

- **Context**: ClaudeSkills MCPビルダーのベストプラクティスとパターンの確認
- **Sources Consulted**: [ClaudeSkills MCP Builder](https://claude-plugins.dev/skills/@AutumnsGrove/ClaudeSkills/mcp-builder)
- **Findings**:
    - **ツールスキーマ設計**:
        - 明確でアクション指向の命名（例: `search_customer_by_email`）
        - 包括的な説明文（ツールが何をするか、いつ使うか、何を返すかを明記）
        - JSON Schemaによる入力検証
        - 固定オプションには`enum`を使用
    - **エラーハンドリング**:
        - エラーを分類（ValidationError, AuthenticationErrorなど）
        - 実行可能なエラーメッセージの提供
        - `isError: true`フラグの明示的な使用
        - サイレントな失敗を避ける
    - **セキュリティ考慮事項**:
        - 入力値の常時検証
        - 環境変数でのシークレット管理（ハードコード禁止）
        - URLスキーム検証（HTTP/HTTPSのみ許可など）
    - **パフォーマンス最適化**:
        - 接続プーリングの使用
        - 並列async操作（`asyncio.gather`相当）
        - 逐次実行の回避
    - **共通の落とし穴**:
        - スキーマ検証エラー: 必須パラメーターのチェック漏れ
        - トランスポート設定: 相対パスではなく絶対パスを使用
        - エラー伝播: 説明的なエラーメッセージと`isError`フラグの使用
    - **テストとデバッグ**:
        - MCP Inspector（`npx @modelcontextprotocol/inspector`）の活用
        - ユニットテストと統合テストの分離
- **Implications**:
    - ツール名は`generate_random_number`が適切（アクション指向）
    - 説明文には「何をするか」「何を返すか」を明記
    - パラメーターなしでも`inputSchema`は明示的に定義（空のobject）
    - エラーレスポンスには具体的なメッセージと`isError: true`を含める
    - 環境変数は使用しないが、パターンとして記録
    - Swift版では`Task.detached`や`TaskGroup`で並列処理を実装可能

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Single Executable Server | `@main`エントリポイントから直接サーバー起動 | シンプル、フィジビリティスタディに最適 | 拡張性は限定的 | ステアリングパターンに準拠、MCP Builder推奨 |
| Handler-based Tools | 各ツールをハンドラー関数として実装 | 独立性、テスト容易性 | ツール数が増えると管理が複雑化 | MCP SDK推奨パターン、MCP Builder標準 |
| Protocol-oriented Tools | ツールをプロトコルで抽象化 | 拡張性、再利用性 | オーバーエンジニアリングのリスク | フィジビリティスタディには不要 |

**Selected**: Single Executable Server + Handler-based Tools

- フィジビリティスタディの目的に最適
- MCP SDK公式パターンに準拠
- MCP Builder Best Practicesと整合（Python実装パターンのSwift版）
- 最小限のコードで動作検証が可能

## Design Decisions

### Decision: ハンドラーベースのツール実装

- **Context**: `generate_random_number`ツールの実装アプローチ
- **Alternatives Considered**:
  1. Protocol-oriented design - ツールをプロトコルで抽象化し、各ツールを独立したstructで実装
  2. Handler function approach - ハンドラー関数内で直接実装
  3. Command pattern - ツールをコマンドオブジェクトとして実装
- **Selected Approach**: Handler function approach
- **Rationale**:
    - フィジビリティスタディには最小限の実装が適切
    - MCP Swift SDK公式ドキュメントの推奨パターン
    - 1つのツールのみのため、抽象化のオーバーヘッドは不要
- **Trade-offs**:
    - **Benefits**: コード量最小、理解容易、デバッグ簡単
    - **Compromises**: ツール数が増えた場合のリファクタリングが必要
- **Follow-up**: 将来的なツール追加時にはProtocol-orientedへの移行を検討

### Decision: StdioTransport使用

- **Context**: MCPクライアントとの通信方式の選択
- **Alternatives Considered**:
  1. StdioTransport - 標準入出力
  2. HTTPClientTransport - HTTP/SSE
  3. Custom Transport - 独自実装
- **Selected Approach**: StdioTransport
- **Rationale**:
    - MCPクライアントの標準的な通信方式
    - ローカル実行環境での検証に最適
    - 追加の設定不要
- **Trade-offs**:
    - **Benefits**: シンプル、MCP標準、デバッグ容易
    - **Compromises**: リモート接続は不可（フィジビリティスタディでは問題なし）
- **Follow-up**: 本番環境ではHTTPTransportの検討が必要

### Decision: async/await一貫使用

- **Context**: 非同期処理の実装方法
- **Alternatives Considered**:
  1. async/await - Swift並行性モデル
  2. Completion handlers - 従来のコールバックパターン
  3. Combine - リアクティブプログラミング
- **Selected Approach**: async/await
- **Rationale**:
    - MCP Swift SDKがasync/awaitベース
    - Swift 5以降の標準パターン
    - ステアリングで推奨されている
- **Trade-offs**:
    - **Benefits**: 可読性、エラー処理の明確性、デバッグ容易
    - **Compromises**: Swift 5.5以降が必須（すでに満たしている）
- **Follow-up**: なし

## Risks & Mitigations

- **Risk 1**: MCP Swift SDK 0.10.2の安定性が不明
    - **Mitigation**: フィジビリティスタディのため、既知の問題を記録し、本番環境では最新安定版を使用
- **Risk 2**: 乱数生成のテスト困難性
    - **Mitigation**: 結果の範囲検証（1-10）のみ実施、詳細なテストは本実装時に実施
- **Risk 3**: エラーハンドリングの網羅性不足
    - **Mitigation**: 基本的なエラーケースのみカバー、フィジビリティスタディの目的は達成可能

## References

- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) - 公式Swift SDK
- [MCP Specification 2025-03-26](https://modelcontextprotocol.io/specification/2025-03-26) - プロトコル仕様
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) - Swift並行性ガイド
- [Swift Package Manager](https://swift.org/package-manager/) - SPM公式ドキュメント
- [ClaudeSkills MCP Builder](https://claude-plugins.dev/skills/@AutumnsGrove/ClaudeSkills/mcp-builder) - MCPサーバー実装のベストプラクティス
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector) - MCPサーバーのデバッグツール
