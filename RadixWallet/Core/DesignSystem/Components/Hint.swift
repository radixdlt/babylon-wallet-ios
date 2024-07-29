// MARK: - Hint
public struct Hint: View, Equatable {
	public struct ViewState: Equatable {
		public let kind: Kind
		public let text: Text?

		public init(kind: Kind, text: Text?) {
			self.kind = kind
			self.text = text
		}

		public init(kind: Kind, text: some StringProtocol) {
			self.kind = kind
			self.text = Text(text)
		}
	}

	public enum Kind: Equatable {
		case info
		case error
		case warning
		case detail
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
			HStack(spacing: .small3) {
				if let iconResource {
					Image(iconResource)
						.renderingMode(.template)
						.resizable()
						.scaledToFit()
						.frame(.smallest)
				}
				text
					.lineSpacing(0)
					.textStyle(textStyle)
			}
			.foregroundColor(foregroundColor)
		}
	}
}

private extension Hint {
	var foregroundColor: Color {
		switch viewState.kind {
		case .info:
			.app.gray2
		case .error:
			.app.red1
		case .warning, .detail:
			.app.alert
		}
	}

	var iconResource: ImageResource? {
		switch viewState.kind {
		case .info, .detail:
			nil
		case .error, .warning:
			.error
		}
	}

	var textStyle: TextStyle {
		switch viewState.kind {
		case .info, .error, .warning:
			.body2HighImportance
		case .detail:
			.body1Regular
		}
	}
}
