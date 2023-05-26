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

	let primaryHeading: String?
	let secondaryHeading: String?
	let placeholder: String
	let text: Binding<String>
	let hint: Hint?
	let focus: Focus?
	let showClearButton: Bool
	let accessory: Accessory
	let innerAccesory: InnerAccessory

	public init(
		primaryHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		focus: Focus,
		showClearButton: Bool = false,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() },
		@ViewBuilder innerAccessory: () -> InnerAccessory = { EmptyView() }
	) {
		self.primaryHeading = primaryHeading
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
		primaryHeading: String? = nil,
		secondaryHeading: String? = nil,
		placeholder: String,
		text: Binding<String>,
		hint: Hint? = nil,
		showClearButton: Bool = false,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() },
		@ViewBuilder innerAccessory: () -> InnerAccessory = { EmptyView() }
	) where FocusValue == Never {
		self.primaryHeading = primaryHeading
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
						Text(primaryHeading)
							.textStyle(.body1HighImportance)
							.foregroundColor(accentColor)
							.multilineTextAlignment(.leading)
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
					TextField(
						placeholder,
						text: text.removeDuplicates()
					)
					.modifier { view in
						if let focus {
							view
								.focused(focus.focusState, equals: focus.value)
								.bind(focus.binding, to: focus.focusState)
						} else {
							view
						}
					}
					.foregroundColor(.app.gray1)
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
						.stroke(accentColor, lineWidth: 1)
				)

				hint
			}

			accessory
				.alignmentGuide(.textFieldAlignment, computeValue: { $0[VerticalAlignment.center] })
		}
	}

	private var accentColor: Color {
		switch hint?.kind {
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
			focus: .on(.field, binding: $focus, to: $focusState),
			innerAccessory: {
				Image(asset: AssetResource.trash).frame(.small)
			}
		)
	}
}
#endif
