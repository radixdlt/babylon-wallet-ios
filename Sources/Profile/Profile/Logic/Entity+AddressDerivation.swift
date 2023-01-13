import Cryptography
import EngineToolkit
import ProfileModels

public extension EntityProtocol {
	static func deriveAddress(
		networkID: NetworkID,
		publicKey: SLIP10.PublicKey
	) throws -> EntityAddress {
		let response = try EngineToolkit().deriveVirtualAccountAddressRequest(
			request: .init(
				publicKey: publicKey.intoEngine(),
				networkId: networkID
			)
		).get()

		return try EntityAddress(address: response.virtualAccountAddress.address)
	}
}
