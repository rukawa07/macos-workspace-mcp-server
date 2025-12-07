import AppKit
import ApplicationServices
import Foundation

// MARK: - Protocol Definition

/// ウィンドウ操作サービスのプロトコル
public protocol WindowServiceProtocol: Sendable {
    /// ウィンドウ情報を取得する
    /// - Parameter bundleId: フィルタリング対象のbundle ID（nilで全アプリ）
    /// - Returns: ウィンドウ情報の配列
    /// - Throws: WorkspaceError.permissionDenied（権限なし時）,
    ///           WorkspaceError.applicationNotFound（指定アプリが見つからない場合）
    func listWindows(bundleId: String?) async throws -> [WindowInfo]

    /// Accessibility権限を確認する
    /// - Returns: 権限が付与されているかどうか
    func checkAccessibilityPermission() -> Bool

    /// ウィンドウを指定位置に配置する
    /// - Parameters:
    ///   - bundleId: 対象アプリケーションのbundle ID
    ///   - title: ウィンドウタイトル（オプション、フィルタリング用）
    ///   - preset: 配置プリセット
    ///   - displayName: 配置先ディスプレイ名（オプション）
    /// - Returns: 配置後のウィンドウ情報
    /// - Throws: WorkspaceError
    func positionWindow(
        bundleId: String,
        title: String?,
        preset: WindowPreset,
        displayName: String?
    ) async throws -> PositionResult

    /// ウィンドウを最前面に表示する
    /// - Parameters:
    ///   - bundleId: 対象アプリケーションのbundle ID
    ///   - title: ウィンドウタイトル（オプション、フィルタリング用）
    /// - Returns: フォーカス結果
    /// - Throws: WorkspaceError
    func focusWindow(
        bundleId: String,
        title: String?
    ) async throws -> FocusResult
}

// MARK: - Default Implementation

/// WindowServiceProtocolのデフォルト実装
///
/// Accessibility APIとNSScreenを使用してウィンドウ情報を取得
public final class DefaultWindowService: WindowServiceProtocol, @unchecked Sendable {

    public init() {}

    // MARK: - Permission Check

    /// Accessibility権限を確認する
    public func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - List Windows

    /// ウィンドウ情報を取得する
    public func listWindows(bundleId: String?) async throws -> [WindowInfo] {
        // CGWindowList APIを使用して全デスクトップのウィンドウを取得
        return getWindowsUsingCGWindowList(bundleId: bundleId)
    }

    // MARK: - CGWindowList Implementation

    /// CGWindowList APIを使用してウィンドウ情報を取得
    private func getWindowsUsingCGWindowList(bundleId: String?) -> [WindowInfo] {
        let windowList =
            CGWindowListCopyWindowInfo([.optionOnScreenOnly, .optionAll], kCGNullWindowID)
            as? [[String: Any]]

        guard let windowList = windowList else {
            return []
        }

        var windows: [WindowInfo] = []

        for windowDict in windowList {
            // システムウィンドウのフィルタリング
            guard let layer = windowDict[kCGWindowLayer as String] as? Int,
                layer == 0
            else {
                continue
            }

            // kCGWindowOwnerPIDからbundle IDとアプリ名を解決
            guard let pid = windowDict[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }

            let app = NSRunningApplication(processIdentifier: pid)
            guard let appBundleId = app?.bundleIdentifier,
                let appName = app?.localizedName
            else {
                continue
            }

            // bundleIdフィルタリング
            if let targetBundleId = bundleId, !targetBundleId.isEmpty {
                guard appBundleId == targetBundleId else {
                    continue
                }
            }

            // kCGWindowBoundsからウィンドウの位置・サイズを抽出
            guard let boundsDict = windowDict[kCGWindowBounds as String] as? [String: Any],
                let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else {
                continue
            }

            // ウィンドウタイトルの取得とフォールバック処理
            let title = windowDict[kCGWindowName as String] as? String ?? ""

            // displayNameの設定（ディスプレイ判定）
            let displayName = determineDisplay(
                windowX: bounds.origin.x,
                windowY: bounds.origin.y,
                windowWidth: bounds.size.width,
                windowHeight: bounds.size.height
            )

            // isMinimized/isFullscreenの設定
            // CGWindowListでは最小化・フルスクリーン情報は取得できないため
            // Accessibility権限がある場合のみ取得を試みる
            var isMinimized = false
            var isFullscreen = false

            if checkAccessibilityPermission() {
                // Accessibility APIで状態を取得
                let appElement = AXUIElementCreateApplication(pid)
                if let axWindows = getAXWindows(appElement: appElement) {
                    // タイトルと位置でマッチングして状態を取得
                    for axWindow in axWindows {
                        if matchesWindow(axWindow: axWindow, title: title, bounds: bounds) {
                            isMinimized =
                                getBoolAttribute(
                                    axWindow, attribute: kAXMinimizedAttribute as CFString) ?? false
                            isFullscreen =
                                getBoolAttribute(axWindow, attribute: "AXFullScreen" as CFString)
                                ?? false
                            break
                        }
                    }
                }
            }

            let windowInfo = WindowInfo(
                title: title,
                x: Double(bounds.origin.x),
                y: Double(bounds.origin.y),
                width: Double(bounds.size.width),
                height: Double(bounds.size.height),
                isMinimized: isMinimized,
                isFullscreen: isFullscreen,
                displayName: displayName,
                ownerBundleId: appBundleId,
                ownerName: appName
            )

            windows.append(windowInfo)
        }

        return windows
    }

