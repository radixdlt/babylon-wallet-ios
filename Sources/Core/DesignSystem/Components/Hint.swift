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

	public static func info(@ViewBuilder _ text: () -> Text) -> Self {
		.init(kind: .info, text: text())
	}

	public static func info(_ string: some StringProtocol) -> Self {
		.init(kind: .info, text: Text(string))
	}

	public static func error(@ViewBuilder _ text: () -> Text) -> Self {
		.init(kind: .error, text: text())
	}

	public static func error(_ string: some StringProtocol) -> Self {
		.init(kind: .error, text: Text(string))
	}

	public var body: some View {
		Label {
			text.lineSpacing(0).textStyle(.body2Regular)
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
