import FeaturePrelude
import UniformTypeIdentifiers

// MARK: - NoJSONDataFound
struct NoJSONDataFound: Error {}

// MARK: - ExportableProfileFile
/// An exportable (and thus importable) Profile file, either encrypted or plaintext.
public enum ExportableProfileFile: FileDocument, Sendable, Hashable {
	case plaintext(ProfileSnapshot)
	case encrypted(EncryptedProfileSnapshot)
}

extension String {
	static let profileFileEncryptedPart = "encrypted"
	private static let filenameProfileBase = "radix_wallet_backup_file"
	static let filenameProfileNotEncrypted: Self = "\(filenameProfileBase).plaintext.json"
	static let filenameProfileEncrypted: Self = "\(filenameProfileBase).\(profileFileEncryptedPart).json"
}

extension ExportableProfileFile {
	public static let readableContentTypes: [UTType] = [.profile]

	public init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents
		else {
			throw NoJSONDataFound()
		}
		try self.init(data: data)
	}

	public init(data: Data) throws {
		@Dependency(\.jsonDecoder) var jsonDecoder
		do {
			self = try .plaintext(jsonDecoder().decode(ProfileSnapshot.self, from: data))
		} catch {
			self = try .encrypted(jsonDecoder().decode(EncryptedProfileSnapshot.self, from: data))
		}
	}

	public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let encoder = jsonEncoder()
		// FIXME: Should we set skip escaping slashes for `jsonEncoder()` everywhere? Feels to risky to do that this close to release, so lets investigate later (thinking about Gateway...)
		encoder.outputFormatting = [.withoutEscapingSlashes]
		switch self {
		case let .plaintext(plaintext):
			let jsonData = try encoder.encode(plaintext)
			return FileWrapper(regularFileWithContents: jsonData)
		case let .encrypted(encryptedSnapshot):
			let jsonData = try encoder.encode(encryptedSnapshot)
			return FileWrapper(regularFileWithContents: jsonData)
		}
	}
}

import OverlayWindowClient
extension OverlayWindowClient.Item.HUD {
	public static let decryptedProfile = Self(
		text: "Successfully decrypted wallet file.",
		icon: .init(kind: .system("lock.open"))
	)

	public static func exportedProfile(encrypted: Bool) -> Self {
		.init(
			text: "Exported \(encrypted ? "encrypted " : "")wallet backup file",
			icon: .init(kind: encrypted ? .system("lock.rectangle.stack") : .system("rectangle.stack"))
		)
	}
}
