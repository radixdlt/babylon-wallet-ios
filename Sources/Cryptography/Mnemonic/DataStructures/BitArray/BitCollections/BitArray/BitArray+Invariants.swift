public extension BitArray {
	#if COLLECTIONS_INTERNAL_CHECKS
	@inline(never)
	@_effects(releasenone)
	func _checkInvariants() {
		precondition(_count <= _storage.count * _Word.capacity)
		precondition(_count > (_storage.count - 1) * _Word.capacity)
		let p = _BitPosition(_count).split
		if p.bit > 0 {
			precondition(_storage.last!.subtracting(_Word(upTo: p.bit)) == .empty)
		}
	}
	#else
	@inline(__always) @inlinable
	func _checkInvariants() {}
	#endif // COLLECTIONS_INTERNAL_CHECKS
}
