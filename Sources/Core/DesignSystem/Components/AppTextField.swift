import Resources
import SwiftUI
import SwiftUINavigation

// MARK: - AppTextFieldHint
public enum AppTextFieldHint: Equatable {
	case info(String)
	case error(String)

	var string: String {
		switch self {
		case let .info(string), let .error(string):
			return string
		}
	}

	var isError: Bool {
		guard case .error = self else { return false }
		return true
	}
}

// MARK: - AppTextField
public struct AppTextField<Value: Hashable>: View {
	public typealias Hint = AppTextFieldHint

	let heading: String?
	let placeholder: String
	let text: Binding<String>
	let hint: Hint?
	let focusState: FocusState<Value>.Binding
	let equals: Value
	let first: Binding<Value>

	public init(
		heading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint?,
		focusState: FocusState<Value>.Binding,
		equals: Value,
		first: Binding<Value>
	) {
		self.heading = heading
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.focusState = focusState
		self.equals = equals
		self.first = first
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			if let heading {
				Text(heading)
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
			}

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
					.stroke(Color.app.gray1, lineWidth: 1)
			)

			if let hint {
				HStack(alignment: .top) {
					if hint.isError {
						Image(asset: AssetResource.info)
							.foregroundColor(.app.red1)
					}
					Text(hint.string)
						.foregroundColor(foregroundColor(for: hint))
						.textStyle(.body2Regular)
				}
				.frame(height: .medium2)
			}
		}
	}

	func foregroundColor(for hint: Hint) -> Color {
		switch hint {
		case .info:
			return .app.gray2
		case .error:
			return .app.red1
		}
	}
}
