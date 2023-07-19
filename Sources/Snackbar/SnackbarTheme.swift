//
//  SnackbarTheme.swift
//  NSColorTest
//
//  Created by Ivan Sapozhnik on 19.07.23.
//

import Cocoa

public protocol SnackbarTheme {
    var style: SnackbarStyle { get set }
    
    var textColor: NSColor { get }
    var backgroundColor: NSColor { get }
    var borderColor: NSColor { get }
}
