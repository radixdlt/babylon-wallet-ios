import ComposableArchitecture
import Sargon

extension ArculusCardClient {
	static let testValue = Self(
		validateMinFirmwareVersion: unimplemented("\(Self.self).validateMinFirmwareVersion"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys"),
		signTransaction: unimplemented("\(Self.self).signTransaction"),
		signSubintent: unimplemented("\(Self.self).signSubintent"),
		signAuth: unimplemented("\(Self.self).signAuth"),
		configureCardWithMnemonic: unimplemented("\(Self.self).configureCardWithMnemonic"),
		verifyPin: unimplemented("\(Self.self).verifyPin"),
		setPin: unimplemented("\(Self.self).setPin"),
	)

	static let noop = Self(
		validateMinFirmwareVersion: {
			ArculusMinFirmwareVersionRequirement.valid
		},
		derivePublicKeys: { _, _ in
			[]
		},
		signTransaction: { _, _, _ in
			[]
		},
		signSubintent: { _, _, _ in
			[]
		},
		signAuth: { _, _, _ in
			[]
		},
		configureCardWithMnemonic: { _, _ in
			// no-op
		},
		verifyPin: { _, _ in
		},
		setPin: { _, _, _ in
		}
	)
}
