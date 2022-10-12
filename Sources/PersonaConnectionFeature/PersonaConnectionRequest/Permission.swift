import Foundation

// MARK: - Permission
public struct Permission: Equatable {
	let description: String
	let details: [String]?
}

// MARK: Identifiable
extension Permission: Identifiable {
	public var id: String { description }
}

#if DEBUG
public extension Permission {
	static let placeholder1: Self = .init(
		description: "A dApp Login, including the following information:",
		details: [
			"Name and something else",
			"Email address",
		]
	)

	static let placeholder2: Self = .init(
		description: "Permission to view at least one account",
		details: nil
	)

	static let placeholder3: Self = .init(
		description: "Very long permission text very long permission text very long permission text very long permission text very long permission text",
		details: [
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
			"Very long details text very long details text very long details text very long details text very long details text very long details text",
		]
	)
}
#endif
