
// MARK: - Hint
public struct Hint: View, Equatable {
	public enum Kind: Equatable {
		case info
		case error
	}

	let kind: Kind
	let text: Text?

	private init(kind: Kind, text: Text?) {
		self.kind = kind
		self.text = text
	}

	public static func info(_ text: () -> Text) -> Self {
		.init(kind: .info, text: text())
	}

	public static func info(_ string: some StringProtocol) -> Self {
		.init(kind: .info, text: Text(string))
	}

	public static func error(_ text: () -> Text) -> Self {
		.init(kind: .error, text: text())
	}

	public static func error(_ string: some StringProtocol) -> Self {
		.init(kind: .error, text: Text(string))
	}

	public static func error() -> Self {
		.init(kind: .error, text: nil)
	}

	public var body: some View {
		if let text {
			Label {
				text.lineSpacing(0).textStyle(.body2Regular)
			} icon: {
				if kind == .error {
					Image(asset: AssetResource.error)
				}
			}
			.foregroundColor(foregroundColor)
		}
	}

	private var foregroundColor: Color {
		switch kind {
		case .info:
			.app.gray2
		case .error:
			.app.red1
		}
	}
}
