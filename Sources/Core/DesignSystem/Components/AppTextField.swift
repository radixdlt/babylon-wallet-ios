import SwiftUI

// MARK: - AppTextField
public struct AppTextField<Value: Hashable>: View {
	let placeholder: String
	let text: Binding<String>
	let hint: String
	let binding: FocusState<Value>.Binding
	let equals: Value
	let first: Binding<Value>

	public init(
		placeholder: String,
		text: Binding<String>,
		hint: String,
		binding: FocusState<Value>.Binding,
		equals: Value,
		first: Binding<Value>
	) {
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.binding = binding
		self.equals = equals
		self.first = first
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			TextField(
				placeholder,
				text: text
					.removeDuplicates()
			)
			.focused(binding, equals: equals)
			.synchronize(first, binding)
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
extension View {
	func synchronize<Value>(
		_ first: Binding<Value>,
		_ second: FocusState<Value>.Binding
	) -> some View {
		onChange(of: first.wrappedValue) { second.wrappedValue = $0 }
			.onChange(of: second.wrappedValue) { first.wrappedValue = $0 }
	}

	@inlinable
	func enabled(_ enabled: @autoclosure () -> Bool) -> some View {
		disabled(!enabled())
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
