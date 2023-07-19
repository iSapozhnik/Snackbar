//
//  Snackbar.swift
//  Lasso
//
//  Created by Ivan Sapozhnik on 17.07.23.
//

import Cocoa

public enum SnackbarStyle {
    case alert
    case info
    case warning
    case success
}

public enum SnackbarType {
    case permanent
    case temporary(duration: TimeInterval, showProgress: Bool = true)
}

public enum ActionType {
    case primary
    case secondary
}

public struct Text {
    let text: String
    let font: NSFont?

    public init(text: String, font: NSFont? = nil) {
        self.text = text
        self.font = font
    }    
}

public struct SnackbarAction {
    let title: String?
    let icon: NSImage?
    let type: ActionType
    let action: () -> Void
    
    public init(
        title: String? = nil,
        icon: NSImage? = nil,
        type: ActionType,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.type = type
        self.action = action
    }
}

public enum ActionsLayout {
    case horizontal
    case vertical
}

public struct AnimationStyle {
    let appear: AppearAnimationStyle
    let dissappear: DissappearAnimationStyle
    
    public init(appear: AppearAnimationStyle, dissappear: DissappearAnimationStyle) {
        self.appear = appear
        self.dissappear = dissappear
    }
}

public enum AppearAnimationStyle {
    case fadeIn
    case slideIn
}

public enum DissappearAnimationStyle {
    case fadeOut
    case slideOut
}

private final class WindowDelegate: NSObject, NSWindowDelegate {
    var willClose: ((SnackbarWindow) -> Void)?
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? SnackbarWindow else { return }
        willClose?(window)
    }
}

public enum Snackbar {
    typealias Animation = (() -> Void)
    private static var cache = [SnackbarWindow: Int]()
    private static let windowDelegate = WindowDelegate()
    private static var dissapearItems = [SnackbarWindow: DispatchWorkItem]()

    public static func clear() {
        cache.keys.forEach { $0.close() }
        cache.removeAll()
        dissapearItems.removeAll()
    }
    /**
     Displays a snackbar with the specified configuration.
     
     - Parameters:
         - theme: The theme of the snackbar.
         - type: The type of the snackbar. Default value is `.permanent`.
         - title: The title of the snackbar.
         - subtitle: The optional subtitle of the snackbar. Default value is `nil`.
         - actions: An array of `SnackbarAction` objects representing the actions available in the snackbar.
         - actionsLayout: The layout style for displaying the actions. Default value is `.vertical`.
         - hasActionsSeparator: A boolean value indicating whether the actions should be separated by a separator. Default value is `false`.
         - hasContentSeparator: A boolean value indicating whether the content should be separated by a separator. Default value is `true`.
         - icon: The optional icon image to be displayed in the snackbar. Default value is `nil`.
         - mainWindow: The main window from which the snackbar will be presented.
         - acceptsEqualContent: A boolean value indicating whether the snackbar can display duplicate content. Default value is `true`.
         - cornerRadius: The corner radius of the snackbar. Default value is `Constants.cornerRadius`.
         - padding: The padding value for the snackbar. Default value is `Constants.padding`.
         - bottomOffet: The bottom offset value for the snackbar. Default value is `Constants.bottomOffset`.
         - animationStyle: The animation style for the snackbar appearance and disappearance. Default value is `.init(appear: .slideIn, disappear: .fadeOut)`.

     - Note:
         The `SnackbarAction` objects in the `actions` array represent the actions that can be performed in the snackbar. Each `SnackbarAction` has a title and a closure that will be executed when the action is triggered.

     - Important:
         The `mainWindow` parameter must be provided to ensure the snackbar is presented from the correct window.
*/
    public static func show(
        theme: SnackbarTheme,
        type: SnackbarType = .permanent,
        title: Text,
        subtitle: Text? = nil,
        actions: [SnackbarAction],
        actionsLayout: ActionsLayout = .vertical,
        hasActionsSeparator: Bool = false,
        hasContentSeparator: Bool = true,
        icon: NSImage? = nil,
        fromWindow mainWindow: NSWindow?,
        acceptsEqualContent: Bool = false,
        cornerRadius: CGFloat = Constants.cornerRadius,
        padding: CGFloat = Constants.padding,
        bottomOffet: CGFloat = Constants.bottomOffset,
        animationStyle: AnimationStyle = .init(appear: .slideIn, dissappear: .fadeOut)
    ) {
        guard acceptsEqualContent || !cache.values.contains(title.text.hashValue) else { return }
        guard let mainWindow else { return }

        let parentWindowSize = mainWindow.frame.size
        
        let snackbarView = SnackbarView(
            type: type,
            title: title,
            subtitle: subtitle,
            textColor: theme.textColor,
            borderColor: theme.borderColor,
            backgroundColor: theme.backgroundColor,
            cornerRadius: cornerRadius,
            padding: padding,
            actions: actions,
            actionsLayout: actionsLayout,
            hasActionsSeparator: hasActionsSeparator,
            hasContentSeparator: hasContentSeparator,
            icon: icon
        )

        let toastSize = CGSize(
            width: round(snackbarView.fittingSize.width),
            height: round(snackbarView.fittingSize.height)
        )
        
        let toastOriginX = (mainWindow.frame.origin.x) + (parentWindowSize.width - toastSize.width) / 2
        var toastOriginY = mainWindow.frame.origin.y + bottomOffet
        toastOriginY += Array(cache.keys)
            .map(\.frame.height)
            .reduce(0, +)
        toastOriginY += CGFloat(cache.keys.count) * Constants.spaceBetweenSnacks
        
        let finalRect = NSRect(x: round(toastOriginX), y: round(toastOriginY), width: toastSize.width, height: toastSize.height).insetBy(dx: -1, dy: -1)
    
        let snackbarWindow = SnackbarWindow(snackbarView: snackbarView, index: cache.keys.count)
        snackbarView.onClick = {
            dissapearItems[snackbarWindow]?.cancel()
            dissappearAnimation(withStyle: animationStyle.dissappear, snackbarWindow: snackbarWindow)
        }
        snackbarWindow.onClick = {
            dissapearItems[snackbarWindow]?.cancel()
            dissappearAnimation(withStyle: animationStyle.dissappear, snackbarWindow: snackbarWindow)
        }
        cache[snackbarWindow] = title.text.hashValue
        snackbarWindow.delegate = windowDelegate
        windowDelegate.willClose = { window in
            cache.removeValue(forKey: window)
            layoutExistingSnackbars(relativeTo: window, animate: true)
        }
        mainWindow.addChildWindow(snackbarWindow, ordered: .above)

        appearAnimation(withStyle: animationStyle.appear, snackbarWindow: snackbarWindow, finalRect: finalRect)
        guard case let .temporary(duration, _) = type else { return }
        let item = DispatchWorkItem(block: {
            dissappearAnimation(withStyle: animationStyle.dissappear, snackbarWindow: snackbarWindow)
        })
        dissapearItems[snackbarWindow] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }
    
