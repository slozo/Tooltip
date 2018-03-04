//
//  Extensions.swift
//  Tooltip
//
//  Created by Lasha Efremidze on 2/22/18.
//  Copyright © 2018 Lasha Efremidze. All rights reserved.
//

import UIKit

extension UIView {
    func hasSuperview(_ superview: UIView) -> Bool {
        //        return self.superview === superview ?? superview.flatMap { $0.superview(of: type) }
        var view = self
        while let _view = view.superview {
            defer { view = _view }
            if _view === superview {
                return true
            }
        }
        return false
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: x + width / 2, y: y + height / 2)
    }
    var x: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }
    var y: CGFloat {
        get { return origin.y }
        set { origin.y = newValue }
    }
}

extension UIEdgeInsets {
    init(all: CGFloat) {
        self.init(top: all, left: all, bottom: all, right: all)
    }
}
