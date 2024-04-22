import Foundation
import Sargon

extension Gateways {
	public static var preset: Self {
		Self.default
	}
}

extension Gateways {
	public typealias Elements = NonEmpty<IdentifiedArrayOf<Gateway>>

	/// All gateways
	public var all: Elements {
		var elements = IdentifiedArrayOf<Gateway>(uniqueElements: [current])
		elements.append(contentsOf: other.elements)
		return .init(rawValue: elements)!
	}
}
