// MARK: - StatusMessageView
struct StatusMessageView: View {
	let text: String
	let type: ViewType
	let spacing: CGFloat
	let textStyle: TextStyle
	let emphasizedColor: Color
	let emphasizedTextStyle: TextStyle?

	init(
		text: String,
		type: ViewType,
		useNarrowSpacing: Bool = false,
		useSmallerFontSize: Bool = false,
		emphasizedColor: Color = .textButton,
		emphasizedTextStyle: TextStyle? = nil
	) {
		self.text = text
		self.type = type
		self.spacing = useNarrowSpacing ? .small2 : .medium3
		self.textStyle = useSmallerFontSize ? .body2HighImportance : .body1Header
		self.emphasizedColor = emphasizedColor
		self.emphasizedTextStyle = emphasizedTextStyle
	}

	enum ViewType: Sendable, Hashable {
		case warning
		case error
		case success
	}

	var body: some View {
		HStack(spacing: spacing) {
			Image(icon)
			Text(markdown: text, emphasizedColor: emphasizedColor, emphasizedFont: emphasizedTextStyle?.font)
				.lineSpacing(-.small3)
				.textStyle(textStyle)
				.multilineTextAlignment(.leading)
		}
		.foregroundColor(color)
	}

	var icon: ImageResource {
		switch type {
		case .warning, .error:
			.error
		case .success:
			.checkCircleOutline
		}
	}

	var color: Color {
		switch type {
		case .warning:
			.warning
		case .error:
			.error
		case .success:
			.app.green1
		}
	}
}

extension StatusMessageView {
	static func transactionIntroducesNewAccount() -> some View {
		HStack(alignment: .center, spacing: .small1) {
			StatusMessageView(text: L10n.TransactionReview.FeePayerValidation.linksNewAccount, type: .warning)
			InfoButton(.payingaccount)
		}
	}
}
