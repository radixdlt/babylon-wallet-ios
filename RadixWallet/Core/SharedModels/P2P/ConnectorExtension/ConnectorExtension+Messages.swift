
extension P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success {
	var getDeviceInfo: GetDeviceInfo? {
		guard case let .getDeviceInfo(payload) = self else {
			return nil
		}
		return payload
	}

	var signTransaction: [SignatureOfSigner]? {
		guard case let .signTransaction(payload) = self else {
			return nil
		}
		return payload
	}

	var derivedPublicKeys: [DerivedPublicKey]? {
		guard case let .derivePublicKeys(payload) = self else {
			return nil
		}
		return payload
	}
}
