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

	static func toStringInstructions(
		_ instructions: Instructions,
		separator: String = "\n",
		argumentSeparator: String = "\n\t"
	) throws -> String {
		var manifestString = try instructions.asStr().trimWhitespacesIncludingNullTerminators()
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
	}

	func toStringInstructions(
		separator: String = "\n",
		argumentSeparator: String = "\n\t"
	) throws -> String {
		try Self.toStringInstructions(
			instructions(),
			separator: separator,
			argumentSeparator: argumentSeparator
		)
	}

	func toStringBlobs(
		preamble: String = "BLOBS\n",
		label: String = "BLOB\n",
		formatting: BlobOutputFormat,
		separator: String = "\n"
	) -> String {
		let body: String
		switch formatting {
		case .excludeBlobs: return ""
		case .includeBlobsByByteCountOnly:
			body = blobs().lazy.enumerated().map { index, blob in
				"\(label)[\(index)]: #\(blob.count) bytes"
			}.joined(separator: separator)
		case .includeBlobs:
			body = blobs().lazy.enumerated().map { index, blob in
				"\(label)[\(index)]:\n\(blob.hex)\n"
			}.joined(separator: separator)
		case .includeBlobsWithHash:
			body = blobs().enumerated().map { index, blob in
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
		instructionsArgumentSeparator: String = "\n\t"
	) throws -> String {
		let instructionsString = try toStringInstructions(
			separator: instructionsSeparator,
			argumentSeparator: instructionsArgumentSeparator
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
			return try toString()
		} catch {
			return "Can't create description of manifest: \(error)"
		}
	}
}
