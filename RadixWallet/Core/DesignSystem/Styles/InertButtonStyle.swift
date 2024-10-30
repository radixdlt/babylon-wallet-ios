
extension ButtonStyle where Self == InertButtonStyle {
	static var inert: Self { .init() }
}

// MARK: - InertButtonStyle
struct InertButtonStyle: ButtonStyle {
	func makeBody(configuration: ButtonStyle.Configuration) -> some View {
		configuration.label.contentShape(Rectangle())
	}
}