    /// Accessibility APIでウィンドウ一覧を取得
    private func getAXWindows(appElement: AXUIElement) -> [AXUIElement]? {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success,
            let windows = windowsRef as? [AXUIElement]
        else {
            return nil
        }

        return windows
    }

    /// AXウィンドウがCGウィンドウとマッチするか判定
    private func matchesWindow(axWindow: AXUIElement, title: String, bounds: CGRect) -> Bool {
        // タイトルでマッチング
        let axTitle = getStringAttribute(axWindow, attribute: kAXTitleAttribute as CFString) ?? ""
        if !title.isEmpty && axTitle == title {
            return true
        }

        // 位置とサイズでマッチング
        var positionRef: CFTypeRef?
        var position = CGPoint.zero
        if AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef)
            == .success,
            let positionValue = positionRef
        {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }

        var sizeRef: CFTypeRef?
        var size = CGSize.zero
        if AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef)
            == .success,
            let sizeValue = sizeRef
        {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }

        // 位置とサイズが一致すればマッチング
        let epsilon: CGFloat = 1.0
        return abs(position.x - bounds.origin.x) < epsilon
            && abs(position.y - bounds.origin.y) < epsilon
            && abs(size.width - bounds.size.width) < epsilon
            && abs(size.height - bounds.size.height) < epsilon
    }

    // MARK: - Private Helpers

    /// 文字列属性を取得
    private func getStringAttribute(_ element: AXUIElement, attribute: CFString) -> String? {
        var valueRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &valueRef)
        guard result == .success, let value = valueRef as? String else {
            return nil
        }
        return value
    }

    /// ブール属性を取得
    private func getBoolAttribute(_ element: AXUIElement, attribute: CFString) -> Bool? {
        var valueRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &valueRef)
        guard result == .success, let value = valueRef else {
            return nil
        }
        return (value as? Bool) ?? (value as? NSNumber)?.boolValue
    }

    /// ウィンドウの中心点からディスプレイを判定
    private func determineDisplay(
        windowX: CGFloat, windowY: CGFloat, windowWidth: CGFloat, windowHeight: CGFloat
    ) -> String {
        // ウィンドウの中心点を計算
        let centerX = windowX + windowWidth / 2
        let centerY = windowY + windowHeight / 2
        let centerPoint = CGPoint(x: centerX, y: centerY)

        // 各ディスプレイのフレームをチェック
        for screen in NSScreen.screens {
            if screen.frame.contains(centerPoint) {
                return screen.localizedName
            }
        }

        // 見つからない場合は「Unknown」
        return "Unknown"
    }

    // MARK: - Position Window

    /// ウィンドウを指定位置に配置する
    public func positionWindow(
        bundleId: String,
        title: String?,
        preset: WindowPreset,
        displayName: String?
    ) async throws -> PositionResult {
        // 1. 権限確認
        guard checkAccessibilityPermission() else {
            throw WorkspaceError.permissionDenied
        }

        // 2. 対象ウィンドウの検索
        let (axWindow, windowInfo, pid) = try findTargetWindow(bundleId: bundleId, title: title)

        // 3. 最小化チェック
        if windowInfo.isMinimized {
            throw WorkspaceError.windowMinimized(bundleId: bundleId, title: title)
        }

        // 4. 配置先ディスプレイの決定
        let targetScreen = try determineTargetScreen(
            displayName: displayName,
            windowInfo: windowInfo
        )

        // 5. 座標計算
        let visibleFrame = convertToScreenCoordinates(targetScreen.visibleFrame)
        let targetFrame = PositionCalculator.calculateFrame(
            preset: preset, visibleFrame: visibleFrame)

        // 6. ウィンドウの位置・サイズ変更
        try setWindowFrame(axWindow: axWindow, frame: targetFrame)

        // 7. 配置後にウィンドウを最前面に表示
        try raiseWindow(axWindow: axWindow, bundleId: bundleId)

        // 8. 更新後のウィンドウ情報を取得して返却
        let updatedWindowInfo = try getUpdatedWindowInfo(
            axWindow: axWindow,
            pid: pid,
            bundleId: bundleId
        )

        return PositionResult(
            window: updatedWindowInfo,
            appliedPreset: preset,
            displayName: targetScreen.localizedName
        )
    }

    // MARK: - Position Window Helpers

    /// 対象ウィンドウを検索
    private func findTargetWindow(
        bundleId: String,
        title: String?
    ) throws -> (AXUIElement, WindowInfo, pid_t) {
        // 実行中のアプリケーションを検索
        guard
            let app = NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleId
            ).first
        else {
            throw WorkspaceError.windowNotFound(bundleId: bundleId, title: title)
        }

        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        // AXウィンドウ一覧を取得
        guard let axWindows = getAXWindows(appElement: appElement), !axWindows.isEmpty else {
            throw WorkspaceError.windowNotFound(bundleId: bundleId, title: title)
        }

        // タイトルでフィルタリング（指定がある場合）
        var targetWindow: AXUIElement?
        for axWindow in axWindows {
            let windowTitle =
                getStringAttribute(axWindow, attribute: kAXTitleAttribute as CFString) ?? ""

            if let title = title {
                if windowTitle.contains(title) {
                    targetWindow = axWindow
                    break
                }
            } else {
                // タイトル未指定の場合は最初のウィンドウ（最前面）を使用
                targetWindow = axWindow
                break
            }
        }

        guard let axWindow = targetWindow else {
            throw WorkspaceError.windowNotFound(bundleId: bundleId, title: title)
        }

        // WindowInfo を構築
        let windowInfo = buildWindowInfo(
            axWindow: axWindow,
            pid: pid,
            bundleId: bundleId,
            appName: app.localizedName ?? "Unknown"
        )

        return (axWindow, windowInfo, pid)
    }

    /// ウィンドウ情報を構築
    private func buildWindowInfo(
        axWindow: AXUIElement,
        pid: pid_t,
        bundleId: String,
        appName: String
    ) -> WindowInfo {
        let title = getStringAttribute(axWindow, attribute: kAXTitleAttribute as CFString) ?? ""

        var position = CGPoint.zero
        var positionRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef)
            == .success,
            let positionValue = positionRef
        {
            AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        }

        var size = CGSize.zero
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef)
            == .success,
            let sizeValue = sizeRef
        {
            AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        }

        let isMinimized =
            getBoolAttribute(axWindow, attribute: kAXMinimizedAttribute as CFString) ?? false
        let isFullscreen =
            getBoolAttribute(axWindow, attribute: "AXFullScreen" as CFString) ?? false

        let displayName = determineDisplay(
            windowX: position.x,
            windowY: position.y,
            windowWidth: size.width,
            windowHeight: size.height
        )

        return WindowInfo(
            title: title,
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height),
            isMinimized: isMinimized,
            isFullscreen: isFullscreen,
            displayName: displayName,
            ownerBundleId: bundleId,
            ownerName: appName
        )
    }

    /// 配置先ディスプレイを決定
    private func determineTargetScreen(
        displayName: String?,
        windowInfo: WindowInfo
    ) throws -> NSScreen {
        if let targetName = displayName {
            // 指定されたディスプレイを検索
            for screen in NSScreen.screens {
                if screen.localizedName == targetName {
                    return screen
                }
            }
            throw WorkspaceError.displayNotFound(displayName: targetName)
        } else {
            // ウィンドウの現在位置からディスプレイを特定
            let centerPoint = CGPoint(
                x: windowInfo.x + windowInfo.width / 2,
                y: windowInfo.y + windowInfo.height / 2
            )

            for screen in NSScreen.screens {
                if screen.frame.contains(centerPoint) {
                    return screen
                }
            }

            // 見つからない場合はメインスクリーン
            return NSScreen.main ?? NSScreen.screens.first!
        }
    }

    /// NSScreenのvisibleFrameをスクリーン座標系に変換
    /// (NSScreenはY軸が下から上、CGWindowはY軸が上から下)
    private func convertToScreenCoordinates(_ visibleFrame: CGRect) -> CGRect {
        guard let mainScreen = NSScreen.screens.first else {
            return visibleFrame
        }

        let mainScreenHeight = mainScreen.frame.height
        let y = mainScreenHeight - visibleFrame.origin.y - visibleFrame.height

        return CGRect(
            x: visibleFrame.origin.x,
            y: y,
            width: visibleFrame.width,
            height: visibleFrame.height
        )
    }

    /// ウィンドウのフレームを設定
    private func setWindowFrame(axWindow: AXUIElement, frame: CGRect) throws {
        // サイズ→位置→サイズの順序で設定（ディスプレイ間移動に対応）
        var size = CGSize(width: frame.width, height: frame.height)
        var position = CGPoint(x: frame.origin.x, y: frame.origin.y)

        // 許容するエラーコード:
        // - .success (0): 成功
        // - .actionUnsupported (-25205): アクションがサポートされていない
        // - .notImplemented (-25200): 属性の設定が実装されていない（一部のアプリで発生）
        func isAcceptableResult(_ result: AXError) -> Bool {
            return result == .success || result == .actionUnsupported || result.rawValue == -25200
        }

        // 1. サイズを設定
        guard let sizeValue = AXValueCreate(.cgSize, &size) else {
            throw WorkspaceError.positioningFailed(reason: "Failed to create size value")
        }
        var result = AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
        let sizeChangeSupported = result == .success

        if !isAcceptableResult(result) {
            throw WorkspaceError.positioningFailed(
                reason: "Failed to set size (error: \(result.rawValue))")
        }

        // 2. 位置を設定
        guard let positionValue = AXValueCreate(.cgPoint, &position) else {
            throw WorkspaceError.positioningFailed(reason: "Failed to create position value")
        }
        result = AXUIElementSetAttributeValue(
            axWindow, kAXPositionAttribute as CFString, positionValue)
        if !isAcceptableResult(result) {
            throw WorkspaceError.positioningFailed(
                reason: "Failed to set position (error: \(result.rawValue))")
        }

        // 3. サイズを再設定（ディスプレイ間移動後の調整、サイズ変更がサポートされている場合のみ）
        if sizeChangeSupported {
            result = AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
            if !isAcceptableResult(result) {
                throw WorkspaceError.positioningFailed(
                    reason: "Failed to set final size (error: \(result.rawValue))")
            }
        }
    }

    /// 更新後のウィンドウ情報を取得
    private func getUpdatedWindowInfo(
        axWindow: AXUIElement,
        pid: pid_t,
        bundleId: String
    ) throws -> WindowInfo {
        let app = NSRunningApplication(processIdentifier: pid)
        return buildWindowInfo(
            axWindow: axWindow,
            pid: pid,
            bundleId: bundleId,
            appName: app?.localizedName ?? "Unknown"
        )
    }

    /// ウィンドウを最前面に表示（内部ヘルパー）
    private func raiseWindow(axWindow: AXUIElement, bundleId: String) throws {
        // アプリケーションをアクティブ化
        guard
            let app = NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleId
            ).first
        else {
            throw WorkspaceError.applicationNotFound(bundleId: bundleId)
        }

        app.activate()

        // ウィンドウを最前面に表示
        let raiseResult = AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        if raiseResult != .success && raiseResult != .actionUnsupported {
            // kAXRaiseActionがサポートされていない場合は警告するが、エラーにはしない
            // アプリのアクティブ化だけでも効果がある場合がある
        }
    }

    // MARK: - Focus Window

    /// ウィンドウを最前面に表示する
    public func focusWindow(
        bundleId: String,
        title: String?
    ) async throws -> FocusResult {
        // 1. 権限確認
        guard checkAccessibilityPermission() else {
            throw WorkspaceError.permissionDenied
        }

        // 2. 対象ウィンドウの検索
        let (axWindow, windowInfo, pid) = try findTargetWindow(bundleId: bundleId, title: title)

        // 3. 最小化されている場合は解除
        if windowInfo.isMinimized {
            var minimized = false
            guard let minimizedValue = AXValueCreate(.cgPoint, &minimized) else {
                throw WorkspaceError.focusFailed(reason: "Failed to create minimized value")
            }
            let result = AXUIElementSetAttributeValue(
                axWindow,
                kAXMinimizedAttribute as CFString,
                minimizedValue
            )
            if result != .success && result != .actionUnsupported {
                throw WorkspaceError.focusFailed(
                    reason: "Failed to unminimize window (error: \(result.rawValue))")
            }
        }

        // 4. ウィンドウを最前面に表示
        try raiseWindow(axWindow: axWindow, bundleId: bundleId)

        // 5. 更新後のウィンドウ情報を取得
        let updatedWindowInfo = try getUpdatedWindowInfo(
            axWindow: axWindow,
            pid: pid,
            bundleId: bundleId
        )

        return FocusResult(window: updatedWindowInfo)
    }
}
