# Requirements Document

## Introduction
本仕様は、複数ディスプレイ環境においてウィンドウを異なるディスプレイ間で移動させる機能を定義する。ユーザーはMCPツールを通じて、任意のウィンドウを指定したディスプレイに配置できるようになる。既存のウィンドウ配置機能（position_window）を拡張し、ディスプレイ指定パラメータを追加することで実現する。

## Requirements

### Requirement 1: ディスプレイ指定によるウィンドウ配置
**Objective:** As a 複数ディスプレイを使うユーザー, I want ウィンドウ配置時に配置先のディスプレイを指定できる, so that 任意のディスプレイにウィンドウを自由に配置できる

#### Acceptance Criteria
1. When ユーザーがウィンドウ配置コマンドでディスプレイ名を指定した場合, the position_window tool shall 指定されたディスプレイの座標系に基づいてウィンドウを配置する
2. When ユーザーがウィンドウ配置コマンドでディスプレイ名を省略した場合, the position_window tool shall ウィンドウが現在存在するディスプレイ内での配置を行う
3. If 指定されたディスプレイ名が存在しない場合, the position_window tool shall エラーメッセージを返し配置操作を中止する

### Requirement 2: ディスプレイ情報取得
**Objective:** As a 複数ディスプレイを使うユーザー, I want 接続されているディスプレイの一覧と情報を取得できる, so that 配置先のディスプレイを正しく指定できる

#### Acceptance Criteria
1. The list_displays tool shall 接続されている全ディスプレイの一覧を返す
2. The list_displays tool shall 各ディスプレイについて以下の情報を含める:
   - ディスプレイ名（識別子）
   - 解像度（width, height）
   - 位置（x, y）- グローバル座標系での左上座標
   - メインディスプレイかどうか
3. If ディスプレイが1台のみ接続されている場合, the list_displays tool shall そのディスプレイの情報を単一要素のリストとして返す

### Requirement 3: プリセット配置のディスプレイ対応
**Objective:** As a 複数ディスプレイを使うユーザー, I want プリセット配置（左半分、右半分など）を指定ディスプレイで使用できる, so that 効率的なウィンドウ配置を複数ディスプレイで実現できる

#### Acceptance Criteria
1. When ユーザーがプリセット配置とディスプレイ名を同時に指定した場合, the position_window tool shall 指定ディスプレイの可視領域に基づいてプリセット配置を計算する
2. The position_window tool shall ディスプレイごとのメニューバー・Dock領域を考慮してプリセット配置を計算する
3. When ディスプレイ名のみ指定しプリセットを省略した場合, the position_window tool shall ウィンドウを指定ディスプレイの中央に配置する
