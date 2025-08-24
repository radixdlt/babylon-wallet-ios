import ComposableArchitecture
import Sargon

// MARK: - ArculusCardClient
struct ArculusCardClient: Sendable {
	var validateMinFirmwareVersion: ValidateMinFirmwareVersion
	var derivePublicKeys: DerivePublicKeys
	var signTransaction: SignTransaction
	var signSubintent: SignSubintent
	var signAuth: SignAuth
	var configureCardWithMnemonic: ConfigureCardWithMnemonic
	var restoreCardPin: RestoreCardPin
	var verifyPin: VerifyPin
	var setPin: SetPin
}

extension ArculusCardClient {
	typealias ValidateMinFirmwareVersion = @Sendable () async throws -> ArculusMinFirmwareVersionRequirement

	typealias DerivePublicKeys = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ paths: [DerivationPath]
	) async throws -> [HierarchicalDeterministicFactorInstance]

	typealias SignTransaction = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ pin: String,
		_ perTransaction: [TransactionSignRequestInputOfTransactionIntent]
	) async throws -> [HdSignatureOfTransactionIntentHash]

	typealias SignSubintent = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ pin: String,
		_ perTransaction: [TransactionSignRequestInputOfSubintent]
	) async throws -> [HdSignatureOfSubintentHash]

	typealias SignAuth = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ pin: String,
		_ perTransaction: [TransactionSignRequestInputOfAuthIntent]
	) async throws -> [HdSignatureOfAuthIntentHash]

	typealias ConfigureCardWithMnemonic = @Sendable (
		_ mnemonic: Mnemonic,
		_ pin: String
	) async throws -> Void

	typealias RestoreCardPin = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ mnemonic: Mnemonic,
		_ newPin: String
	) async throws -> Void

	typealias VerifyPin = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ pin: String
	) async throws -> Void

	typealias SetPin = @Sendable (
		_ factorSource: ArculusCardFactorSource,
		_ oldPIN: String,
		_ newPIN: String
	) async throws -> Void
}

extension DependencyValues {
	var arculusCardClient: ArculusCardClient {
		get { self[ArculusCardClient.self] }
		set { self[ArculusCardClient.self] = newValue }
	}
}
