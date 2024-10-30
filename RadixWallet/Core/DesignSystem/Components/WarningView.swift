// MARK: - WarningErrorView
struct WarningErrorView: View {
	let text: String
	let type: ViewType
	let spacing: CGFloat

	init(
		text: String,
		type: ViewType,
		useNarrowSpacing: Bool = false
	) {
		self.text = text
		self.type = type
		self.spacing = useNarrowSpacing ? .small2 : .medium3
	}

	enum ViewType {
		case warning
		case error
	}

	var body: some View {
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

extension WarningErrorView {
	static func transactionIntroducesNewAccount() -> some View {
		HStack(alignment: .center, spacing: .small1) {
			WarningErrorView(text: L10n.TransactionReview.FeePayerValidation.linksNewAccount, type: .warning)
			InfoButton(.payingaccount)
		}
	}
}
