import Foundation
import Sargon

extension Gateways {
	public static var preset: Self {
		sargonProfileStage1()
	}
}

extension Gateways {
	public typealias Elements = NonEmpty<IdentifiedArrayOf<Gateway>>

	/// All gateways
	public var all: Elements {
		var elements = IdentifiedArrayOf<Gateway>(uniqueElements: [current])
		elements.append(contentsOf: other)
		return .init(rawValue: elements)!
	}
}
