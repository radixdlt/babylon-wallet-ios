import ComposableArchitecture
@testable import ImportProfileFeature
import Profile
import TestUtils

// MARK: - ImportProfileFeatureTests
@MainActor
final class ImportProfileFeatureTests: TestCase {
	let sut = TestStore(
		initialState: ImportProfile.State(),
		reducer: ImportProfile()
	)

	func test__GIVEN__action_goBack__WHEN__reducer_is_run__THEN__it_coordinates_to_goBack() async throws {
		_ = await sut.send(.internal(.view(.goBack)))
		_ = await sut.receive(.delegate(.goBack))
	}

	func test__GIVEN_fileImport_not_displayed__WHEN__user_wants_to_import_a_profile__THEN__fileImported_displayed() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: false),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.view(.importProfileFileButtonTapped))) {
			$0.isDisplayingFileImporter = true
		}
	}

	func test__GIVEN_fileImport_displayed__WHEN__dismissed__THEN__fileImported_is_not_displayed_anymore() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: true),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.view(.dismissFileImporter))) {
			$0.isDisplayingFileImporter = false
		}
	}

	func test__GIVEN__a_corrupted_profileSnapshot__WHEN__it_is_decoded__THEN__reducer_delegates_error() async throws {
		sut.dependencies.data = .init(contentsOfURL: { _, _ in
			Data("deadbeef".utf8) // invalid data
		})
		sut.dependencies.jsonDecoder = .iso8601

		_ = await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))
		_ = await sut.receive(.delegate(.failedToImportProfileSnapshot(reason: "Failed to import ProfileSnapshot data, error: dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: \"The given data was not valid JSON.\", underlyingError: Optional(Error Domain=NSCocoaErrorDomain Code=3840 \"Invalid value around line 1, column 0.\" UserInfo={NSDebugDescription=Invalid value around line 1, column 0., NSJSONSerializationErrorIndex=0})))")))
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__reducer_calls_save_on_keychainClient_and_delegates_snapshot() async throws {
		sut.dependencies.data = .init(contentsOfURL: { url, options in
			XCTAssertEqual(url, URL(string: "file://profiledataurl")!)
			XCTAssertEqual(options, .uncached)
			return self.profileSnapshotData
		})
		sut.dependencies.jsonDecoder = .iso8601
		let keychainDataGotCalled = ActorIsolated<Data?>(nil)
		let keychainSetDataExpectation = expectation(description: "setDataForKey should be called on Keychain client")
		sut.dependencies.keychainClient.setDataDataForKey = { data, key in
			if key == "profileSnapshotKeychainKey" {
				Task {
					await keychainDataGotCalled.setValue(data)
					keychainSetDataExpectation.fulfill()
				}
			}
		}
		_ = await sut.send(.view(.profileImported(.success(URL(string: "file://profiledataurl")!))))
		_ = await sut.receive(.delegate(.importedProfileSnapshot(profileSnapshot)))

		waitForExpectations(timeout: 1)
		try await keychainDataGotCalled.withValue {
			guard let jsonData = $0 else {
				XCTFail("Expected keychain to have set data for profile")
				return
			}
			let decoded = try JSONDecoder.iso8601.decode(ProfileSnapshot.self, from: jsonData)
			XCTAssertEqual(decoded, profileSnapshot)
		}
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
