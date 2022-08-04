import Foundation

public struct Profile: Equatable {
	public let name: String
	public init(name: String = "Unnamed") {
		self.name = name
	}
}
