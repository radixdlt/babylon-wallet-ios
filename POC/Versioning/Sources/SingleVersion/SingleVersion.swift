import Foundation

// MARK: - Trivial0
struct Trivial0: Codable {
	let label: String
	let version: Int
	init(label: String) {
		self.label = label
		self.version = 0
	}
}

// MARK: - Trivial1
struct Trivial1: Codable {
	let label: String
	let id: UUID
	let version: Int
	init(id: UUID = .init(), label: String) {
		self.label = label
		self.id = id
		self.version = 1
	}
}

typealias Trivial = Trivial1
