import struct CryptoKit.SHA256
import Foundation
import Mnemonic
import SLIP10

// MARK: - OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
public protocol OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource:
	FactorSourceNonHardwareHierarchicalDeterministicProtocol,
	SLIP10FactorSourceHierarchicalDeterministicProtocol
	where
	CreateFactorInstanceInput == CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
{
	func createInstance(input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput) async throws -> CreateFactorInstanceWithKey<Instance>
}

public extension OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	func createAnyFactorInstanceForResponse(
		input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	) async throws -> AnyCreateFactorInstanceForResponse {
		try await Self.createInstance(
			factorSourceReference: reference,
			createInstanceInput: input
		).eraseToAny()
	}

	func createInstance(
		input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	) async throws -> CreateFactorInstanceWithKey<Instance> {
		try await Self.createInstance(
			factorSourceReference: reference,
			createInstanceInput: input
		)
	}

	static func createInstance(
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

		let privateKey: PrivateKey? = { () -> PrivateKey? in
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
