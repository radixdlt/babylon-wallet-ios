import Foundation

extension P2P.RTCMessageFromPeer {
	public func responseLedgerHardwareWallet() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet {
		guard case let .response(.connectorExtension(.ledgerHardwareWallet(response)), _) = self else {
			throw WrongResponseType()
		}

		return response
	}

	public func ledgerHardwareWalletSuccess() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success {
		let ledgerHardwareWallet = try responseLedgerHardwareWallet()
		return try ledgerHardwareWallet.response.get()
	}

	public func getDeviceInfoResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.GetDeviceInfo {
		let success = try ledgerHardwareWalletSuccess()
		guard let deviceInfo = success.getDeviceInfo else {
			throw WrongResponseType()
		}
		return deviceInfo
	}

	public func signTransactionResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.SignTransaction {
		let success = try ledgerHardwareWalletSuccess()
		guard let signTransaction = success.signTransaction else {
			throw WrongResponseType()
		}
		return signTransaction
	}

	public func derivePublicKeyResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.DerivePublicKey {
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
