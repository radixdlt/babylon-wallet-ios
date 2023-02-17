import Cryptography
import Prelude

public extension FactorSource {
	/// The `id` and `model` must be obtained from the device itself by connecting it to
	/// a desktop with a browser with Radix Connector Extension installed and following the
	/// steps in the extension and in the wallet.
	static func ledgerHardwareWallet(
		id: FactorSourceID,
		model: LedgerHardwareModel
	) -> Self {
		Self(
			kind: .ledgerHQHardwareWallet,
			id: id,
			hint: model.hint,
			parameters: .olympiaBackwardsCompatible
		)
	}
}
