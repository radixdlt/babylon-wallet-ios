import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - TransactionManifest + CustomStringConvertible
extension TransactionManifest: CustomStringConvertible {}

extension TransactionManifest {
	public enum BlobOutputFormat {
		case excludeBlobs
		case includeBlobsByByteCountOnly
		case includeBlobs
		/// Blob + Blake hash of blob
		case includeBlobsWithHash
		public static let `default`: Self = .includeBlobsByByteCountOnly
	}

	public enum ManifestConversionError: Error {
		case networkMismatch(found: NetworkID?, expected: NetworkID?)
		case manifestGeneration(messsage: String?)
		case unknown(type: String)

		public init?(error: Error) {
			guard case let .deserializeResponseFailure(.errorResponse(json)) = error as? EngineToolkit.Error else { return nil }
			guard let errorType = json["error"]?.string else { return nil }
			switch errorType {
			case "NetworkMismatchError":
				func networkID(_ key: String) -> NetworkID? {
					json[key]?.int
						.map { NetworkID(rawValue: UInt8($0)) }
				}
				self = .networkMismatch(found: networkID("found"), expected: networkID("expected"))
			case "ManifestGenerationError":
				self = .manifestGeneration(messsage: json["message"]?.string)
			default:
				self = .unknown(type: errorType)
			}
		}
	}

	internal static func toStringInstructions(
		_ instructions: ManifestInstructions,
		// If instructions are on JSON format we stringify them, which requires blobs (convertManifest)
		in manifest: TransactionManifest,
		networkID: NetworkID,
		separator: String = "\n",
		argumentSeparator: String = "\n\t"
	) throws -> String {
		switch instructions {
		case let .string(manifestString):

			var manifestString = manifestString.trimWhitespacesIncludingNullTerminators()
			if manifestString.hasSuffix(";") {
				manifestString.removeLast()
			}

			// Remove newline so that we can control number of newlines ourselves.
			let instructionsStringsWithoutNewline = manifestString
				.split(separator: ";")
				.map { $0.trimmingCharacters(in: .newlines) }
				.map { $0 + ";" } // Re-add ";"
				.map {
					// Make it possible to change separator between arguments inside the instruction
					$0.split(separator: " ").filter { !$0.isEmpty }.joined(separator: argumentSeparator)
				}

			return instructionsStringsWithoutNewline
				.joined(separator: separator)

		case .parsed:
			// We dont wanna print JSON, so we go through conversion to STRING first
			func stringifyManifest(networkForRequest: NetworkID) throws -> TransactionManifest {
				try EngineToolkit()
					.convertManifest(
						request: .init(
							manifest: manifest, // need blobs
							// Wanna convert from Self (`.parsed`) -> ManifestInstrictions.string
							outputFormat: .string,
							networkId: networkForRequest
						)
					)
					.get()
			}

			// If the chosen network is wrong, we will try with other networks
			func stringifiedManifest() throws -> TransactionManifest {
				do {
					return try stringifyManifest(networkForRequest: networkID)
				} catch {
					guard let conversionError = ManifestConversionError(error: error) else { throw error }
					guard case .networkMismatch = conversionError else { throw conversionError }

					for networkForRequest in NetworkID.all(but: networkID) {
						do {
							return try stringifyManifest(networkForRequest: networkForRequest)
						} catch {
							guard case .networkMismatch = ManifestConversionError(error: error) else { break }
							continue
						}
					}

					throw conversionError
				}
			}

			// Recursively call `toString` on `stringifiedSelf`, with original arguments intact.
			return try Self.toStringInstructions(
				stringifiedManifest().instructions, // Use newly stringified instructions!
				in: manifest, // Don't care,
				networkID: networkID,
				separator: separator, // passthrough
				argumentSeparator: argumentSeparator // passthrough
			)
		}
	}

	internal func toStringInstructions(
		separator: String = "\n",
		argumentSeparator: String = "\n\t",
		networkID: NetworkID
	) throws -> String {
		try Self.toStringInstructions(
			instructions,
			// If instructions are on JSON format we stringify them, which requires blobs (convertManifest)
			in: self,
			networkID: networkID,
			separator: separator,
			argumentSeparator: argumentSeparator
		)
	}

	internal func toStringBlobs(
		preamble: String = "BLOBS\n",
		label: String = "BLOB\n",
		formatting: BlobOutputFormat,
		separator: String = "\n"
	) -> String {
		let body: String
		switch formatting {
		case .excludeBlobs: return ""
		case .includeBlobsByByteCountOnly:
			body = blobs.lazy.enumerated().map { index, blob in
				"\(label)[\(index)]: #\(blob.count) bytes"
			}.joined(separator: separator)
		case .includeBlobs:
			body = blobs.lazy.enumerated().map { index, blob in
				"\(label)[\(index)]:\n\(blob.hex)\n"
			}.joined(separator: separator)
		case .includeBlobsWithHash:
			body = blobs.enumerated().map { index, blob in
				let hash = try! blake2b(data: blob)
				let hashHex = hash.hex
				return "\(label)[\(index)] hash = \(hashHex):\n\(blob.hex)\n"
			}.joined(separator: separator)
		}
		guard !body.isEmpty else {
			return ""
		}
		return [preamble, body].joined()
	}

	public func toString(
		preamble: String = "~~~ MANIFEST ~~~\n",
		blobOutputFormat: BlobOutputFormat = .default,
		blobSeparator: String = "\n",
		blobPreamble: String = "BLOBS\n",
		blobLabel: String = "BLOB\n",
		instructionsSeparator: String = "\n\n",
		instructionsArgumentSeparator: String = "\n\t",
		networkID: NetworkID
	) throws -> String {
		let instructionsString = try toStringInstructions(
			separator: instructionsSeparator,
			argumentSeparator: instructionsArgumentSeparator,
			networkID: networkID
		)

		let blobString = toStringBlobs(
			preamble: blobPreamble,
			label: blobLabel,
			formatting: blobOutputFormat,
			separator: blobSeparator
		)

		let manifestString = [preamble, instructionsString, blobString].joined()

		return manifestString
	}

	public var description: String {
		// Best we can do is default to the primary network given the roadmap.
		do {
			return try toString(networkID: .nebunet)
		} catch {
			return "Can't create description of manifest: \(error)"
		}
	}
}
