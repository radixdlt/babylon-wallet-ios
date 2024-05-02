import Foundation
import Sargon

extension CanBeEmptyIdentifiedCollection {
	public init(identified: IdentifiedArrayOf<Element>) {
		self.init(identified.elements)
	}
}
