// MARK: - Hint
public struct Hint: View, Equatable {
	public struct ViewState: Sendable, Equatable {
		public let kind: Kind
		public let text: AttributedString?

		public init(kind: Kind, text: String?) {
			self.kind = kind
			self.text = text.map { .init(stringLiteral: $0) }
		}

		public init(kind: Kind, attributed: AttributedString?) {
			self.kind = kind
			self.text = attributed
		}

		public static func info(_ string: String) -> Self {
			.init(kind: .info, text: string)
		}

		public static func error(_ string: String) -> Self {
			.init(kind: .error, text: string)
		}

		public static func error() -> Self {
			.init(kind: .error, text: nil)
		}

		public static func iconError(_ string: String) -> Self {
			.init(kind: .error(imageSize: .icon), text: string)
		}

		public static func iconError() -> Self {
			.init(kind: .error(imageSize: .icon), text: nil)
		}
	}

	public enum Kind: Sendable, Equatable {
		case info
		case error(imageSize: HitTargetSize)
		case warning
		case detail

		static var error: Self {
			.error(imageSize: .smallest)
		}
	}

	public let viewState: ViewState

	public init(viewState: ViewState) {
		self.viewState = viewState
	}

	public var body: some View {
		if let text = viewState.text {
			HStack(spacing: .small3) {
				if let imageResource {
					Image(imageResource)
						.renderingMode(.template)
						.resizable()
						.scaledToFit()
						.frame(imageSize)
				}
				Text(text)
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

	var imageResource: ImageResource? {
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

	var imageSize: HitTargetSize {
		switch viewState.kind {
		case .info, .detail, .warning:
			.smallest
		case let .error(imageSize):
			imageSize
		}
	}
}
