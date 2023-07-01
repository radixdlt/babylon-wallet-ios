import Resources
import SwiftUI

public struct WarningErrorView: View {
	public let text: String
	public let type: ViewType

	public init(text: String, type: ViewType) {
		self.text = text
		self.type = type
	}

	public enum ViewType {
		case warning
		case error
	}

	public var body: some View {
		HStack(spacing: .medium3) {
			Image(asset: AssetResource.warningError)
				.resizable()
				.renderingMode(.template)
				.frame(.smallest)
			Text(text)
				.textStyle(.body1Header)
				.multilineTextAlignment(.leading)
		}
		.foregroundColor(color)
	}

	var color: Color {
		switch type {
		case .warning:
			return .app.alert
		case .error:
			return .app.red1
		}
	}
}
