
public struct ToggleView: SwiftUI.View {
	public let icon: AssetIcon.Content?
	public let title: String
	public let subtitle: String
	public let minHeight: CGFloat
	public let isOn: Binding<Bool>

	public init(
		icon: AssetIcon.Content? = nil,
		title: String,
		subtitle: String,
		minHeight: CGFloat = .largeButtonHeight,
		isOn: Binding<Bool>
	) {
		self.icon = icon
		self.title = title
		self.subtitle = subtitle
		self.minHeight = minHeight
		self.isOn = isOn
	}

	public var body: some SwiftUI.View {
		Toggle(
			isOn: isOn,
			label: {
				HStack(spacing: .zero) {
					if let icon {
						AssetIcon(icon)
							.padding(.trailing, .medium3)
					}

					PlainListRowCore(title: title, subtitle: subtitle)
						.padding(.vertical, .small3)
				}
			}
		)
		.frame(maxWidth: .infinity, minHeight: minHeight)
	}
}
