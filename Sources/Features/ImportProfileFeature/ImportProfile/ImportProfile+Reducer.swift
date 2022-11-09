import ComposableArchitecture
import Foundation
import KeychainClientDependency
import Profile

// MARK: - ImportProfile
public struct ImportProfile: ReducerProtocol {
	@Dependency(\.data) var data
	@Dependency(\.jsonDecoder) var jsonDecoder
	@Dependency(\.keychainClient) var keychainClient
	public init() {}
}

// MARK: ReducerProtocol Conformance
public extension ImportProfile {
	func reduce(into state: inout State, action: Action) -> Effect<Action, Never> {
		switch action {
		case .internal(.view(.goBack)):
			return .run { send in
				await send(.delegate(.goBack))
			}

		case .internal(.view(.dismissFileImporter)):
			state.isDisplayingFileImporter = false
			return .none

		case .internal(.view(.importProfileFileButtonTapped)):
			state.isDisplayingFileImporter = true
			return .none

		case let .internal(.view(.profileImported(.failure(error)))):
			return .run { send in
				await send(.delegate(.failedToImportProfileSnapshot(reason: "Failed to import file, error: \(String(describing: error))")))
			}

		case let .internal(.view(.profileImported(.success(profileURL)))):
			return .run { [data, jsonDecoder, keychainClient] send in
				let data = try data(contentsOf: profileURL, options: .uncached)
				let snapshot = try jsonDecoder.decode(ProfileSnapshot.self, from: data)
				try keychainClient.saveProfileSnapshot(profileSnapshot: snapshot)
				await send(.delegate(.importedProfileSnapshot(snapshot)))
			} catch: { error, send in
				await send(.delegate(.failedToImportProfileSnapshot(reason: "Failed to import ProfileSnapshot data, error: \(String(describing: error))")))
			}

		case .delegate:
			return .none
		}
	}
}

public struct ReadDataEffect {
	public typealias DataFromURL = @Sendable (URL, Data.ReadingOptions) throws -> Data

	private let dataFromURL: DataFromURL

	public init(dataFromURL: @escaping DataFromURL) {
	  self.dataFromURL = dataFromURL
	}

	func callAsFunction(contentsOf url: URL, options: Data.ReadingOptions) throws -> Data {
		try dataFromURL(url, options)
	}
}

extension ReadDataEffect: DependencyKey {
	public static let liveValue = Self(
		dataFromURL: { url, options in try Data(contentsOf: url, options: options) }
	)
}

import XCTestDynamicOverlay

extension ReadDataEffect: TestDependencyKey {
	public static let previewValue = Self(
		dataFromURL: { _, _ in Data() }
	)

	public static let testValue = Self(
		dataFromURL: unimplemented("\(Self.self).dataFromURL")
	)
}

extension DependencyValues {
	var data: ReadDataEffect {
		get { self[ReadDataEffect.self] }
		set { self[ReadDataEffect.self] = newValue }
	}
}
