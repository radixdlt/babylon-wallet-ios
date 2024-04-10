import Foundation

// MARK: - AnyRange
public struct AnyRange<Bound: Comparable & Sendable>: Sendable {
	public let lowerBound: Bound?
	public let upperBound: Bound?

	public init(lowerBound: Bound? = nil, upperBound: Bound? = nil) {
		self.lowerBound = lowerBound
		self.upperBound = upperBound
	}
}

// MARK: Equatable
extension AnyRange: Equatable where Bound: Equatable {}

// MARK: Hashable
extension AnyRange: Hashable where Bound: Hashable {}

extension AnyRange {
	public func contains(_ element: Bound) -> Bool {
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

	public var isEmpty: Bool {
		lowerBound != nil && lowerBound == upperBound
	}
}

extension AnyRange {
	public func contains(_ otherRange: AnyRange) -> Bool {
		switch (otherRange.lowerBound, otherRange.upperBound) {
		case let (lowerBound?, upperBound?):
			contains(lowerBound) && contains(upperBound)
		case (let lowerBound?, nil):
			contains(lowerBound) && upperBound == nil
		case (nil, let upperBound?):
			lowerBound == nil && contains(upperBound)
		case (nil, nil):
			lowerBound == nil && upperBound == nil
		}
	}

	public var polymorphic: PolyMorhpic {
		switch (lowerBound, upperBound) {
		case let (lowerBound?, upperBound?):
			.range(lowerBound ..< upperBound)
		case (let lowerBound?, nil):
			.partialRangeFrom(lowerBound...)
		case (nil, let upperBound?):
			.partialRangeUpTo(..<upperBound)
		case (nil, nil):
			.unboundedRange
		}
	}

	public enum PolyMorhpic: Sendable {
		case range(Range<Bound>)
		case partialRangeFrom(PartialRangeFrom<Bound>)
		case partialRangeUpTo(PartialRangeUpTo<Bound>)
		case unboundedRange
	}
}
