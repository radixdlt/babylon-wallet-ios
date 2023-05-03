import Prelude

public struct ROLASignChallenge: Sendable, Hashable, Decodable {
	/// 32 bytes as hex, a nonce to sign
	public let nonce: HexCodable
	/// The on ledger addres to the dapps definition address
	public let dAppDefinitionAddress: AccountAddress
	public let origin: URL
}
