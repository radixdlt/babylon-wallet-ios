import ScreenshotPreventing
import SwiftUINavigation

// MARK: - AppTextField
struct AppTextField<FocusValue: Hashable, Accessory: View, InnerAccessory: View>: View {
	struct Focus {
		let value: FocusValue
		let binding: Binding<FocusValue>
		let focusState: FocusState<FocusValue>.Binding

		static func on(
			_ value: FocusValue,
			binding: Binding<FocusValue>,
			to focusState: FocusState<FocusValue>.Binding
		) -> Self {
			.init(value: value, binding: binding, focusState: focusState)
		}
	}

	struct PrimaryHeading: Sendable, Hashable, ExpressibleByStringLiteral {
		let text: String
		let isProminent: Bool
		init(text: String, isProminent: Bool = true) {
			self.text = text
			self.isProminent = isProminent
		}

		init(stringLiteral value: StringLiteralType) {
			self.init(text: value)
		}
	}

	let useSecureField: Bool

	@Environment(\.isEnabled) var isEnabled: Bool

	let primaryHeading: PrimaryHeading?
	let subHeading: String?
	let secondaryHeading: String?
	let placeholder: String
	let text: Binding<String>
	let hint: Hint.ViewState?
	let focus: Focus?
	let showClearButton: Bool
	let preventScreenshot: Bool
	let accessory: Accessory
	let innerAccesory: InnerAccessory

	@State private var isFocused: Bool = false

	init(
		useSecureField: Bool = false,
		primaryHeading: PrimaryHeading? = nil,
		subHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint.ViewState? = nil,
		focus: Focus,
		showClearButton: Bool = false,
		preventScreenshot: Bool = false,
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
		self.preventScreenshot = preventScreenshot
		self.accessory = accessory()
		self.innerAccesory = innerAccessory()
	}

	init(
		useSecureField: Bool = false,
		primaryHeading: PrimaryHeading? = nil,
		subHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint.ViewState? = nil,
		showClearButton: Bool = false,
		preventScreenshot: Bool = false,
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
		self.preventScreenshot = preventScreenshot
		self.accessory = accessory()
		self.innerAccesory = innerAccessory()
	}

	var body: some View {
		HStack(alignment: .textFieldAlignment, spacing: 0) {
			VStack(alignment: .leading, spacing: Constants.appTextFieldSpacing) {
				if primaryHeading != nil || secondaryHeading != nil {
					HStack(spacing: 0) {
						if let primaryHeading {
							VStack(alignment: .leading, spacing: 0) {
								Text(primaryHeading.text)
									.textStyle(primaryHeading.isProminent ? .body1HighImportance : .body2Regular)
									.foregroundColor(primaryHeading.isProminent && isEnabled ? accentColor(isFocused: true) : .app.gray2)
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
				}

				HStack(spacing: .small2) {
					Group {
						if useSecureField {
							SecureField(placeholder, text: text.removeDuplicates())
						} else {
							TextField(
								placeholder,
								text: text.removeDuplicates()
							) { value in
								isFocused = value
							}
							.screenshotProtected(isProtected: isScreenshotProtected)
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
				.padding(.medium3)
				.frame(height: .standardButtonHeight)
				.background(Color.app.gray5)
				.cornerRadius(.small2)
				.overlay(
					RoundedRectangle(cornerRadius: .small2)
						.stroke(accentColor(isFocused: isFocused), lineWidth: 1)
				)

				if let hint {
					Hint(viewState: hint)
				}
			}

			accessory
				.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })
		}
	}

	private var isScreenshotProtected: Bool {
		#if DEBUG
		false
		#else
		preventScreenshot
		#endif
	}

	private func accentColor(isFocused: Bool) -> Color {
		switch hint?.kind {
		case .none, .info:
			isFocused ? .app.gray1 : .app.gray4
		case .error:
			.app.red1
		case .warning, .detail:
			.app.alert
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

extension Constants {
	static let appTextFieldSpacing: CGFloat = .small1
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
