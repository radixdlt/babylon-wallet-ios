import Foundation
import Sargon

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
