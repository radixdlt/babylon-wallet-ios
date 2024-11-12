
// MARK: - TokenRowShadow
extension View {
	func tokenRowShadow(_ show: Bool = true) -> some View {
		shadow(
			color: show ? .app.shadowBlack : .clear,
			radius: .small2,
			x: .zero,
			y: .small2
		)
	}
}
