
public struct WarningErrorView: View {
	public let text: String
	public let type: ViewType
	public let spacing: CGFloat

	public init(
		text: String,
		type: ViewType,
		useNarrowSpacing: Bool = false
	) {
		self.text = text
		self.type = type
		self.spacing = useNarrowSpacing ? .small2 : .medium3
	}

	public enum ViewType {
		case warning
		case error
	}

	public var body: some View {
		HStack(spacing: spacing) {
			Image(.error)
			Text(text)
				.lineSpacing(-.small3)
				.textStyle(.body1Header)
				.multilineTextAlignment(.leading)
		}
		.foregroundColor(color)
	}

	var color: Color {
		switch type {
		case .warning:
			.app.alert
		case .error:
			.app.red1
		}
	}
}
