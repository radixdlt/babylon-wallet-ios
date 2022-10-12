import Foundation

// MARK: - dApp
public struct dApp: Equatable {
	let name: String
	let permissions: [Permission]
}

#if DEBUG
public extension dApp {
	static let placeholder: Self = .init(
		name: "Radaswap",
		permissions: [
			.placeholder1,
			.placeholder2,
			//            .placeholder3
		]
	)
}
#endif
