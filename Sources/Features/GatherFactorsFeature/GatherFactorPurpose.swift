import Foundation

// MARK: - GatherFactorPurpose_
public enum GatherFactorPurpose_: Sendable, Hashable {
	case sign(SignPurpose)
	case derivePublicKey(DerivePublicKey)

	public enum DerivePublicKey: Sendable, Hashable {
		case createAccount
		case createPersona
	}

	public enum SignPurpose: Sendable, Hashable {
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

// MARK: - GatherFactorPurposeProtocol
public protocol GatherFactorPurposeProtocol: Sendable, Equatable {
	associatedtype Produce: Sendable & Equatable
	var purpose: GatherFactorPurpose_ { get }
}

// MARK: - GatherFactorPurposeDerivePublicKey
public struct GatherFactorPurposeDerivePublicKey: GatherFactorPurposeProtocol {
	public typealias Produce = SLIP10.PublicKey
	public let purpose: GatherFactorPurpose_
	public init(purpose: GatherFactorPurpose_.DerivePublicKey) {
		self.purpose = .derivePublicKey(purpose)
	}
}

// MARK: - GatherFactorPurposeSign
// public enum GatherFactorPurposeDerivePublicKey: GatherFactorPurposeProtocol {
//    public typealias Produce = SLIP10.PublicKey
//    public var purpose: GatherFactorPurpose_ {
//        switch self {
//        case .createAccount: return .derivePublicKey(.createAccount)
//        case .createPersona: return .derivePublicKey(.createPersona)
//        }
//    }
//    case createAccount(AccountHierarchicalDeterministicDerivationPath)
//    case createPersona(IdentityHierarchicalDeterministicDerivationPath)
// }

public struct GatherFactorPurposeSign: GatherFactorPurposeProtocol, Sendable, Hashable {
	public typealias Produce = SignedPayload
	public var purpose: GatherFactorPurpose_ { .sign(signPurpose) }
	public let signPurpose: GatherFactorPurpose_.SignPurpose

	// Can this ever be nil?
	public let derivationPath: DerivationPath

	public let payloadToSign: Data
	public let expectedPublicKeyOfSigner: SLIP10.PublicKey

	public init(
		signPurpose: GatherFactorPurpose_.SignPurpose,
		payloadToSign: Data,
		expectedPublicKeyOfSigner: SLIP10.PublicKey,
		derivationPath: DerivationPath
	) {
		self.signPurpose = signPurpose
		self.payloadToSign = payloadToSign
		self.expectedPublicKeyOfSigner = expectedPublicKeyOfSigner
		self.derivationPath = derivationPath
	}
}

import Cryptography
import FeaturePrelude

// MARK: - SignedPayload
//// MARK: - GatherFactorResult
// public enum GatherFactorResult: Sendable, Hashable {
//	case signedPayload(SignedPayload)
//	case publicKey(SLIP10.PublicKey)
//	func matches(toSign: GatherPurposeSign) -> Bool {
//		switch self {
//		case let .signedPayload(signedPayload):
//			return signedPayload.matches(toSign: toSign)
//		case .publicKey: return false
//		}
//	}
//
//	func matches(publicKeyDerivation: GatherFactorPurpose_.DerivePublicKey) -> Bool {
//		switch self {
//		case .publicKey:
//			return true // we are unable to do more validation than this.
//		case .signedPayload: return false
//		}
//	}
// }

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

	func matches(toSign: GatherFactorPurposeSign) -> Bool {
		toSign.payloadToSign == messageThatWasSigned &&
			toSign.expectedPublicKeyOfSigner == publicKey &&
			toSign.expectedPublicKeyOfSigner.isValidSignature(self.signature, for: toSign.payloadToSign)
	}
}

#if DEBUG
public extension GatherFactorPurpose_ {
	static let previewValue: Self = .derivePublicKey(.createAccount)
}
#endif
