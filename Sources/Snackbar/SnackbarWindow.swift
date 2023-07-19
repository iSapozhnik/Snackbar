import Cocoa

final class SnackbarWindow: NSWindow {
    var index: Int
    let snackbarView: SnackbarView
    var onClick: (() -> Void)?
    
    init(
        snackbarView: SnackbarView,
        index: Int
    ) {
        self.snackbarView = snackbarView
        self.index = index
        
        super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        configureWindow()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func contentRect(forFrameRect frameRect: NSRect) -> NSRect {
        frameRect
    }
    
    override func mouseDown(with _: NSEvent) {
//        close()
        onClick?()
    }
    
    private func configureWindow() {
        backgroundColor = .clear
        isOpaque = false
        level = .floating
        ignoresMouseEvents = false
        hasShadow = true
        isReleasedWhenClosed = false
        
        let content = NSView(frame: frame)
        content.wantsLayer = true
        content.layer?.backgroundColor = .clear
        
        content.addSubview(snackbarView)
        snackbarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            snackbarView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            snackbarView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            snackbarView.topAnchor.constraint(equalTo: content.topAnchor),
            snackbarView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        contentView = content
    }
}
