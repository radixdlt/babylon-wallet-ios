import Foundation

// MARK: - SendableAnyHashable
public struct SendableAnyHashable: @unchecked Sendable, Hashable {
	let wrapped: AnyHashable

	init(wrapped: some Hashable & Sendable) {
		self.wrapped = .init(wrapped)
	}
}

// MARK: - EnvironmentValues

extension EnvironmentValues {
	/// The fallback string when the amount value is missing
	var missingFungibleAmountFallback: String? {
		get { self[MissingFungibleAmountKey.self] }
		set { self[MissingFungibleAmountKey.self] = newValue }
	}
}

// MARK: - MissingFungibleAmountKey
private struct MissingFungibleAmountKey: EnvironmentKey {
	static let defaultValue: String? = nil
}
