import Foundation

extension P2P.RTCMessageFromPeer {
	public func responseLedgerHardwareWallet() throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet {
		guard case let .response(.connectorExtension(.ledgerHardwareWallet(response))) = self else {
			throw WrongResponseType()
		}

		return response
	}

	public func ledgerHardwareWalletSuccess() throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success {
		let ledgerHardwareWallet = try responseLedgerHardwareWallet()
		return try ledgerHardwareWallet.response.get()
	}

	public func getDeviceInfoResponse() throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo {
		let success = try ledgerHardwareWalletSuccess()
		guard let deviceInfo = success.getDeviceInfo else {
			throw WrongResponseType()
		}
		return deviceInfo
	}

	public func signTransactionResponse() throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.SignTransaction {
		let success = try ledgerHardwareWalletSuccess()
		guard let signTransaction = success.signTransaction else {
			throw WrongResponseType()
		}
		return signTransaction
	}

	public func derivePublicKeyResponse() throws -> P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.DerivePublicKey {
		let success = try ledgerHardwareWalletSuccess()
		guard let derivePublicKey = success.derivePublicKey else {
			throw WrongResponseType()
		}
		return derivePublicKey
	}
}

// MARK: - WrongResponseType
struct WrongResponseType: Swift.Error {}

// MARK: - WrongRequestType
struct WrongRequestType: Swift.Error {}

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
