public enum QR {
	public static let addressPrefix = "radix:"

	public static func removeAddressPrefixIfNeeded(
		from address: inout String
	) {
		if address.hasPrefix(QR.addressPrefix) {
			address.removeFirst(QR.addressPrefix.count)
		}
	}
}
