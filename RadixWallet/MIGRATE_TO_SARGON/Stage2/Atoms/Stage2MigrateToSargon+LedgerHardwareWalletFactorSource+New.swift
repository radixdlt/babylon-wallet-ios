import Foundation
import Sargon

extension LedgerHardwareWalletFactorSource {
	static func from(
		device: LedgerDeviceInfo,
		name: String
	) throws -> Self {
		try model(
			.init(model: device.model),
			name: name,
			body: .init(bytes: device.id.data)
		)
	}
}

extension LedgerHardwareWalletFactorSource {
	/// Creates a factor source of `.ledger` kind with the specified
	/// Ledger model, name and `deviceID` (hash of public key)
	public static func model(
		_ model: LedgerHardwareWalletModel,
		name: String,
		body: Exactly32Bytes
	) throws -> Self {
		try .init(
			id: .init(kind: .ledgerHqHardwareWallet, body: body),
			common: .new(
				// We MUST always save a Ledger with Babylon AND Olympia crypto parameters
				// since most users typically only have one Ledger, and Olympia users must
				// be able to import from Olympia wallet, which requires Olympia crypto
				// parameters, and these user must also be able to later derive new Babylon
				// accounts using the same Ledger, thus the FactorSource must have Babylon
				// crypto parameters as well (since user is unable to "edit FactorSource").
				cryptoParameters: .babylonOlympiaCompatible
			),
			hint: .init(name: name, model: model)
		)
	}
}
