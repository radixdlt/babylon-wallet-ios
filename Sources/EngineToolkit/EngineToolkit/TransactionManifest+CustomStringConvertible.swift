import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - TransactionManifest + CustomStringConvertible
extension TransactionManifest: CustomStringConvertible {}

public extension TransactionManifest {
	enum BlobOutputFormat {
		case excludeBlobs
		case includeBlobsByByteCountOnly
		case includeBlobs
		/// Blob + SHA256.twice hash of blob
		case includeBlobsWithHash
		public static let `default`: Self = .includeBlobsByByteCountOnly
	}

	internal static func toStringInstructions(
		_ instructions: ManifestInstructions,
		// If instructions are on JSON format we stringify them, which requires blobs (convertManifest)
		in manifest: TransactionManifest,
		networkID: NetworkID,
		separator: String = "\n",
		argumentSeparator: String = "\n\t"
	) -> String {
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

		case let .json(instructionsOnJSONFormat):
			// We dont wanna print JSON, so we go through conversion to STRING first
			func stringifyManifest(networkForRequest: NetworkID) throws -> TransactionManifest {
				try EngineToolkit()
					.convertManifest(
						request: .init(
							transactionVersion: .default,
							manifest: manifest, // need blobs
							// Wanna convert from Self (`.json`) -> ManifestInstrictions.string
							outputFormat: .string,
							networkId: networkForRequest
						)
					)
					.get()
			}

			let stringifiedManifest: TransactionManifest? = {
				do {
					return try stringifyManifest(networkForRequest: networkID)
				} catch {
					// maybe NetworkMismatchError...
					for networkForRequest in NetworkID.all(but: networkID) {
						do {
							return try stringifyManifest(networkForRequest: networkForRequest)
						} catch {
							continue
						}
					}
					return nil
				}
			}()
			guard let stringifiedManifest else {
				// We fail to stringify JSON instructions..
				return String(describing: instructionsOnJSONFormat)
			}

			// Recursively call `toString` on `stringifiedSelf`, with original arguments intact.
			return Self.toStringInstructions(
				stringifiedManifest.instructions, // Use newly stringified instructions!
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
	) -> String {
		Self.toStringInstructions(
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
				let hash = Data(SHA256.twice(data: blob))
				let hashHex = hash.hex
				return "\(label)[\(index)] hash = \(hashHex):\n\(blob.hex)\n"
			}.joined(separator: separator)
		}
		guard !body.isEmpty else {
			return ""
		}
		return [preamble, body].joined()
	}

	func toString(
		preamble: String = "~~~ MANIFEST ~~~\n",
		blobOutputFormat: BlobOutputFormat = .default,
		blobSeparator: String = "\n",
		blobPreamble: String = "BLOBS\n",
		blobLabel: String = "BLOB\n",
		instructionsSeparator: String = "\n\n",
		instructionsArgumentSeparator: String = "\n\t",
		networkID: NetworkID
	) -> String {
		let instructionsString = toStringInstructions(
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

	var description: String {
		// Best we can do is default to the primary network given the roadmap.
		toString(networkID: .hammunet)
	}

	func accountsRequiredToSign(
		networkId: NetworkID,
		version: TXVersion = .default
	) throws -> Set<ComponentAddress> {
		let convertedManifest = try EngineToolkit().convertManifest(request: ConvertManifestRequest(
			transactionVersion: version,
			manifest: self,
			outputFormat: .json,
			networkId: networkId
		)).get()

		switch convertedManifest.instructions {
		case let .json(instructions):
			var accountsRequiredToSign: Set<ComponentAddress> = []
			for instruction in instructions {
				switch instruction {
				case let .callMethod(callMethodInstruction):
					let isAccountComponent = callMethodInstruction.receiver.isAccountComponent()
					let isMethodThatRequiresAuth = [
						"lock_fee",
						"lock_contingent_fee",
						"withdraw",
						"withdraw_by_amount",
						"withdraw_by_ids",
						"lock_fee_and_withdraw",
						"lock_fee_and_withdraw_by_amount",
						"lock_fee_and_withdraw_by_ids",
						"create_proof",
						"create_proof_by_amount",
						"create_proof_by_ids",
					].contains(callMethodInstruction.methodName)

					if isAccountComponent, isMethodThatRequiresAuth {
						switch callMethodInstruction.receiver {
						case let .componentAddress(componentAddress):
							accountsRequiredToSign.insert(componentAddress)
						case .component:
							// TODO: The RENodeId should be translated to an account component
							// address and added to the set
							break
						}
					}

				default:
					break
				}
			}

			return accountsRequiredToSign
		case .string:
			throw SborDecodeError(value: "Impossible case") // TODO: need a better error
		}
	}
}
