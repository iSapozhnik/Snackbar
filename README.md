# Snackbar Component for Cocoa

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A lightweight and customizable Snackbar component for Cocoa, designed to display brief informative messages to users.

## Features

- Display short messages or notifications to users
- Customizable appearance, including background color, text color, and animation duration
- Support for action buttons and callback handlers
- Easy integration into existing Cocoa projects

## Installation

### Cocoapods

Swift PAckage manager is your friend.


## Usage

### Initialization

Make a theme

```swift
extension SnackbarTheme where Self == DefaultSnackbarTheme {
    static var info: SnackbarTheme { DefaultSnackbarTheme(withStyle: .info) }
    static var alert: SnackbarTheme { DefaultSnackbarTheme(withStyle: .alert) }
    static var warning: SnackbarTheme { DefaultSnackbarTheme(withStyle: .warning) }
    static var success: SnackbarTheme { DefaultSnackbarTheme(withStyle: .success) }
}

struct DefaultSnackbarTheme: SnackbarTheme {
    var style: SnackbarStyle
    
    init(withStyle style: SnackbarStyle) {
        self.style = style
    }

    var textColor: NSColor { .labelColor }
    var backgroundColor: NSColor {
        switch style {
        case .alert:
            return .systemRed
        case .success:
            return .systemGreen
        case .warning:
            return .systemOrange
        case .info:
            return .systemBlue
        }
    }

    var borderColor: NSColor {
        .secondaryLabelColor
    }
}
```

### Displaying a Snackbar

Snackbar with action buttons and icon.

```swift
let theme: SnackbarTheme = .alert
let actions = [
    SnackbarAction(
        title: NSLocalizedString("Remove", comment: ""),
        icon: nil,
        type: .primary,
        action: {}
    ),
    SnackbarAction(
        title: NSLocalizedString("Later", comment: ""),
        icon: nil,
        type: .secondary,
        action: {}
    ),
]
Snackbar.show(
    theme: theme,
    type: .permanent,
    title: NSLocalizedString("Are you sure you want to remove all spaces?", comment: "").text,
    subtitle: NSLocalizedString("You can not undo this action", comment: "").text,
    actions: actions,
    actionsLayout: .horizontal,
    hasActionsSeparator: false,
    icon: NSImage(named: "your_icon"),
    fromWindow: view.window
)
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please refer to the [Contribution Guidelines](CONTRIBUTING.md) for more details.

## Acknowledgments

- [Author Name](https://github.com/authorname) - Thanks for the inspiration!

## Support

For any questions or issues, please [open an issue](https://github.com/your/repository/issues).
