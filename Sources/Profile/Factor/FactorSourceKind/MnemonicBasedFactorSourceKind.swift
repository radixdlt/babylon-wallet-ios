
// MARK: - MnemonicBasedFactorSourceKind
public enum MnemonicBasedFactorSourceKind: Sendable, Hashable {
	public enum OnDeviceMnemonicKind: Sendable, Hashable {
		case babylon
		case olympia
	}

	case onDevice(OnDeviceMnemonicKind)
	case offDevice

	public var factorSourceKind: FactorSourceKind {
		switch self {
		case .offDevice: return .offDeviceMnemonic
		case .onDevice: return .device
		}
	}
}
