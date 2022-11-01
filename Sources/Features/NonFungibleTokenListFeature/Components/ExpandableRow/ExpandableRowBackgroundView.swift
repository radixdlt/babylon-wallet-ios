import SwiftUI

struct ExpandableRowBackgroundView: SwiftUI.View {
	let paddingEdge: Edge.Set
	let paddingValue: CGFloat
	let cornerRadius: CGFloat

	var body: some View {
		Rectangle()
			.foregroundColor(.white)
			.padding(paddingEdge, paddingValue)
			.cornerRadius(paddingValue)
			.padding(paddingEdge, -paddingValue)
			.cornerRadius(cornerRadius)
	}
}
