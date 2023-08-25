import Resources
import SwiftUI
import SwiftUINavigation

// MARK: - AppTextField
public struct AppTextField<FocusValue: Hashable, Accessory: View, InnerAccessory: View>: View {
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

	public struct PrimaryHeading: Sendable, Hashable, ExpressibleByStringLiteral {
		public let text: String
		public let isProminent: Bool
		public init(text: String, isProminent: Bool = true) {
			self.text = text
			self.isProminent = isProminent
		}

		public init(stringLiteral value: StringLiteralType) {
			self.init(text: value)
		}
	}

	public let useSecureField: Bool

	@Environment(\.isEnabled) var isEnabled: Bool

	let primaryHeading: PrimaryHeading?
	let subHeading: String?
	let secondaryHeading: String?
	let placeholder: String
	let text: Binding<String>
	let hint: Hint?
	let focus: Focus?
	let showClearButton: Bool
	let accessory: Accessory
	let innerAccesory: InnerAccessory

	public init(
		useSecureField: Bool = false,
		primaryHeading: PrimaryHeading? = nil,
		subHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		focus: Focus,
		showClearButton: Bool = false,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() },
		@ViewBuilder innerAccessory: () -> InnerAccessory = { EmptyView() }
	) {
		self.useSecureField = useSecureField
		self.primaryHeading = primaryHeading
		self.subHeading = subHeading
		self.secondaryHeading = secondaryHeading
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.focus = focus
		self.showClearButton = showClearButton
		self.accessory = accessory()
		self.innerAccesory = innerAccessory()
	}

	public init(
		useSecureField: Bool = false,
		primaryHeading: PrimaryHeading? = nil,
		subHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		showClearButton: Bool = false,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() },
		@ViewBuilder innerAccessory: () -> InnerAccessory = { EmptyView() }
	) where FocusValue == Never {
		self.useSecureField = useSecureField
		self.primaryHeading = primaryHeading
		self.subHeading = subHeading
		self.secondaryHeading = secondaryHeading
		self.placeholder = placeholder
		self.text = text
		self.hint = hint
		self.focus = nil
		self.showClearButton = showClearButton
		self.accessory = accessory()
		self.innerAccesory = innerAccessory()
	}

	public var body: some View {
		HStack(alignment: .textFieldAlignment, spacing: 0) {
			VStack(alignment: .leading, spacing: .small3) {
				HStack(spacing: 0) {
					if let primaryHeading {
						VStack(alignment: .leading, spacing: 0) {
							Text(primaryHeading.text)
								.textStyle(primaryHeading.isProminent ? .body1HighImportance : .body2Regular)
								.foregroundColor(primaryHeading.isProminent && isEnabled ? accentColor(border: false) : .app.gray2)
								.multilineTextAlignment(.leading)
							if let subHeading {
								Text(subHeading)
									.textStyle(.body2Regular)
									.foregroundColor(.app.gray2)
									.multilineTextAlignment(.trailing)
							}
						}
					}

					Spacer(minLength: 0)

					if let secondaryHeading {
						Text(secondaryHeading)
							.textStyle(.body2Regular)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.trailing)
					}
				}

				HStack(spacing: .small2) {
					Group {
						if useSecureField {
							SecureField(placeholder, text: text.removeDuplicates())
						} else {
							TextField(
								placeholder,
								text: text.removeDuplicates()
							)
						}
					}
					.modifier { view in
						if let focus {
							view
								.focused(focus.focusState, equals: focus.value)
								.bind(focus.binding, to: focus.focusState)
						} else {
							view
						}
					}
					.privacySensitive()
					.foregroundColor(isEnabled ? .app.gray1 : .app.gray2)
					.textStyle(.body1Regular)
					.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })

					if
						showClearButton,
						!text.wrappedValue.isEmpty
					{
						Button {
							text.wrappedValue = ""
						} label: {
							Image(systemName: "multiply.circle.fill")
								.foregroundStyle(.gray)
						}
					}

					innerAccesory
				}
				.padding([.top, .bottom])
				.padding([.leading, .trailing], 6)
				.frame(height: .standardButtonHeight)
				.background(Color.app.gray5)
				.cornerRadius(.small2)
				.overlay(
					RoundedRectangle(cornerRadius: .small2)
						.stroke(accentColor(border: true), lineWidth: 1)
				)

				hint
			}

			accessory
				.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })
		}
	}

	private func accentColor(border: Bool) -> Color {
		switch hint?.kind {
		case .none:
			return border ? .app.gray4 : .app.gray1
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
			focus: .on(.field, binding: $focus, to: $focusState),
			innerAccessory: {
				Image(asset: AssetResource.trash).frame(.small)
			}
		)
	}
}
#endif
