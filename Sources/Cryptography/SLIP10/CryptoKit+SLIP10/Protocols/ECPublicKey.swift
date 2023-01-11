import Foundation

public protocol ECPublicKey {
	var rawRepresentation: Data { get }
	var compressedRepresentation: Data { get }

	// We deliberately are NOT using `compactRepresentation` label, since for P256
	// it is kind of broken, because we can only provide 32 bytes, i.e. the X coordinate
	// and it results in wrong key, so we want to use `x963Representation` for P256.
	init<Bytes>(compressedRepresentation: Bytes) throws where Bytes: ContiguousBytes

	init<D>(uncompressedRepresentation: D) throws where D: ContiguousBytes
}
