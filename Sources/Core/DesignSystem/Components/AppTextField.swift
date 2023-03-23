import Resources
import SwiftUI
import SwiftUINavigation

// MARK: - AppTextField
public struct AppTextField<Value: Hashable>: View {
	let placeholder: String
	let text: Binding<String>
	let hint: String?
	let presentsError: Bool
	let focusState: FocusState<Value>.Binding
	let equals: Value
	let first: Binding<Value>
	public init(
		placeholder: String,
		text: Binding<String>,
		hint: String?,
		presentsError: Bool = false,
		focusState: FocusState<Value>.Binding,
		equals: Value,
		first: Binding<Value>
	) {
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.presentsError = presentsError
		self.focusState = focusState
		self.equals = equals
		self.first = first
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			TextField(
				placeholder,
				text: text.removeDuplicates()
			)
			.focused(focusState, equals: equals)
			.bind(first, to: focusState)
			.padding()
			.frame(height: .standardButtonHeight)
			.background(Color.app.gray5)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.cornerRadius(.small2)
			.overlay(
				RoundedRectangle(cornerRadius: .small2)
					.stroke(borderColor, lineWidth: 1)
			)

			HStack(alignment: .top) {
				if presentsError {
					Image(asset: AssetResource.error)
						.foregroundColor(.app.red1)
				}

				Text(hint ?? "")
					.foregroundColor(presentsError ? .app.red1 : .app.gray2)
					.textStyle(.body2Regular)
			}
			.opacity(hint != nil ? 1 : 0)
			.frame(height: .medium2)
		}
	}

	private var borderColor: Color {
		presentsError ? .app.red1 : .app.gray1
	}
}
