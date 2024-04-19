import Foundation
import Sargon

extension MnemonicWithPassphrase {
	public func toSeed() -> BIP39Seed {
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - MnemonicWithPassphrase + Codable
extension MnemonicWithPassphrase: Codable {
	public init(from decoder: any Decoder) throws {
		fatalError()
	}

	public func encode(to encoder: any Encoder) throws {
		fatalError()
	}
}

// Move elsewhere?
extension MnemonicWithPassphrase {
	@discardableResult
	public func validatePublicKeys(
		of softwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
	) throws -> Bool {
		try validatePublicKeys(
			of: softwareAccounts.map {
				(
					path: $0.path.path,
					expectedPublicKey: $0.publicKey.asGeneral
				)
			}
		)
	}

	@discardableResult
	public func validatePublicKeys(
		of accounts: some Collection<Sargon.Account>
	) throws -> Bool {
		try validatePublicKeys(
			of: accounts.flatMap { account in
				account.virtualHierarchicalDeterministicFactorInstances.map {
					(
						path: $0.derivationPath.path,
						expectedPublicKey: $0.publicKey.publicKey
					)
				}
			}
		)
	}

	@discardableResult
	public func validatePublicKeys(
		of accounts: [(path: HDPath, expectedPublicKey: Sargon.PublicKey)]
	) throws -> Bool {
		/*
		 //		let bip39Seed = self.toSeed()
		 //
		 //		for (path, publicKey) in accounts {
		 //			let derivedPublicKey: Sargon.PublicKey = switch publicKey.curve {
		 //			case .secp256k1:
		 //				try .secp256k1(hdRoot.derivePrivateKey(
		 //					path: path,
		 //					curve: SECP256K1.self
		 //				).publicKey)
		 //			case .curve25519:
		 //				try .eddsaEd25519(hdRoot.derivePrivateKey(
		 //					path: path,
		 //					curve: Curve25519.self
		 //				).publicKey)
		 //			}
		 //
		 //			guard derivedPublicKey == publicKey else {
		 //				throw ValidateMnemonicAgainstEntities.publicKeyMismatch
		 //			}
		 //		}
		 //		// PublicKeys matches
		 //		return true
		 */
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}

// MARK: - ValidateMnemonicAgainstEntities
enum ValidateMnemonicAgainstEntities: LocalizedError {
	case publicKeyMismatch
}
