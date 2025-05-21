extension InteractionReview {
	static let gradientBackground: LinearGradient = .init(
		stops: [
			.init(color: .secondaryBackground, location: 0),
			.init(color: .tertiaryBackground, location: 1),
		],
		startPoint: .top,
		endPoint: .bottom
	)

	static let transferLineTrailingPadding: CGFloat = .huge3
}
