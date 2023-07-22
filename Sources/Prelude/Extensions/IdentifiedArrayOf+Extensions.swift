import Foundation
extension IdentifiedArrayOf {
	public func appending(_ element: Element) -> Self {
		var copy = self
		copy.append(element)
		return copy
	}
}
