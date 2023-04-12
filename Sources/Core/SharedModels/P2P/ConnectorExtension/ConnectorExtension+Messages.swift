import Foundation

extension P2P.RTCIncomingMessage {
	public func ledgerNanoSuccess() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success {
		let result = try self.peerMessage.result.get()
		switch result {
		case let .connectorExtension(.ledgerHardwareWallet(ledgerNanoResult)):
			return try ledgerNanoResult.response.get()
		default: throw WrongResponseType()
		}
	}

	public func getDeviceInfoResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.GetDeviceInfo {
		let success = try ledgerNanoSuccess()
		guard let deviceInfo = success.getDeviceInfo else {
			throw WrongResponseType()
		}
		return deviceInfo
	}

	public func signTransactionResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.SignTransaction {
		let success = try ledgerNanoSuccess()
		guard let signTransaction = success.signTransaction else {
			throw WrongResponseType()
		}
		return signTransaction
	}

	public func derivePublicKeyResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.DerivePublicKey {
		let success = try ledgerNanoSuccess()
		guard let derivePublicKey = success.derivePublicKey else {
			throw WrongResponseType()
		}
		return derivePublicKey
	}
}

// MARK: - WrongResponseType
struct WrongResponseType: Swift.Error {}

extension P2P.FromConnectorExtension.LedgerHardwareWallet.Success {
	public var getDeviceInfo: GetDeviceInfo? {
		guard case let .getDeviceInfo(wrapped) = self else {
			return nil
		}
		return wrapped
	}

	public var signTransaction: SignTransaction? {
		guard case let .signTransaction(wrapped) = self else {
			return nil
		}
		return wrapped
	}

	public var derivePublicKey: DerivePublicKey? {
		guard case let .derivePublicKey(wrapped) = self else {
			return nil
		}
		return wrapped
	}
}
