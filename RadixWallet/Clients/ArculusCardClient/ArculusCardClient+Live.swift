import ComposableArchitecture
import Sargon

extension ArculusCardClient: DependencyKey {
	typealias Value = ArculusCardClient

	static let liveValue: Self = .init(
		validateMinFirmwareVersion: {
			try await SargonOS.shared.arculusCardValidateMinFirmwareVersion()
		},
		derivePublicKeys: { factorSource, paths in
			try await SargonOS.shared.arculusCardDerivePublicKeys(
				factorSource: factorSource,
				paths: paths
			)
		},
		signTransaction: { factorSource, pin, perTransaction in
			try await SargonOS.shared.arculusCardSignTransaction(
				factorSource: factorSource,
				pin: pin,
				perTransaction: perTransaction
			)
		},
		signSubintent: { factorSource, pin, perTransaction in
			try await SargonOS.shared.arculusCardSignSubintent(
				factorSource: factorSource,
				pin: pin,
				perTransaction: perTransaction
			)
		},
		signAuth: { factorSource, pin, perTransaction in
			try await SargonOS.shared.arculusCardSignAuth(
				factorSource: factorSource,
				pin: pin,
				perTransaction: perTransaction
			)
		},
		configureCardWithMnemonic: { mnemonic, pin in
			_ = try await SargonOS.shared.arculusCardConfigureWithMnemonic(
				mnemonic: mnemonic,
				pin: pin
			)
		},
		verifyPin: { factorSource, pin in
			try await SargonOS.shared.verifyCardPin(factorSource: factorSource, pin: pin)
		},
		setPin: { factorSource, oldPin, newPin in
			try await SargonOS.shared.setCardPin(factorSource: factorSource, oldPin: oldPin, newPin: newPin)
		}
	)
}
