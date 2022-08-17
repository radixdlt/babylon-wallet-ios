import Foundation

public struct Profile: Equatable {
	public let accounts: [Account]
	public let name: String

	public init(
		name: String = "Unnamed",
		accounts: [Account] = []
	) {
		self.name = name
		self.accounts = accounts
	}
}
