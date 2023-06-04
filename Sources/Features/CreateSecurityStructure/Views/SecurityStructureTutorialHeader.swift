import FeaturePrelude

// MARK: - SecurityStructureTutorialHeader
public struct SecurityStructureTutorialHeader: SwiftUI.View {
	public let action: () -> Void
	public init(
		action: @escaping () -> Void = {
			loggerGlobal.debug("MFA: How does it work? Button tapped")
		}
	) {
		self.action = action
	}

	public var body: some SwiftUI.View {
		VStack(spacing: .medium1) {
			Text("Multi-Factor Setup") // FIXME: Strings
				.font(.app.sheetTitle)

			Text("You can assign diffrent factors to different actions on Radix Accounts")
				.font(.app.body2Regular)

			Button("How does it work?", action: action)
				.buttonStyle(.info)
				.padding(.horizontal, .large2)
				.padding(.bottom, .medium1)
		}
		.padding(.medium1)
	}
}
