import Foundation

extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success {
	public var getDeviceInfo: GetDeviceInfo? {
		guard case let .getDeviceInfo(payload) = self else {
			return nil
		}
		return payload
	}

	public var signTransaction: SignTransaction? {
		guard case let .signTransaction(payload) = self else {
			return nil
		}
		return payload
	}

	public var derivePublicKey: DerivePublicKey? {
		guard case let .derivePublicKey(payload) = self else {
			return nil
		}
		return payload
	}
}
