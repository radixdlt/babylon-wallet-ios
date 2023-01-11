extension Collection {
	@inlinable
	@inline(__always)
	func _rebased<Element>() -> UnsafeMutableBufferPointer<Element>
		where Self == UnsafeMutableBufferPointer<Element>.SubSequence
	{
		.init(rebasing: self)
	}
}

extension UnsafeMutableBufferPointer {
	@inlinable
	@inline(__always)
	func _assign(from source: Self) {
		assert(source.count == self.count)
		if count > 0 {
			baseAddress!.assign(from: source.baseAddress!, count: count)
		}
	}

	@inlinable
	@inline(__always)
	func _initialize(at index: Int, to value: Element) {
		(baseAddress.unsafelyUnwrapped + index).initialize(to: value)
	}
}
