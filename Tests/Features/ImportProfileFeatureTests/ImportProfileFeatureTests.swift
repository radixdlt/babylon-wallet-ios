import FeatureTestingPrelude
@testable import ImportProfileFeature
import Profile

// MARK: - ImportProfileFeatureTests
@MainActor
final class ImportProfileFeatureTests: TestCase {
	func test__GIVEN__action_goBack__WHEN__reducer_is_run__THEN__it_coordinates_to_goBack() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		)

		await sut.send(.internal(.view(.goBack)))
		await sut.receive(.delegate(.goBack))
	}

	func test__GIVEN_fileImport_not_displayed__WHEN__user_wants_to_import_a_profile__THEN__fileImported_displayed() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: false),
			reducer: ImportProfile()
		)

		await sut.send(.internal(.view(.importProfileFileButtonTapped))) {
			$0.isDisplayingFileImporter = true
		}
	}

	func test__GIVEN_fileImport_displayed__WHEN__dismissed__THEN__fileImported_is_not_displayed_anymore() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: true),
			reducer: ImportProfile()
		)

		await sut.send(.internal(.view(.dismissFileImporter))) {
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
		sut.dependencies.keychainClient.dataForKey = { _, _ in
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

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__reducer_calls_save_on_keychainClient_and_delegates_snapshot() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		)
		let profileSnapshotData = try profileSnapshotData()
		let profileSnapshot = try profileSnapshot()
		sut.dependencies.dataReader = .init { url, options in
			XCTAssertEqual(url, URL(string: "file://profiledataurl")!)
			XCTAssertEqual(options, .uncached)
			return profileSnapshotData
		}
		let profileSnapshotDataInKeychain = ActorIsolated<Data?>(nil)
		sut.dependencies.keychainClient.updateDataForKey = { @Sendable data, key, _, _ in
			Task {
				if key == "profileSnapshotKeychainKey" {
					await profileSnapshotDataInKeychain.setValue(data)
				}
			}
		}
		await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))
		await sut.receive(.delegate(.importedProfileSnapshot(profileSnapshot)))

		try await profileSnapshotDataInKeychain.withValue {
			guard let jsonData = $0 else {
				XCTFail("Expected keychain to have set data for profile")
				return
			}
			let decoded = try JSONDecoder.liveValue().decode(ProfileSnapshot.self, from: jsonData)
			XCTAssertEqual(decoded, profileSnapshot)
		}

		await sut.finish()
	}
}

private extension ImportProfileFeatureTests {
	func profileSnapshotData() throws -> Data {
		try readTestFixtureData(jsonName: "profile_snapshot")
	}

	func profileSnapshot() throws -> ProfileSnapshot {
		let jsonDecoder = JSONDecoder.iso8601
		let data = try profileSnapshotData()
		return try jsonDecoder.decode(ProfileSnapshot.self, from: data)
	}
}
