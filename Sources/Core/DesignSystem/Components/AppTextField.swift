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
public struct AppTextField<FocusValue: Hashable, Accessory: View>: View {
	public typealias Hint = AppTextFieldHint

	public struct Focus {
		let value: FocusValue
		let binding: Binding<FocusValue>
		let focusState: FocusState<FocusValue>.Binding

		public static func on(
			_ value: FocusValue,
			binding: Binding<FocusValue>,
			to focusState: FocusState<FocusValue>.Binding
		) -> Self {
			.init(value: value, binding: binding, focusState: focusState)
		}
	}

	let primaryHeading: String?
	let secondaryHeading: String?
	let placeholder: String
	let text: Binding<String>
	let hint: Hint?
	let focus: Focus?
	let accessory: Accessory

	public init(
		primaryHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		focus: Focus,
		@ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
	) {
		self.primaryHeading = primaryHeading
		self.secondaryHeading = secondaryHeading
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.focus = focus
		self.accessory = accessory()
	}

	public init(
		primaryHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		@ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
	) where FocusValue == Never {
		self.primaryHeading = primaryHeading
		self.secondaryHeading = secondaryHeading
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.focus = nil
		self.accessory = accessory()
	}

	public var body: some View {
		HStack(alignment: .textFieldAlignment, spacing: 0) {
			VStack(alignment: .leading, spacing: .small2) {
				HStack {
					if let primaryHeading {
						Text(primaryHeading)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.leading)
					}

					if primaryHeading != nil || secondaryHeading != nil {
						Spacer(minLength: 0)
					}

					if let secondaryHeading {
						Text(secondaryHeading)
							.textStyle(.body2Regular)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.trailing)
					}
				}

				TextField(
					placeholder,
					text: text.removeDuplicates()
				)
				.modifier { view in
					if let focus {
						view.focused(focus.focusState, equals: focus.value)
							.bind(focus.binding, to: focus.focusState)
					} else {
						view
					}
				}
				.padding()
				.frame(height: .standardButtonHeight)
				.background(Color.app.gray5)
				.foregroundColor(.app.gray1)
				.textStyle(.body1Regular)
				.cornerRadius(.small2)
				.overlay(
					RoundedRectangle(cornerRadius: .small2)
						.stroke(borderColor(for: hint), lineWidth: 1)
				)
				.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })

				if let hint {
					HStack(alignment: .top) {
						if hint.isError {
							Image(asset: AssetResource.error)
								.foregroundColor(.app.red1)
						}
						Text(hint.string)
							.foregroundColor(foregroundColor(for: hint))
							.textStyle(.body2Regular)
					}
					.frame(height: .medium2)
				}
			}

			accessory
				.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })
		}
	}

	private func foregroundColor(for hint: Hint) -> Color {
		switch hint {
		case .info:
			return .app.gray2
		case .error:
			return .app.red1
		}
	}

	private func borderColor(for hint: Hint?) -> Color {
		switch hint {
		case .none:
			return .app.gray1
		case .info:
			return .app.gray1
		case .error:
			return .app.red1
		}
	}
}

extension VerticalAlignment {
	private enum TextFieldAlignment: AlignmentID {
		static func defaultValue(in d: ViewDimensions) -> CGFloat {
			d[.bottom]
		}
	}

	fileprivate static let textFieldAlignment = VerticalAlignment(TextFieldAlignment.self)
}

#if DEBUG
struct AppTextField_Previews: PreviewProvider {
	static var previews: some View {
		AppTextFieldPreview()
			.background(Color.gray.opacity(0.2))
			.padding()
	}
}

struct AppTextFieldPreview: View {
	enum Focus {
		case field
	}

	@FocusState
	var focusState: Focus?
	@State
	var focus: Focus?
	@State
	var text: String = ""

	var body: some View {
		AppTextField(
			primaryHeading: "Primary Heading",
			secondaryHeading: "Secondary Heading",
			placeholder: "Placeholder",
			text: $text,
			hint: .error("Hint"),
			focus: .on(.field, binding: $focus, to: $focusState)
		) {
			Image(asset: AssetResource.trash).frame(.small)
		}
	}
}
#endif
