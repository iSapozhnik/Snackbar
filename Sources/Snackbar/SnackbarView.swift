//
//  SnackbarView.swift
//  NSColorTest
//
//  Created by Ivan Sapozhnik on 19.07.23.
//

import Cocoa

final class SnackbarView: NSBox {
    var onClick: (() -> Void)?

    private lazy var countDownLabel: NSTextField = {
        let countdownDuration: Int
        if case let .temporary(duration, _) = type {
            countdownDuration = Int(duration)
        } else {
            countdownDuration = 0
        }
        
        let countDownLabel = NSTextField(labelWithString: String(countdownDuration))
        countDownLabel.alignment = .center
        countDownLabel.translatesAutoresizingMaskIntoConstraints = false
        countDownLabel.widthAnchor.constraint(equalToConstant: Constants.countDoawnWidth).isActive = true
        countDownLabel.isSelectable = false
        countDownLabel.textColor = NSColor.secondaryLabelColor
        return countDownLabel
    }()

    private let type: SnackbarType
    private let titleText: Text
    private let subtitleText: Text?
    private let textColor: NSColor
    private let icon: NSImage?
    private let padding: CGFloat
    private var timer: Timer?
    private let actions: [SnackbarAction]
    private let actionsLayout: ActionsLayout
    private let hasActionsSeparator: Bool
    private let hasContentSeparator: Bool
    
    private var counter: Int = 0
    
    init(
        type: SnackbarType,
        title: Text,
        subtitle: Text?,
        textColor: NSColor,
        borderColor: NSColor,
        backgroundColor: NSColor,
        cornerRadius: CGFloat,
        padding: CGFloat,
        actions: [SnackbarAction],
        actionsLayout: ActionsLayout,
        hasActionsSeparator: Bool,
        hasContentSeparator: Bool,
        icon: NSImage?
    ) {
        self.type = type
        self.titleText = title
        self.subtitleText = subtitle
        self.textColor = textColor
        self.padding = padding
        self.actions = actions
        self.actionsLayout = actionsLayout
        self.hasActionsSeparator = hasActionsSeparator
        self.hasContentSeparator = hasContentSeparator
        self.icon = icon
        super.init(frame: .zero)
        fillColor = backgroundColor
        self.borderColor = borderColor
        boxType = .custom
        self.cornerRadius = cornerRadius
        contentViewMargins = .zero
        configureView()
        setupTimer()
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTimer() {
        guard case let .temporary(duration, _) = type else { return }
        counter = Int(duration)
        timer?.invalidate()
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCountDown), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func configureView() {
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        
        let addSeparator = {
            let separator = NSBox()
            separator.boxType = .separator
            stackView.addArrangedSubview(separator)
        }
        
        if case let .temporary(_, showProgress) = type, showProgress == true {
            stackView.addArrangedSubview(countDownLabel)
        }
        
        if let icon {
            let imageView = NSImageView(image: icon)
            imageView.imageScaling = .scaleNone
            imageView.setContentCompressionResistancePriority(.required, for: .vertical)
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            stackView.addArrangedSubview(imageView)
            if hasContentSeparator { addSeparator() }
        }
        
        let textStackView = NSStackView()
        textStackView.spacing = Constants.spaceBetweenTitleAndSubtitle
        textStackView.alignment = .leading
        textStackView.orientation = .vertical
        
        let titleLabel = NSTextField(labelWithString: titleText.text)
        titleLabel.font = titleText.font ?? Constants.titleFont
        titleLabel.isSelectable = false
        titleLabel.textColor = textColor
        textStackView.addArrangedSubview(titleLabel)
        
        if let subtitleText {
            let subtitleLabel = NSTextField(labelWithString: subtitleText.text)
            subtitleLabel.font = subtitleText.font ?? Constants.subtitleFont
            subtitleLabel.isSelectable = false
            subtitleLabel.textColor = .secondaryLabelColor // TODO: Color
            textStackView.addArrangedSubview(subtitleLabel)
        }
        
        stackView.addArrangedSubview(textStackView)
        
        if !actions.isEmpty {
            if hasContentSeparator { addSeparator() }

            let actionsStackView = NSStackView()
            switch actionsLayout {
            case .horizontal:
                actionsStackView.orientation = .horizontal
            case .vertical:
                actionsStackView.orientation = .vertical
            }
            for (index, action) in actions.enumerated() {
                let button = NSButton(title: action.title ?? "", target: self, action: #selector(onButton(_:)))
                button.tag = index
                button.alignment = .center
                button.contentTintColor = action.type == .primary ? textColor : .secondaryLabelColor
                button.font = NSFont.systemFont(ofSize: 14, weight: action.type == .primary ? .semibold : .regular)
                
                if let icon = action.icon {
                    button.imagePosition = .imageTrailing
                    button.image = icon
                    button.imageScaling = .scaleProportionallyDown
                }
                button.isBordered = false
                actionsStackView.addArrangedSubview(button)
                
                if index != actions.count - 1, hasActionsSeparator {
                    let separator = NSBox()
                    separator.boxType = .separator
                    actionsStackView.addArrangedSubview(separator)
                }
            }
            stackView.addArrangedSubview(actionsStackView)
        }

        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
        ])
    }
    
    @objc private func updateCountDown() {
        counter -= 1
        countDownLabel.stringValue = String(counter)
    }
    
    @objc
    private func onButton(_ sender: NSButton) {
        onClick?()
        guard
            actions.indices.contains(sender.tag)
        else { return }
        let action = actions[sender.tag]
        action.action()
    }
}
