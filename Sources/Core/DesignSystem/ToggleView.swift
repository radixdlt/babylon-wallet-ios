import SwiftUI

public struct ToggleView: SwiftUI.View {
	public let title: String
	public let subtitle: String
	public let isOn: Binding<Bool>

	public init(title: String, subtitle: String, isOn: Binding<Bool>) {
		self.title = title
		self.subtitle = subtitle
		self.isOn = isOn
	}

	public var body: some SwiftUI.View {
		Toggle(
			isOn: isOn,
			label: {
				VStack(alignment: .leading, spacing: 0) {
					Text(title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					Text(subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
				}
			}
		)
		.frame(maxWidth: .infinity, idealHeight: .largeButtonHeight)
	}
}
