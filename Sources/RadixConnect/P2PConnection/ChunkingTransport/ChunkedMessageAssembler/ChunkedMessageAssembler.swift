import P2PModels
import Prelude

// MARK: - ChunkedMessagePackageAssembler
public final class ChunkedMessagePackageAssembler: Sendable {
	public init() {}
}

// MARK: - AssembledMessage
public struct AssembledMessage: Sendable, Hashable {
	public let messageContent: Data
	public let messageHash: Data
}

extension ChunkedMessagePackageAssembler {
	public typealias Error = ConverseError.ChunkingTransportError.AssemblerError

	public func assemble(packages: [ChunkedMessagePackage]) throws -> AssembledMessage {
		guard
			!packages.isEmpty
		else {
			loggerGlobal.error("'packages' array is empty, not allowed.")
			throw Error.parseError(.noPackages)
		}

		if let receiveMessageError = packages.compactMap(\.receiveMessageError).first {
			loggerGlobal.error("'packages' contained receiveMessageError: \(String(describing: receiveMessageError))")
			throw Error.foundReceiveMessageError(receiveMessageError)
		}

		let filterMetaDataPkg: (ChunkedMessagePackage) -> Bool = { $0.packageType == .metaData }

		guard
			let indexOfMetaData = packages.firstIndex(where: filterMetaDataPkg)
		else {
			loggerGlobal.error("No MetaData package in 'packages', which is required.")
			throw Error.parseError(.noMetaDataPackage)
		}

		let metaDataWasFirstInList = indexOfMetaData == 0
		if !metaDataWasFirstInList {
			loggerGlobal.warning("MetaData was not first package in array, either other client are sending packages in incorrect order, or we have received them over the communication channel in the wrong order. We will try to reorder them.")
		}

		guard
			packages.filter(filterMetaDataPkg).count == 1
		else {
			loggerGlobal.error("Found multiple MetaData packages, this is invalid.")
			throw Error.parseError(.foundMultipleMetaDataPackages)
		}

		guard
			case let .metaData(metaDataPackage) = packages[indexOfMetaData]
		else {
			let errorMsg = "Have asserted that package at index: \(indexOfMetaData) IS a MetaData package, bad logic somewhere."
			loggerGlobal.error(.init(stringLiteral: errorMsg))
			throw Error.parseError(.foundMultipleMetaDataPackages)
		}

		guard metaDataPackage.chunkCount > 0 else {
			loggerGlobal.error("MetaData package states a chunkCount of 0. This is not allowed. Client is sending corrupt data.")
			throw Error.parseError(.metaDataPackageStatesZeroChunkPackages)
		}

		let expectedHash = metaDataPackage.hashOfMessage.data
		let chunkCount = metaDataPackage.chunkCount

		// Mutable since we allow incorrect ordering of chunked packages, and sort on index.
		var chunkedPackages: [ChunkedMessageChunkPackage] = packages.compactMap(\.chunk)

		guard chunkedPackages.count == chunkCount else {
			loggerGlobal.error("Invalid number of chunked packages, metadata package states: #\(chunkCount) but got: #\(chunkedPackages.count).")
			throw Error.parseError(.invalidNumberOfChunkedPackages(
				got: chunkedPackages.count,
				butMetaDataPackageStated: chunkCount
			))
		}

		assert(chunkedPackages.count > 0, "We should have check that number of chunked packages are greater than zero above. Code below will fail otherwise.")

		let indices = chunkedPackages.map(\.chunkIndex)
		let expectedOrderOfIndices = ((0 ..< chunkCount).map { $0 })
		let indicesDifference = Set(indices).symmetricDifference(Set(expectedOrderOfIndices))
		guard indicesDifference.isEmpty else {
			loggerGlobal.error("Incorrect indices of chunked packages, got difference: \(indicesDifference)")
			throw Error.parseError(.incorrectIndicesOfChunkedPackages)
		}

		let chunkedPackagesWereOrdered = indices == expectedOrderOfIndices
		if !chunkedPackagesWereOrdered {
			// Chunked packages are not ordered properly
			loggerGlobal.warning("Chunked packages are not ordered, either other client are sending packages in incorrect order, or we have received them over the communication channel in the wrong order. We will reorder them.")
			chunkedPackages.sort(by: <)
		}

		let message = chunkedPackages.map(\.chunkData).reduce(Data(), +)

		guard message.count == metaDataPackage.messageByteCount else {
			loggerGlobal.error("Re-assembled message has #\(message.count) bytes, but MetaData package stated a message byte count of: #\(metaDataPackage.messageByteCount) bytes.")
			throw Error.messageByteCountMismatch(
				got: message.count,
				butMetaDataPackageStated: metaDataPackage.messageByteCount
			)
		}

		let hash = try RadixHasher.hash(data: message)
		guard hash == expectedHash else {
			let hashHex = hash.hex()
			let expectedHashHex = expectedHash.hex()
			loggerGlobal.critical("Hash of re-assembled message differs from expected one. Calculated hash: '\(hashHex)', but MetaData package stated: '\(expectedHashHex)'.")
			throw Error.hashMismatch(
				calculated: hashHex,
				butExpected: expectedHashHex
			)
		}

		return AssembledMessage(messageContent: message, messageHash: hash)
	}
}
