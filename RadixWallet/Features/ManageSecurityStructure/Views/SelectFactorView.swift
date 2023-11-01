import ComposableArchitecture
import SwiftUI

// MARK: - SelectFactorView
public struct SelectFactorView: SwiftUI.View {
	@Environment(\.isEnabled) private var isEnabled
	public let title: String
	public let subtitle: String
	public let factorSet: (any BaseFactorSourceProtocol)?
	public let action: () -> Void
	public init(
		title: String,
		subtitle: String,
		factorSet: (any BaseFactorSourceProtocol)? = nil,
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
					// FIXME: future strings
					Text(factorSet?.display ?? "None set")
						.font(.app.body1Header)
						.foregroundColor(factorSet == nil || !isEnabled ? .app.gray3 : .app.gray1)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
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
