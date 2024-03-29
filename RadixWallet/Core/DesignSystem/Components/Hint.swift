
// MARK: - Hint
public struct Hint: View, Equatable {
	public struct ViewState: Equatable {
		public let kind: Kind
		public let text: Text?
	}

	public enum Kind: Equatable {
		case info
		case error
		case warning
	}

	public let viewState: ViewState

	private init(kind: Kind, text: Text?) {
		self.viewState = .init(kind: kind, text: text)
	}

	public init(viewState: ViewState) {
		self.viewState = viewState
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
		if let text = viewState.text {
			Label {
				text.lineSpacing(0).textStyle(.body2Regular)
			} icon: {
				if let iconAsset {
					Image(asset: iconAsset)
						.resizable()
						.renderingMode(.template)
						.frame(.smallest)
				}
			}
			.foregroundColor(foregroundColor)
		}
	}

	private var foregroundColor: Color {
		switch viewState.kind {
		case .info:
			.app.gray2
		case .error:
			.app.red1
		case .warning:
			.app.alert
		}
	}

	private var iconAsset: ImageAsset? {
		switch viewState.kind {
		case .info:
			nil
		case .error:
			AssetResource.error
		case .warning:
			AssetResource.warningError
		}
	}
}
