// MARK: - ToggleView
struct ToggleView: SwiftUI.View {
	let context: Context
	let icon: ImageResource?
	let title: String
	let subtitle: String?
	let minHeight: CGFloat
	let isOn: Binding<Bool>

	init(
		context: Context = .toggle,
		icon: ImageResource? = nil,
		title: String,
		subtitle: String?,
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

	var body: some SwiftUI.View {
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
		.tint(.toggleActive)
	}
}

// MARK: ToggleView.Context
extension ToggleView {
	enum Context {
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
