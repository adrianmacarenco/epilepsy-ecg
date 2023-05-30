//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 30/04/2023.
//

import UIKit

public extension UIFont {
    class func sfProRegular(withSize size: CGFloat, shouldScale: Bool = true) -> UIFont {
      
        let font = UIFont(name: "SFProDisplay-Regular", size: size)!
        if shouldScale {
            return UIFontMetrics.default.scaledFont(for: font)
        } else {
            return font
        }
    }

    class func sfProMedium(withSize size: CGFloat, shouldScale: Bool = true) -> UIFont {
        let font = UIFont(name: "SFProDisplay-Medium", size: size)!
        if shouldScale {
            return UIFontMetrics.default.scaledFont(for: font)
        } else {
            return font
        }
    }

    class func sfProBold(withSize size: CGFloat, shouldScale: Bool = true) -> UIFont {
        let font = UIFont(name: "SFProDisplay-Bold", size: size)!
        if shouldScale {
            return UIFontMetrics.default.scaledFont(for: font)
        } else {
            return font
        }
    }
}


class FontsBundle {}
@discardableResult
public func registerFonts() -> Bool {
    [
        UIFont.registerFont(
            bundles: .myModule,
            fontName: "SFProDisplay-Bold", fontExtension: "ttf"),
        UIFont.registerFont(
            bundles: .myModule,
            fontName: "SFProDisplay-Medium", fontExtension: "ttf"),
        UIFont.registerFont(
            bundles: .myModule,
            fontName: "SFProDisplay-Regular", fontExtension: "ttf"),
    ]
    .allSatisfy { $0 }
}

extension UIFont {

    static func registerFont(bundles: Bundle..., fontName: String, fontExtension: String) -> Bool {
        for bundle in bundles {
            if registerFont(bundle: bundle, fontName: fontName, fontExtension: fontExtension) {
                return true
            }
        }
        return false
    }
    static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) -> Bool {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension) else {
            print("Couldn't find font \(fontName)")
            return false
        }
        
        var error: UnsafeMutablePointer<Unmanaged<CFError>?>?
       
        let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, CTFontManagerScope.process, error)

        guard success else {
            print(
                """
                Error registering font: \(fontName). Maybe it was already registered.
                """
            )
            return true
        }

        return true
    }
}


public extension UIFont {
    static let headline1 = UIFont.sfProBold(withSize: 28)
    static let headline2 = UIFont.sfProBold(withSize: 22)
    static let headline3 = UIFont.sfProBold(withSize: 18)
    static let subheader1 = UIFont.sfProRegular(withSize: 12)
    static let overline = UIFont.sfProMedium(withSize: 14)
    static let title1 = UIFont.sfProMedium(withSize: 17)
    static let title2 = UIFont.sfProMedium(withSize: 15)
    static let body1 = UIFont.sfProRegular(withSize: 17)
    static let body2 = UIFont.sfProRegular(withSize: 15)
    static let caption1 = UIFont.sfProRegular(withSize: 15)
    static let caption2 = UIFont.sfProRegular(withSize: 13)
    static let caption3 = UIFont.sfProMedium(withSize: 13)
    static let caption4 = UIFont.sfProMedium(withSize: 14)
    static let largeInput = UIFont.sfProRegular(withSize: 22)
}
