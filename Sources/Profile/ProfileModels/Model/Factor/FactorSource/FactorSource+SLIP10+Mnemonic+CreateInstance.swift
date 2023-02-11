import Cryptography
import Prelude

// MARK: - OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
public protocol OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource:
	FactorSourceNonHardwareHierarchicalDeterministicProtocol,
	SLIP10FactorSourceHierarchicalDeterministicProtocol
	where
	CreateFactorInstanceInput == CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
{
	func createInstance(input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput) async throws -> CreateFactorInstanceWithKey<Instance>
}

extension OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	public func createAnyFactorInstanceForResponse(
		input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	) async throws -> AnyCreateFactorInstanceForResponse {
		try await Self.createInstance(
			factorSourceReference: reference,
			createInstanceInput: input
		).eraseToAny()
	}

	public func createInstance(
		input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	) async throws -> CreateFactorInstanceWithKey<Instance> {
		try await Self.createInstance(
			factorSourceReference: reference,
			createInstanceInput: input
		)
	}

	public static func createInstance(
		factorSourceReference: FactorSourceReference,
		createInstanceInput input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	) async throws -> CreateFactorInstanceWithKey<Instance> {
		let hdRoot = try HD.Root(
			seed: input.mnemonic.seed(passphrase: input.bip39Passphrase)
		)

		let factorSourceID = try SHA256.factorSourceID(hdRoot: hdRoot, curve: Curve.self)

		guard factorSourceID == factorSourceReference.factorSourceID else {
			throw IncorrectKeyNotMatchingFactorSourceID()
		}

		let derivationPath = try input.derivationPath.hdFullPath()

		let key = try hdRoot.derivePrivateKey(
			path: derivationPath,
			curve: Curve.self
		)

		let instance = Instance(
			factorSourceReference: factorSourceReference,
			publicKey: Self.embedPublicKey(key.publicKey),
			derivationPath: input.derivationPath,
			initializationDate: Date()
		)

		let privateKey: SLIP10.PrivateKey? = { () -> SLIP10.PrivateKey? in
			guard input.includePrivateKey, let privateKey = key.privateKey else {
				return nil
			}
			return Self.embedPrivateKey(privateKey)
		}()

		return try CreateFactorInstanceWithKey(
			factorInstance: instance,
			privateKey: privateKey
		)
	}
}
