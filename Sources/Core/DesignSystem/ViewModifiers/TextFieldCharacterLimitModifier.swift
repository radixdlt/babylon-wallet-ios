#if os(iOS)
import Introspect
import SwiftUI

public extension View {
	@MainActor
	func textFieldCharacterLimit(_ limit: Int?, forText text: Binding<String>) -> some View {
		self.introspectTextField { uiTextField in
			if let limit {
				uiTextField.dynamicProperties = (characterLimit: limit, textBinding: text)
			} else {
				uiTextField.dynamicProperties = nil
			}
		}
	}
}

private extension UITextField {
	var dynamicProperties: (characterLimit: Int, textBinding: Binding<String>)? {
		get {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			return objc_getAssociatedObject(self, key) as? (characterLimit: Int, textBinding: Binding<String>)
		}
		set {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			objc_setAssociatedObject(self, key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			delegate?.swizzle()
		}
	}
}

private extension UITextFieldDelegate {
	func swizzle() {
		guard !SwizzledUITextFieldDelegate.state.isActive else { return }

		guard let delegateClass = object_getClass(self) else {
			return
		}

		let originalSelector = #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))
		let swizzledSelector = #selector(SwizzledUITextFieldDelegate.swizzled_textField(_:shouldChangeCharactersIn:replacementString:))

		guard let swizzledMethod = class_getInstanceMethod(SwizzledUITextFieldDelegate.self, swizzledSelector) else {
			return
		}

		if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
			// exchange implementation
			method_exchangeImplementations(originalMethod, swizzledMethod)
			SwizzledUITextFieldDelegate.state = .active(.exchanged)
		} else {
			// add implementation
			class_addMethod(delegateClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
			SwizzledUITextFieldDelegate.state = .active(.added)
		}
	}
}

// MARK: - SwizzledUITextFieldDelegate
private final class SwizzledUITextFieldDelegate {
	enum State {
		enum ActivationType {
			case exchanged
			case added
		}

		case inactive
		case active(ActivationType)

		var isActive: Bool {
			guard case .active = self else { return false }
			return true
		}
	}

	static var state: State = .inactive

	@MainActor
	@objc func swizzled_textField(
		_ textField: UITextField,
		shouldChangeCharactersIn range: NSRange,
		replacementString string: String
	) -> Bool {
		guard
			let (characterLimit, textBinding) = textField.dynamicProperties,
			let currentString = textField.text
		else {
			switch Self.state {
			case .inactive:
				return true
			case .active(.exchanged):
				return swizzled_textField(textField, shouldChangeCharactersIn: range, replacementString: string)
			case .active(.added):
				return true
			}
		}

		let proposedString = currentString.replacingCharacters(in: Range(range, in: currentString)!, with: string)

		if proposedString.count > characterLimit {
			let newString = String(proposedString.prefix(characterLimit))

			DispatchQueue.main.async {
				textBinding.wrappedValue = newString
				textField.text = newString
			}

			return false
		} else {
			return true
		}
	}
}
#endif
