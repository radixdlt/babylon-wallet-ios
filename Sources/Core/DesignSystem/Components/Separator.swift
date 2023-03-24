import SwiftUI

// MARK: - SeparatorEdgeSet
public struct SeparatorEdgeSet: OptionSet {
	public static let top = Self(rawValue: 1 << 0)
	public static let bottom = Self(rawValue: 1 << 1)

	public let rawValue: UInt8

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
}

extension View {
	public func separator(_ edges: SeparatorEdgeSet) -> some View {
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
public struct Separator: View {
	public init() {}

	public var body: some View {
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
