@testable import Profile
import TestingPrelude

final class SnapshotHeaderTests: TestCase {
	func test_version_compatibility_check_too_low() throws {
		let tooLow = ProfileSnapshot.Header.Version.minimum - 1

		let oldHeader = ProfileSnapshot.Header(
			creatingDevice: device,
			lastUsedOnDevice: device,
			id: stableUUID,
			lastModified: stableDate,
			contentHint: .init(),
			snapshotVersion: tooLow
		)
		XCTAssertThrowsError(
			try oldHeader.validateCompatibility()
		) { anyError in
			guard let error = anyError as? ProfileSnapshot.Header.IncompatibleProfileVersion else {
				return XCTFail("WrongErrorType")
			}
			XCTAssertEqual(error, .init(decodedVersion: tooLow, minimumRequiredVersion: .minimum))
		}
	}

	func test_version_compatibility_check_ok() throws {
		let snapshotHeader = ProfileSnapshot.Header(
			creatingDevice: device,
			lastUsedOnDevice: device,
			id: stableUUID,
			lastModified: stableDate,
			contentHint: .init(
				numberOfAccountsOnAllNetworksInTotal: 6,
				numberOfPersonasOnAllNetworksInTotal: 3,
				numberOfNetworks: 2
			),
			snapshotVersion: .minimum
		)
		XCTAssertNoThrow(
			try snapshotHeader.validateCompatibility()
		)
	}
}
