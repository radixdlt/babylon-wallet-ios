import Foundation

// MARK: - IncomingConnectionRequestFromDapp
public struct IncomingConnectionRequestFromDapp: Equatable, Decodable {
	let componentAddress: ComponentAddress
	let name: String?
	let permissions: [IncomingConnectionRequestFromDapp.Permission]
}

#if DEBUG
public extension IncomingConnectionRequestFromDapp {
	static let placeholder: Self = .init(
		componentAddress: "deadbeef",
		name: "Radaswap",
		permissions: [
			.placeholder1,
			.placeholder2,
			//            .placeholder3
		]
	)
}
#endif
