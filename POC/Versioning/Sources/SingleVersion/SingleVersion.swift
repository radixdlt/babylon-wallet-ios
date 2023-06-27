import Foundation

struct Profile0: Codable {
	struct Settings: Codable {
		let isDeveloper: Bool
	}

	let settings: Settings
	let id: UUID
	let version: Int

	init(
		id: UUID = .init(),
		settings: Settings
	) {
		self.id = id
		self.settings = settings
		self.version = 0
	}
}
