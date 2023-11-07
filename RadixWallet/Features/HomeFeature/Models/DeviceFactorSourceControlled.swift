import Foundation

// MARK: - DeviceFactorSourceControlled
public struct DeviceFactorSourceControlled: Sendable, Hashable {
	public let factorSourceID: FactorSourceID.FromHash
	public var importMnemonicNeeded = false {
		didSet {
			if importMnemonicNeeded {
				exportMnemonicNeeded = false
			}
		}
	}

	public var exportMnemonicNeeded = false
}
