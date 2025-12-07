# Implementation Plan

## Tasks

- [x] 1. ディスプレイ情報を表現するデータモデルの作成
- [x] 1.1 (P) ディスプレイ情報モデルを作成する
    - ディスプレイ名、解像度、位置、可視領域、メインディスプレイフラグを持つ構造体を定義
    - Sendable、Codableに準拠させてJSON出力に対応
    - Core Graphics座標系（左上原点、Y軸下向き）で位置情報を表現
    - _Requirements: 2.2_

- [x] 1.2 (P) ディスプレイ一覧レスポンスモデルを作成する
    - ディスプレイ情報の配列をラップするレスポンス構造体を定義
    - 既存のレスポンスモデル（WindowListResponse等）と同じパターンに従う
    - _Requirements: 2.1_

- [x] 2. 中央配置プリセットの追加
- [x] 2.1 (P) ウィンドウ配置プリセットに中央配置を追加する
    - WindowPreset列挙型にcenterケースを追加
    - 既存のプリセット（left, right, fullscreen等）と同じパターンで定義
    - _Requirements: 3.3_

- [x] 2.2 中央配置の座標計算ロジックを実装する
    - PositionCalculatorにcenterプリセット用の計算を追加
    - 可視領域の中央にウィンドウを配置する座標を計算
    - デフォルトのウィンドウサイズ（可視領域の60%程度）を使用
    - _Requirements: 3.3_

- [x] 3. ディスプレイ情報取得サービスの実装
- [x] 3.1 ディスプレイ情報取得のプロトコルと実装を作成する
    - DisplayServiceProtocolを定義しlistDisplaysメソッドを宣言
    - DefaultDisplayServiceでNSScreen APIを使用して全ディスプレイ情報を取得
    - NSScreen座標系からCore Graphics座標系への変換を実装
    - 単一ディスプレイ環境でも正常に動作することを確認
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 4. ディスプレイ一覧取得ツールの実装
- [x] 4.1 ListDisplaysToolを実装する
    - MCPToolプロトコルに準拠したツール構造体を作成
    - ツール定義（name、description、inputSchema）を設定
    - DisplayServiceを呼び出してディスプレイ一覧を取得しJSON形式で返却
    - パラメータなしのシンプルなツールとして実装
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 5. システム統合と動作検証
- [x] 5.1 ツールレジストリへの登録と接続確認
    - ListDisplaysToolをToolRegistryに登録
    - handleListToolsとhandleCallToolでの適切なルーティングを実装
    - PositionWindowToolのinputSchemaにcenterプリセットを追加
    - _Requirements: 2.1, 3.3_

- [x] 5.2 ユニットテストの作成
    - DisplayInfoのエンコード・デコードテスト
    - PositionCalculatorのcenterプリセット計算テスト
    - DisplayServiceが少なくとも1つのディスプレイを返すことのテスト
    - ListDisplaysToolがJSON形式でレスポンスを返すことのテスト
    - _Requirements: 2.1, 2.2, 2.3, 3.3_

## Requirements Coverage

| Requirement | Tasks | Status |
|-------------|-------|--------|
| 1.1 | - | 実装済み |
| 1.2 | - | 実装済み |
| 1.3 | - | 実装済み |
| 2.1 | 1.2, 3.1, 4.1, 5.1, 5.2 | 新規実装 |
| 2.2 | 1.1, 3.1, 4.1, 5.2 | 新規実装 |
| 2.3 | 3.1, 4.1 | 新規実装 |
| 3.1 | - | 実装済み |
| 3.2 | - | 実装済み |
| 3.3 | 2.1, 2.2, 5.1, 5.2 | 新規実装 |
