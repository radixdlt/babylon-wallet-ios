import FeaturePrelude

// MARK: - SelectFactorView
public struct SelectFactorView: SwiftUI.View {
	public let title: String
	public let subtitle: String
	public let factorSet: BaseFactorSourceProtocol?
	public let action: () -> Void
	public init(
		title: String,
		subtitle: String,
		factorSet: BaseFactorSourceProtocol? = nil,
		action: (() -> Void)? = nil
	) {
		self.title = title
		self.subtitle = subtitle
		self.factorSet = factorSet
		self.action = action ?? {
			loggerGlobal.debug("\(title) factor selection tapped")
		}
	}

	public var body: some SwiftUI.View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(title)
				.font(.app.sectionHeader)

			Text(subtitle)
				.font(.app.body2Header)
				.foregroundColor(.app.gray3)

			Button(action: action) {
				HStack {
					// FIXME: Strings
					Text(factorSet?.selectedFactorDisplay ?? "None set")
						.font(.app.body1Header)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
				.foregroundColor(.app.gray3)
			}
			.cornerRadius(.medium2)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.app.gray5)
		}
		.padding()
		.frame(maxWidth: .infinity)
	}
}
