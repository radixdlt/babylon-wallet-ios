enum QR {
	static let addressPrefix = "radix:"
	static let rnsPrefix = "rns:"

	static func removeTransferRecipientPrefixIfNeeded(
		from address: inout String
	) {
		if address.hasPrefix(QR.addressPrefix) {
			address.removeFirst(QR.addressPrefix.count)
		}

		if address.hasPrefix(QR.rnsPrefix) {
			address.removeFirst(QR.rnsPrefix.count)
		}
	}
}
