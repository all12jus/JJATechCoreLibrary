//
//  File.swift
//  
//
//  Created by Justin Allen on 8/29/22.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
public class FontAwesomeConverter {
    public static func image(
        fromChar char: String,
        color: UIColor,
        size: CGFloat,
        font_name: String
    ) -> Image {
        let label = UILabel(frame: .zero)
        label.textColor = color
        label.font = UIFont(name: font_name, size: size)
        label.text = char
        label.sizeToFit()
        let renderer = UIGraphicsImageRenderer(size: label.frame.size)
        let image = renderer.image(actions: { context in
            label.layer.render(in: context.cgContext)
        })
        
        let result = Image(uiImage:  image).renderingMode(.template)
        return result
    }
}
