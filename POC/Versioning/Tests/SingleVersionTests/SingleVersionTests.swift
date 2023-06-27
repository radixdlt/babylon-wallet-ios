@testable import SingleVersion
import XCTest

// MARK: - Migrating
protocol Migrating {
	associatedtype From: Codable
	associatedtype To: Migratable
	static func migrate(from: From) throws -> To
}

// MARK: - Migratable
protocol Migratable: Codable where Migrator.To == Self {
	associatedtype Migrator: Migrating
	var version: Int { get }
}

// MARK: - Trivial + Migratable
extension Trivial: Migratable {
	struct Migrator: Migrating {
		typealias From = Trivial0
		typealias To = Trivial1
		static func migrate(from: From) throws -> To {
			To(label: from.label)
		}
	}
}

extension Migratable {
	static func parseAndMigrateIfNeeded(json: String) throws -> Migrator.To {
		try parseAndMigrateIfNeeded(json: Data(json.utf8))
	}

	static func parseAndMigrateIfNeeded(json: Data) throws -> Migrator.To {
		let jsonDecoder = JSONDecoder()
		do {
			return try jsonDecoder.decode(Migrator.To.self, from: json)
		} catch {
			let from = try jsonDecoder.decode(Migrator.From.self, from: json)
			return try Migrator.migrate(from: from)
		}
	}
}

// MARK: - SingleVersionTests
// "88888888-4444-4444-4444-CCCCCCCCCCCC"
final class SingleVersionTests: XCTestCase {
	func test_decoding() throws {
		let json0 = """
		{
			"version": 0,
			"label": "test"
		}
		"""
		let migrated = try Trivial.parseAndMigrateIfNeeded(json: json0)
		XCTAssertEqual(migrated.version, 1)
		XCTAssertEqual(migrated.label, "test")
	}
}
