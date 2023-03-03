import FeatureTestingPrelude
@testable import OnboardingFeature
import Profile

// MARK: - ImportProfileTests
@MainActor
final class ImportProfileTests: TestCase {
	func test__GIVEN__action_goBack__WHEN__reducer_is_run__THEN__it_coordinates_to_goBack() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		)

		await sut.send(.view(.goBack))
		await sut.receive(.delegate(.goBack))
	}

	func test__GIVEN_fileImport_not_displayed__WHEN__user_wants_to_import_a_profile__THEN__fileImported_displayed() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: false),
			reducer: ImportProfile()
		)

		await sut.send(.view(.importProfileFileButtonTapped)) {
			$0.isDisplayingFileImporter = true
		}
	}

	func test__GIVEN_fileImport_displayed__WHEN__dismissed__THEN__fileImported_is_not_displayed_anymore() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: true),
			reducer: ImportProfile()
		)

		await sut.send(.view(.dismissFileImporter)) {
			$0.isDisplayingFileImporter = false
		}
	}

	func test__GIVEN__a_corrupted_profileSnapshot__WHEN__it_is_decoded__THEN__reducer_delegates_error_and_on_debug_builds_removes_corrupt_data() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		)
		let invalidProfileData = Data("deadbeef".utf8) // invalid data
		sut.dependencies.dataReader = .init { _, _ in
			invalidProfileData
		}

		let expectation = expectation(description: "Error")
		sut.dependencies.errorQueue.schedule = { error in
			XCTAssertEqual(String(describing: error), "dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: \"The given data was not valid JSON.\", underlyingError: Optional(Error Domain=NSCocoaErrorDomain Code=3840 \"Invalid value around line 1, column 0.\" UserInfo={NSDebugDescription=Invalid value around line 1, column 0., NSJSONSerializationErrorIndex=0})))")
			expectation.fulfill()
		}

		await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))
		await sut.finish()

		wait(for: [expectation], timeout: 0)
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__it_gets_imported() async throws {
		let profileSnapshotData = try profileSnapshotData()
		let profileSnapshot = try profileSnapshot()
		let injectedProfileSnapshot = ActorIsolated<ProfileSnapshot?>(nil)

		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		) {
			$0.dataReader = .init { url, options in
				XCTAssertEqual(url, URL(string: "file://profiledataurl")!)
				XCTAssertEqual(options, .uncached)
				return profileSnapshotData
			}
			$0.onboardingClient.importProfileSnapshot = {
				await injectedProfileSnapshot.setValue($0)
			}
		}

		await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))
		await sut.receive(.delegate(.imported))

		await injectedProfileSnapshot.withValue {
			XCTAssertEqual($0, profileSnapshot)
		}

		await sut.finish()
	}
}

extension ImportProfileTests {
	private func profileSnapshotData() throws -> Data {
		try readTestFixtureData(jsonName: "profile_snapshot")
	}

	private func profileSnapshot() throws -> ProfileSnapshot {
		let jsonDecoder = JSONDecoder.iso8601
		let data = try profileSnapshotData()
		return try jsonDecoder.decode(ProfileSnapshot.self, from: data)
	}
}
