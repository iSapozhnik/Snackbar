import Cocoa

public protocol SnackbarTheme {
    var style: SnackbarStyle { get set }
    
    var textColor: NSColor { get }
    var backgroundColor: NSColor { get }
    var borderColor: NSColor { get }
}
