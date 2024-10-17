enum QR {
	static let addressPrefix = "radix:"

	static func removeAddressPrefixIfNeeded(
		from address: inout String
	) {
		if address.hasPrefix(QR.addressPrefix) {
			address.removeFirst(QR.addressPrefix.count)
		}
	}
}
