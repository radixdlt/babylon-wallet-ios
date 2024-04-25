import Foundation
import Sargon

// MARK: - FactorSourceKindOfMnemonic
public enum FactorSourceKindOfMnemonic: Sendable, Hashable {
	public enum OnDeviceMnemonicKind: Sendable, Hashable {
		case babylon(isMain: Bool)
		case olympia
	}

	case onDevice(OnDeviceMnemonicKind)
	case offDevice

	public var factorSourceKind: FactorSourceKind {
		switch self {
		case .offDevice: .offDeviceMnemonic
		case .onDevice: .device
		}
	}
}

#if DEBUG
extension Mnemonic {
	public static let testValueZooVote = try! Self(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote")
	public static let testValueAbandonArt = try! Self(phrase: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art")
}
#endif // DEBUG
