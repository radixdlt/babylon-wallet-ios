import ComposableArchitecture
import Sargon
import SwiftUI
import UniformTypeIdentifiers

// MARK: - NoJSONDataFound
struct NoJSONDataFound: Error {}

// MARK: - FileContentIsNotProfile
struct FileContentIsNotProfile: LocalizedError {
	var errorDescription: String? {
		L10n.Error.ProfileLoad.decodingError("Invalid backup file.")
	}
}

// MARK: - ExportableProfileFile
/// An exportable (and thus importable) Profile file, either encrypted or plaintext.
public enum ExportableProfileFile: FileDocument, Sendable, Hashable {
	case plaintext(Profile)
	case encrypted(EncryptedProfileJSONData)
}

extension String {
	static let profileFileEncryptedPart = "encrypted"
	private static let filenameProfileBase = "radix_wallet_backup_file"
	static let filenameProfileNotEncrypted: Self = "\(filenameProfileBase).plaintext.json"
	static let filenameProfileEncrypted: Self = "\(filenameProfileBase).\(profileFileEncryptedPart).json"
}

extension UTType {
	// FIXME: should we declare our own file format? For now we use require `.json` file extension.
	public static let profile: Self = .json
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
		switch Profile.analyzeContents(data: data) {
		case .encryptedProfile:
			self = .encrypted(data)
		case .notProfile:
			throw FileContentIsNotProfile()
		case let .plaintextProfile(plaintextProfile):
			self = .plaintext(plaintextProfile)
		}
	}

	public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		@Dependency(\.jsonEncoder) var jsonEncoder
		let encoder = jsonEncoder()
		// FIXME: Should we set skip escaping slashes for `jsonEncoder()` everywhere? Feels to risky to do that this close to release, so lets investigate later (thinking about Gateway...)
		encoder.outputFormatting = [.withoutEscapingSlashes]
		switch self {
		case let .plaintext(plaintext):
			let jsonData = plaintext.profileSnapshot()
			return FileWrapper(regularFileWithContents: jsonData)
		case let .encrypted(encryptedSnapshot):
			return FileWrapper(regularFileWithContents: encryptedSnapshot)
		}
	}
}

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
