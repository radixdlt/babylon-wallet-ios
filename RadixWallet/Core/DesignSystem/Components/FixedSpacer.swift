
struct FixedSpacer: View {
	let width: CGFloat
	let height: CGFloat

	init(width: CGFloat = 1, height: CGFloat = 1) {
		self.width = width
		self.height = height
	}

	var body: some View {
		Rectangle()
			.fill(.clear)
			.frame(width: width, height: height)
	}
}
