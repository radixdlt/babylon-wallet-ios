import Foundation

// MARK: - AnyRange
struct AnyRange<Bound: Comparable & Sendable>: Sendable {
	let lowerBound: Bound?
	let upperBound: Bound?

	init(lowerBound: Bound? = nil, upperBound: Bound? = nil) {
		self.lowerBound = lowerBound
		self.upperBound = upperBound
	}
}

// MARK: Equatable
extension AnyRange: Equatable where Bound: Equatable {}

// MARK: Hashable
extension AnyRange: Hashable where Bound: Hashable {}

extension AnyRange {
	func contains(_ element: Bound) -> Bool {
		switch (lowerBound, upperBound) {
		case let (lowerBound?, upperBound?):
			(lowerBound ..< upperBound).contains(element)
		case (let lowerBound?, nil):
			lowerBound <= element
		case (nil, let upperBound?):
			element < upperBound
		case (nil, nil):
			true
		}
	}

	var isEmpty: Bool {
		lowerBound != nil && lowerBound == upperBound
	}
}
