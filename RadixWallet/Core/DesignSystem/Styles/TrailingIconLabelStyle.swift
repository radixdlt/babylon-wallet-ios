
extension LabelStyle where Self == TrailingIconLabelStyle {
	/// Applies the `trailingIcon` style with the default spacing
	static var trailingIcon: Self { .trailingIcon() }

	/// A label style where the icon follows the "title", or text part
	static func trailingIcon(spacing: CGFloat = .small2) -> Self {
		.init(spacing: spacing)
	}
}

// MARK: - TrailingIconLabelStyle
struct TrailingIconLabelStyle: LabelStyle {
	let spacing: CGFloat

	func makeBody(configuration: LabelStyle.Configuration) -> some View {
		HStack(spacing: spacing) {
			configuration.title
			configuration.icon
		}
	}
}
