import FeaturePrelude

struct RoundedCornerBackground: View {
	let excludedEdges: Edge.Set
	let cornerRadius: CGFloat

	init(exclude excludedEdges: Edge.Set, cornerRadius: CGFloat) {
		self.excludedEdges = excludedEdges
		self.cornerRadius = cornerRadius
	}

	var body: some View {
		Rectangle()
			.fill(.app.white)
			.padding(excludedEdges, cornerRadius)
			.cornerRadius(cornerRadius)
			.padding(excludedEdges, -cornerRadius)
	}
}
