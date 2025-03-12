extension Error {
	var isUserCanceledKeychainAccess: Bool {
		guard let error = self as? KeychainAccess.Status else {
			return false
		}
		return error == .userCanceled
	}

	var isUserRejectedSigningOnLedgerDevice: Bool {
		guard let error = self as? P2P.ConnectorExtension.Response.LedgerHardwareWallet.Failure else {
			return false
		}
		return error.code == .userRejectedSigningOfTransaction
	}

	var isHostInteractionAborted: Bool {
		guard let error = self as? CommonError else {
			return false
		}
		return error == CommonError.HostInteractionAborted
	}
}
