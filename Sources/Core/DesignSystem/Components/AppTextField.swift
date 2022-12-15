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
	@MainActor
	func swizzle() {
		guard !SwizzledUITextFieldDelegate.isActive else { return }

		guard let delegateClass = object_getClass(self) else {
			return
		}

		let originalSelector = #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))
		let swizzledSelector = #selector(SwizzledUITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))

		guard let swizzledMethod = class_getInstanceMethod(SwizzledUITextFieldDelegate.self, swizzledSelector) else {
			return
		}

		if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
			// exchange implementation
			method_exchangeImplementations(originalMethod, swizzledMethod)
		} else {
			// add implementation
			class_addMethod(delegateClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
		}

		SwizzledUITextFieldDelegate.isActive = true
	}
}

// MARK: - SwizzledUITextFieldDelegate
private final class SwizzledUITextFieldDelegate {
	static var isActive = false

	@MainActor
	@objc func textField(
		_ textField: UITextField,
		shouldChangeCharactersIn range: NSRange,
		replacementString string: String
	) -> Bool {
		print("something")

		guard
			let characterLimit = textField.characterLimit,
			let currentString = textField.text
		else {
			return self.textField(textField, shouldChangeCharactersIn: range, replacementString: string)
		}

		let newString = currentString.replacingCharacters(in: Range(range, in: currentString)!, with: string)

		return newString.count <= characterLimit
	}
}
