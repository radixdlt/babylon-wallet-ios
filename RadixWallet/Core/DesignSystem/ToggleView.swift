// MARK: - ToggleView
public struct ToggleView: SwiftUI.View {
	public let context: Context
	public let icon: ImageAsset?
	public let title: String
	public let subtitle: String
	public let minHeight: CGFloat
	public let isOn: Binding<Bool>

	public init(
		context: Context = .toggle,
		icon: ImageAsset? = nil,
		title: String,
		subtitle: String,
		minHeight: CGFloat = .largeButtonHeight,
		isOn: Binding<Bool>
	) {
		self.context = context
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

					PlainListRowCore(context: context.plainListRowContext, title: title, subtitle: subtitle)
				}
			}
		)
		.frame(maxWidth: .infinity, minHeight: minHeight)
	}
}

// MARK: ToggleView.Context
extension ToggleView {
	public enum Context {
		case settings
		case toggle
	}
}

extension ToggleView.Context {
	var plainListRowContext: PlainListRowCore.ViewState.Context {
		switch self {
		case .settings: .settings
		case .toggle: .toggle
		}
	}
}
