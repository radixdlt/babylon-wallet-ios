extension Range where Bound: FixedWidthInteger {
	@inlinable
	func _clampedToUInt() -> Range<UInt> {
		if upperBound <= 0 {
			return Range<UInt>(uncheckedBounds: (0, 0))
		}
		if lowerBound >= UInt.max {
			return Range<UInt>(uncheckedBounds: (UInt.max, UInt.max))
		}
		let lower = lowerBound < 0 ? 0 : UInt(lowerBound)
		let upper = upperBound > UInt.max ? UInt.max : UInt(upperBound)
		return Range<UInt>(uncheckedBounds: (lower, upper))
	}

	@inlinable
	func _toUInt() -> Range<UInt>? {
		guard
			let lower = UInt(exactly: lowerBound),
			let upper = UInt(exactly: upperBound)
		else {
			return nil
		}
		return Range<UInt>(uncheckedBounds: (lower: lower, upper: upper))
	}
}
