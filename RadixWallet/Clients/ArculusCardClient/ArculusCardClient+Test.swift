import ComposableArchitecture
import Sargon

extension ArculusCardClient {
	static let testValue = Self(
		validateMinFirmwareVersion: unimplemented("\(Self.self).validateMinFirmwareVersion"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys"),
		signTransaction: unimplemented("\(Self.self).signTransaction"),
		signSubintent: unimplemented("\(Self.self).signSubintent"),
		signAuth: unimplemented("\(Self.self).signAuth"),
		configureCardWithMnemonic: unimplemented("\(Self.self).configureCardWithMnemonic")
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
		}
	)
}
