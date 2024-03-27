extension NotarySignature {
	public init(signature: Sargon.SignatureWithPublicKey) {
		fatalError("sargon migration")
	}
}

// MARK: - AssetsTransfersRecipient + Identifiable
extension AssetsTransfersRecipient: Identifiable {
	public typealias ID = AccountAddress
	public var id: ID {
		accountAddress
	}
}
