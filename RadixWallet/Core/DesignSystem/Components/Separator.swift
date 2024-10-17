// MARK: - SeparatorEdgeSet
struct SeparatorEdgeSet: OptionSet {
	static let top = Self(rawValue: 1 << 0)
	static let bottom = Self(rawValue: 1 << 1)

	let rawValue: UInt8

	init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
}

extension View {
	func separator(_ edges: SeparatorEdgeSet) -> some View {
		self.modifier(SeparatorModifier(edges: edges))
	}
}

// MARK: - SeparatorModifier
private struct SeparatorModifier: ViewModifier {
	let edges: SeparatorEdgeSet

	func body(content: Content) -> some View {
		VStack(spacing: 0) {
			if edges.contains(.top) {
				Separator()
			}
			content
			if edges.contains(.bottom) {
				Separator()
			}
		}
	}
}

// MARK: - Separator
struct Separator: View {
	init() {}

	var body: some View {
		Color.app.gray4
			.frame(height: 1)
	}
}

// MARK: - Separator_Previews
struct Separator_Previews: PreviewProvider {
	static var previews: some View {
		Separator()
	}
}
