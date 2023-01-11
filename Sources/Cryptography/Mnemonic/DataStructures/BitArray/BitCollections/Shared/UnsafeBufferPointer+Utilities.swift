extension Collection {
	@inlinable
	@inline(__always)
	func _rebased<Element>() -> UnsafeBufferPointer<Element>
		where Self == UnsafeBufferPointer<Element>.SubSequence
	{
		.init(rebasing: self)
	}
}

extension UnsafeBufferPointer {
	@inlinable
	@inline(__always)
	func _ptr(at index: Int) -> UnsafePointer<Element> {
		assert(index >= 0 && index < count)
		return baseAddress.unsafelyUnwrapped + index
	}
}
