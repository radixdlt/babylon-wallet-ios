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
		_ = await sut.send(ImportProfile.Action.internal(.goBack))
		_ = await sut.receive(.coordinate(.goBack))
	}

	func test__GIVEN_fileImport_not_displayed__WHEN__user_wants_to_import_a_profile__THEN__fileImported_displayed() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: false),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.importProfileFile)) {
			$0.isDisplayingFileImporter = true
		}
	}

	func test__GIVEN_fileImport_displayed__WHEN__dismissed__THEN__fileImported_is_not_displayed_anymore() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: true),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.dismissFileimporter)) {
			$0.isDisplayingFileImporter = false
		}
	}

	func test__GIVEN__valid_profileSnapshot_json_data__WHEN__data_imported__THEN__data_gets_decoded() async throws {
		sut.dependencies.jsonDecoder = .iso8601
		_ = await sut.send(.internal(.importProfileDataResult(.success(profileSnapshotData))))
		_ = await sut.receive(.internal(.importProfileSnapshotFromDataResult(.success(profileSnapshot))))
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__it_gets_saved() async throws {
		_ = await sut.send(.internal(.importProfileSnapshotFromDataResult(.success(profileSnapshot))))
		_ = await sut.receive(.internal(.saveProfileSnapshot(profileSnapshot)))
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_saved__THEN__reducer_calls_save_on_keychainClient() async throws {
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
		_ = await sut.send(.internal(.saveProfileSnapshot(profileSnapshot)))
		_ = await sut.receive(.internal(.saveProfileSnapshotResult(.success(profileSnapshot))))

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

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_has_been_saved__THEN__reducer_coordinates_to_parent_reducer() async throws {
		_ = await sut.send(.internal(.saveProfileSnapshotResult(.success(profileSnapshot))))
		_ = await sut.receive(.coordinate(.importedProfileSnapshot(profileSnapshot)))
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
