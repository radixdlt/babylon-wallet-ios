public extension BitArray {
	@_spi(Testing)
	var _capacity: Int {
		_storage.capacity * _Word.capacity
	}
}
