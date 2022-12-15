import Introspect
import SwiftUI
import SwiftUINavigation

// MARK: - AppTextField
public struct AppTextField<Value: Hashable>: View {
	let placeholder: String
	let text: Binding<String>
	let characterLimit: Int?
	let hint: String
	let binding: FocusState<Value>.Binding
	let equals: Value
	let first: Binding<Value>

	public init(
		placeholder: String,
		text: Binding<String>,
		characterLimit: Int? = nil,
		hint: String,
		binding: FocusState<Value>.Binding,
		equals: Value,
		first: Binding<Value>
	) {
		self.placeholder = placeholder
		self.text = text
		self.characterLimit = characterLimit
		self.hint = hint
		self.binding = binding
		self.equals = equals
		self.first = first
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			TextField(
				placeholder,
				text: text.removeDuplicates()
			)
			.introspectTextField { $0.characterLimit = characterLimit }
			.focused(binding, equals: equals)
			.bind(first, to: binding)
			.padding()
			.frame(height: .standardButtonHeight)
			.background(Color.app.gray5)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.cornerRadius(.small2)
			.overlay(
				RoundedRectangle(cornerRadius: .small2)
					.stroke(Color.app.gray1, lineWidth: 1)
			)

			Text(hint)
				.foregroundColor(.app.gray2)
				.textStyle(.body2Regular)
		}
	}
}

// TODO: extract / delete duplicate
extension Binding where Value: Equatable {
	func removeDuplicates() -> Self {
		.init(
			get: { self.wrappedValue },
			set: { newValue, transaction in
				guard newValue != self.wrappedValue else { return }
				self.transaction(transaction).wrappedValue = newValue
			}
		)
	}
}

private extension UITextField {
	var characterLimit: Int? {
		get {
			let key = unsafeBitCast(Selector(#function), to: UnsafeRawPointer.self)
			return objc_getAssociatedObject(self, key) as? Int
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
			let characterLimit = textField.characterLimit,
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

		let newString = currentString.replacingCharacters(in: Range(range, in: currentString)!, with: string)

		print(newString)

		if newString.count > characterLimit {
			DispatchQueue.main.async {
				textField.text = String(newString.prefix(characterLimit))
			}
			return false
		} else {
			return true
		}
	}
}
