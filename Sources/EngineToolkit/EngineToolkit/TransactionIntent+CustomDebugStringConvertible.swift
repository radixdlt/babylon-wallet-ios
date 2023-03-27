import EngineToolkitModels
import Prelude

// MARK: - TransactionIntent + CustomStringConvertible
extension TransactionIntent: CustomStringConvertible {}

// MARK: - TransactionHeader + CustomStringConvertible
extension TransactionHeader: CustomStringConvertible {}

extension TransactionIntent {
	public func description(
		lookupNetworkName: ((NetworkID) -> String?)?
	) -> String {
		"""
		header: \(header.description(lookupNetworkName: lookupNetworkName))
		manifest:
		===============================================

		\((try? manifest.toString(
			preamble: "",
			instructionsSeparator: "\n",
			instructionsArgumentSeparator: "\t",
			networkID: header.networkId
		)) ?? "\(String(describing: manifest))")

		===============================================

		"""
	}

	public var description: String {
		description(lookupNetworkName: nil)
	}
}

extension TransactionHeader {
	public func description(
		lookupNetworkName: ((NetworkID) -> String?)?
	) -> String {
		"""
		version: \(String(describing: version)),
		networkId: \(String(describing: networkId))\(lookupNetworkName.map { f in f(networkId).map { " (\($0))" } ?? "" } ?? ""),
		startEpochInclusive: \(String(describing: startEpochInclusive)),
		endEpochExclusive: \(String(describing: endEpochExclusive)),
		nonce: \(String(describing: nonce)),
		publicKey: \(publicKey.uncompressedRepresentation.hex),
		notaryAsSignatory: \(String(describing: notaryAsSignatory)),
		costUnitLimit: \(String(describing: costUnitLimit)),
		tipPercentage: \(String(describing: tipPercentage)),
		"""
	}

	public var description: String {
		description(lookupNetworkName: nil)
	}
}