    private static func appearAnimation(
        withStyle animationStyle: AppearAnimationStyle,
        snackbarWindow: SnackbarWindow,
        finalRect: CGRect
    ) {
        switch animationStyle {
        case .fadeIn:
            fadeIn(snackbarWindow: snackbarWindow, finalRect: finalRect)
        case .slideIn:
            slideIn(snackbarWindow: snackbarWindow, finalRect: finalRect)
        }
    }
    
    private static func dissappearAnimation(
        withStyle animationStyle: DissappearAnimationStyle,
        snackbarWindow: SnackbarWindow
    ) {
        switch animationStyle {
        case .fadeOut:
            fadeOut(snackbarWindow: snackbarWindow)
        case .slideOut:
            slideOut(snackbarWindow: snackbarWindow)
        }
    }
    
    private static func layoutExistingSnackbars(relativeTo window: SnackbarWindow, animate: Bool) {
        cache.keys
            .filter { $0.index >= window.index }
            .forEach { existingWindow in
                existingWindow.index -= 1
                var newFrame = existingWindow.frame
                newFrame.origin.y -= window.frame.height + Constants.spaceBetweenSnacks
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = Constants.animationDuration
                    existingWindow.animator().setFrame(newFrame, display: true, animate: animate)
                }
            }
    }
    
    private static func fadeIn(snackbarWindow: SnackbarWindow, finalRect: CGRect) {
        snackbarWindow.alphaValue = 0.0
        snackbarWindow.setFrame(finalRect, display: false)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Constants.animationDuration
            snackbarWindow.animator().alphaValue = 1.0
        }
    }
    
    private static func fadeOut(snackbarWindow: SnackbarWindow) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.animationDuration
            snackbarWindow.animator().alphaValue = 0.0
        }, completionHandler: {
            snackbarWindow.close()
            dissapearItems.removeValue(forKey: snackbarWindow)
        })
    }
    
    private static func slideIn(snackbarWindow: SnackbarWindow, finalRect: CGRect) {
        snackbarWindow.alphaValue = 0.0

        var initialFrame = finalRect
        initialFrame.origin.y -= snackbarWindow.frame.height
        snackbarWindow.setFrame(initialFrame, display: false)
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Constants.animationDuration
            snackbarWindow.animator().alphaValue = 1.0
            snackbarWindow.animator().setFrame(finalRect, display: true, animate: true)
        }
    }
    
    private static func slideOut(snackbarWindow: SnackbarWindow) {
        var initialFrame = snackbarWindow.frame
        initialFrame.origin.y -= snackbarWindow.frame.height
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.animationDuration
            snackbarWindow.animator().alphaValue = 0.0
            snackbarWindow.animator().setFrame(initialFrame, display: true, animate: true)
        }, completionHandler: {
            snackbarWindow.close()
            dissapearItems.removeValue(forKey: snackbarWindow)
        })
    }
}
