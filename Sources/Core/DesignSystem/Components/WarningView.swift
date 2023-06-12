import Resources
import SwiftUI

public struct WarningView: View {
	public let text: String

	public init(text: String) {
		self.text = text
	}

	public var body: some View {
		HStack(spacing: .medium3) {
			Image(asset: AssetResource.warningError)
				.resizable()
				.frame(.smallest)
			Text(text)
				.textStyle(.body1Header)
				.foregroundColor(.app.alert)
				.multilineTextAlignment(.leading)
		}
	}
}
