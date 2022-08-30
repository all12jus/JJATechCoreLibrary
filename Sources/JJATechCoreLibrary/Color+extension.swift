//
//  File.swift
//  
//
//  Created by Justin Allen on 8/29/22.
//

import Foundation
import SwiftUI

@available(iOS 14.0, *)
public extension Color {

    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    static let label = Color(UIColor.label)
    #endif
    
    var uiColor: UIColor? {
        self.cgColor.map({ UIColor(cgColor: $0) })
    }
}
