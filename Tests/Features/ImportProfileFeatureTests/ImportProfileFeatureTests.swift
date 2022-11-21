import ComposableArchitecture
@testable import ImportProfileFeature
import Profile
import TestUtils

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
		sut.dependencies.data = .init(contentsOfURL: { _, _ in
			invalidProfileData
		})
		sut.dependencies.keychainClient.dataForKey = { _, _ in
			invalidProfileData
		}

		let expectation1 = expectation(description: "Remove corrupt Profile data from keychain")
		sut.dependencies.keychainClient.removeDataForKey = { _ in
			expectation1.fulfill()
		}

		let expectation2 = expectation(description: "Error")
		sut.dependencies.errorQueue.schedule = { error in
			XCTAssertEqual(String(describing: error), "dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: \"The given data was not valid JSON.\", underlyingError: Optional(Error Domain=NSCocoaErrorDomain Code=3840 \"Invalid value around line 1, column 0.\" UserInfo={NSDebugDescription=Invalid value around line 1, column 0., NSJSONSerializationErrorIndex=0})))")
			expectation2.fulfill()
		}

		await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))

		wait(for: [expectation1, expectation2], timeout: 0)

		await sut.finish()
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__reducer_calls_save_on_keychainClient_and_delegates_snapshot() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(),
			reducer: ImportProfile()
		)

		sut.dependencies.data = .init(contentsOfURL: { url, options in
			XCTAssertEqual(url, URL(string: "file://profiledataurl")!)
			XCTAssertEqual(options, .uncached)
			return self.profileSnapshotData
		})
		let profileSnapshotDataInKeychain = ActorIsolated<Data?>(nil)
		sut.dependencies.keychainClient.setDataDataForKey = { data, key in
			if key == "profileSnapshotKeychainKey" {
				Task {
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
	nonisolated var profileSnapshotData: Data {
		let url = Bundle.module.url(forResource: "profile_snapshot", withExtension: "json")!
		return try! Data(contentsOf: url)
	}

	nonisolated var profileSnapshot: ProfileSnapshot {
		let jsonDecoder = JSONDecoder.iso8601
		return try! jsonDecoder.decode(ProfileSnapshot.self, from: profileSnapshotData)
	}
}
