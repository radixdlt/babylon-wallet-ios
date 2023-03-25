import Resources
import SwiftUI

// MARK: - Hint
public struct Hint: View, Equatable {
	public enum Kind: Equatable {
		case info
		case error
	}

	let kind: Kind
	let text: Text

	public init(
		_ kind: Kind,
		_ text: Text
	) {
		self.kind = kind
		self.text = text
	}

	public var body: some View {
		Label {
			text.textStyle(.body2Regular)
		} icon: {
			if kind == .error {
				Image(asset: AssetResource.error)
			}
		}
		.foregroundColor(foregroundColor)
	}

	private var foregroundColor: Color {
		switch kind {
		case .info:
			return .app.gray2
		case .error:
			return .app.red1
		}
	}
}

extension Hint {
	public static func info(_ string: some StringProtocol) -> Self {
		.init(.info, Text(string))
	}

	public static func error(_ string: some StringProtocol) -> Self {
		.init(.error, Text(string))
	}
}
