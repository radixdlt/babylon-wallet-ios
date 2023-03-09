import SwiftUI
import SwiftUINavigation

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
		first: Binding<Value>,
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
				text: text.removeDuplicates()
			)
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
