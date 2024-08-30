
public struct ToggleView: SwiftUI.View {
	public let icon: ImageAsset?
	public let title: String
	public let subtitle: String
	public let minHeight: CGFloat
	public let isOn: Binding<Bool>

	public init(
		icon: ImageAsset? = nil,
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
						AssetIcon(.asset(icon))
							.padding(.trailing, .medium3)
					}

					PlainListRowCore(context: .toggle, title: title, subtitle: subtitle)
				}
			}
		)
		.frame(maxWidth: .infinity, minHeight: minHeight)
	}
}
