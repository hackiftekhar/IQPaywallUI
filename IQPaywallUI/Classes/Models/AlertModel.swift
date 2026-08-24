//
//  AlertModel.swift

import Foundation

public struct AlertModel {
    public var isShow: Bool = false
    public private(set) var title: String = ""
    public private(set) var message: String = ""
    public private(set) var buttonTitle: String = ""

    public init() {
    }

    public mutating func show(title: String, message: String, buttonTitle: String = "OK") {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        isShow = true
    }

    public mutating func hide() {
        isShow = false
        title = ""
        message = ""
        buttonTitle = ""
    }
}
