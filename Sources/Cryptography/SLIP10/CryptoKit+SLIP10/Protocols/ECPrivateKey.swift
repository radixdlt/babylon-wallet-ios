import Foundation

public protocol ECPrivateKey {
	associatedtype PublicKey: ECPublicKey
	var publicKey: PublicKey { get }
	var rawRepresentation: Data { get }
	init<D>(rawRepresentation data: D) throws where D: ContiguousBytes
}
