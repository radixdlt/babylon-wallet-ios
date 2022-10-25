import Common
import Foundation

// MARK: - IncomingConnectionRequestFromDapp
public struct IncomingConnectionRequestFromDapp: Equatable, Decodable {
	let componentAddress: ComponentAddress
	let name: String?
	let permissions: [IncomingConnectionRequestFromDapp.Permission]
}

// MARK: - Computed Propertie
public extension IncomingConnectionRequestFromDapp {
	var displayName: String {
		name ?? L10n.DApp.unknownName
	}
}

#if DEBUG
public extension IncomingConnectionRequestFromDapp {
	static let placeholder: Self = .init(
		componentAddress: "deadbeef",
		name: "Radaswap",
		permissions: [
			.placeholder1,
			.placeholder2,
//			.placeholder3,
		]
	)
}
#endif
