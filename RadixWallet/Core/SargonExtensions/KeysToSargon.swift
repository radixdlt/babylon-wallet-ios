import Foundation
import Sargon
import SargonUniFFI
public typealias TXID = IntentHash

extension TXID {
	public func formatted(_ format: AddressFormat = .default) -> String {
		//        self.bech32EncodedTxId
		fatalError("Sargon migration")
	}
}

extension SignedIntent {
	public func hash() -> SignedIntentHash {
		fatalError("Sargon migration")
	}
}

extension SLIP10.PublicKey {
	public func intoSargon() -> Sargon.PublicKey {
		try! Sargon.PublicKey(bytes: self.compressedData)
	}
}

extension SLIP10.Signature {
	public func intoSargon() -> Sargon.Signature {
		fatalError("Sargon migration")
	}
}

extension K1.PublicKey {
	public func intoSargon() -> Sargon.Secp256k1PublicKey {
		fatalError("Sargon migration")
	}
}

extension SignatureWithPublicKey {
	public func intoSargon() -> Sargon.SignatureWithPublicKey {
		fatalError("Sargon migration")
	}
}
