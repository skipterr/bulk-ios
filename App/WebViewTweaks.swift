import UIKit
import WebKit
import ObjectiveC

extension WKWebView {
    /// Убирает серую панель «‹ › Done», которую iOS ставит над клавиатурой у полей ввода на веб-странице.
    /// Делается через подмену класса внутреннего вида WKContentView: он отвечает «панели нет».
    func hideInputAccessoryBar() {
        guard let content = scrollView.subviews.first(where: { String(describing: type(of: $0)).hasPrefix("WKContent") }),
              let baseClass = object_getClass(content) else { return }
        let name = "\(baseClass)_BulkNoAccessory"
        var swapped: AnyClass? = NSClassFromString(name)
        if swapped == nil, let newClass = objc_allocateClassPair(baseClass, name, 0) {
            let noBar: @convention(block) (AnyObject) -> UIView? = { _ in nil }
            class_addMethod(newClass, #selector(getter: UIResponder.inputAccessoryView),
                            imp_implementationWithBlock(noBar), "@@:")
            objc_registerClassPair(newClass)
            swapped = newClass
        }
        if let swapped { object_setClass(content, swapped) }
    }
}
