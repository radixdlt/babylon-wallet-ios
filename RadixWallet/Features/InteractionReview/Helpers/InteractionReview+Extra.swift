extension InteractionReview {
	static let gradientBackground: LinearGradient = .init(
		stops: [
			.init(color: .app.gray5, location: 0),
			.init(color: .app.gray4, location: 1),
		],
		startPoint: .top,
		endPoint: .bottom
	)

	static let transferLineTrailingPadding: CGFloat = .huge3

	static let shadowColor: Color = .app.gray2.opacity(0.4)
}
