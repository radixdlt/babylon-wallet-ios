import Foundation
import Resources

// MARK: - DappMetadata
public struct DappMetadata: Sendable, Hashable {
	public let name: String
	public let description: String?

	public init(
		name: String?,
		description: String? = nil
	) {
		self.name = name?.nilIfBlank ?? L10n.DApp.Metadata.unknownName
		self.description = description
	}
}

#if DEBUG
public extension DappMetadata {
	static let previewValue: Self = .init(
		name: "Collabo.Fi",
		description: "A very collaby finance dapp"
	)
}
#endif
