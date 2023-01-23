import Foundation

// MARK: - GatherFactorPurpose
public enum GatherFactorPurpose: Sendable, Hashable {
	case sign(Sign)
	case derivePublicKey(DerivePublicKey)

	public enum DerivePublicKey: Sendable, Hashable {
		case createAccount(AccountHierarchicalDeterministicDerivationPath)
		case createPersona(IdentityHierarchicalDeterministicDerivationPath)
	}

	public struct Sign: Sendable, Hashable {
		public let mode: SignMode

		// Can this ever be nil?
		public let derivationPath: DerivationPath

		public let payloadToSign: Data
		public let expectedPublicKeyOfSigner: SLIP10.PublicKey

		public init(
			mode: SignMode,
			payloadToSign: Data,
			expectedPublicKeyOfSigner: SLIP10.PublicKey,
			derivationPath: DerivationPath
		) {
			self.mode = mode
			self.payloadToSign = payloadToSign
			self.expectedPublicKeyOfSigner = expectedPublicKeyOfSigner
			self.derivationPath = derivationPath
		}
	}

	public enum SignMode: Sendable, Hashable {
		case transaction(SignTransaction)

		/// Proof of ownership of account
		case proofOfOwnership

		public enum SignTransaction: Sendable, Hashable {
			case fromDapp
			case fromFallet(FromWallet)

			public enum FromWallet: Sendable, Hashable {
				case transfer
				// FIXME: put behind Alpha/Beta flag in future
				case faucet
				case securitize(Securitize)

				public enum Securitize: Sendable, Hashable {
					case account
					case persona
				}
			}
		}
	}
}

import Cryptography
import FeaturePrelude

// MARK: - GatherFactorsResult
public struct GatherFactorsResult: Sendable, Hashable {
	public let purpose: GatherFactorPurpose
	public let results: OrderedSet<GatherFactorResult>
	public init(purpose: GatherFactorPurpose, results: OrderedSet<GatherFactorResult>) throws {
		switch purpose {
		case let .sign(sign):
			guard results.allSatisfy({ $0.matches(toSign: sign) }) else {
				struct InvalidSignatureResult: Swift.Error {}
				throw InvalidSignatureResult()
			}
		// all good
		case let .derivePublicKey(derive):
			guard results.allSatisfy({ $0.matches(publicKeyDerivation: derive) }) else {
				struct InvalidDerivation: Swift.Error {}
				throw InvalidDerivation()
			}
			// all good
		}

		self.purpose = purpose
		self.results = results
	}
}

// MARK: - GatherFactorResult
public enum GatherFactorResult: Sendable, Hashable {
	case signedPayload(SignedPayload)
	case publicKey(SLIP10.PublicKey)
	func matches(toSign: GatherFactorPurpose.Sign) -> Bool {
		switch self {
		case let .signedPayload(signedPayload):
			return signedPayload.matches(toSign: toSign)
		case .publicKey: return false
		}
	}

	func matches(publicKeyDerivation: GatherFactorPurpose.DerivePublicKey) -> Bool {
		switch self {
		case .publicKey:
			return true // we are unable to do more validation than this.
		case .signedPayload: return false
		}
	}
}

// MARK: - SignedPayload
public struct SignedPayload: Sendable, Hashable {
	public let signature: SLIP10.Signature
	public let publicKey: SLIP10.PublicKey
	public let messageThatWasSigned: Data
	init(
		signature: SLIP10.Signature,
		publicKey: SLIP10.PublicKey,
		messageThatWasSigned: Data
	) throws {
		guard publicKey.isValidSignature(signature, for: messageThatWasSigned) else {
			struct InvalidSignature: Swift.Error {}
			throw InvalidSignature()
		}
		self.signature = signature
		self.publicKey = publicKey
		self.messageThatWasSigned = messageThatWasSigned
	}

	func matches(toSign: GatherFactorPurpose.Sign) -> Bool {
		toSign.payloadToSign == messageThatWasSigned &&
			toSign.expectedPublicKeyOfSigner == publicKey &&
			toSign.expectedPublicKeyOfSigner.isValidSignature(self.signature, for: toSign.payloadToSign)
	}
}

#if DEBUG
public extension GatherFactorPurpose {
	static let previewValue: Self = try! .derivePublicKey(.createAccount(.init(networkID: .nebunet, index: 0, keyKind: .transactionSigningKey)))
}
#endif
