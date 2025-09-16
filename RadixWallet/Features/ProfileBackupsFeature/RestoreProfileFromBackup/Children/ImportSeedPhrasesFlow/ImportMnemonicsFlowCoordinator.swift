import ComposableArchitecture
import SwiftUI

// MARK: - ImportMnemonicsFlowCoordinator
@Reducer
struct ImportMnemonicsFlowCoordinator: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var factorSourcesToImport: IdentifiedArrayOf<DeviceFactorSource> = []
		var imported: Set<FactorSourceIDFromHash> = []

		var path: StackState<Path.State> = .init()
		let profileToCheck: ProfileToCheck

		init(profileToCheck: ProfileToCheck) {
			self.profileToCheck = profileToCheck
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case importMnemonic(ImportMnemonicForFactorSource)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonicForFactorSource.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonicForFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(
				state: \.importMnemonic,
				action: \.importMnemonic
			) {
				ImportMnemonicForFactorSource()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	enum InternalAction: Sendable, Equatable {
		case loadedToImport(IdentifiedArrayOf<DeviceFactorSource>)
	}

	enum DelegateAction: Sendable, Equatable {
		case finishedImportingMnemonics(
			imported: Set<FactorSourceIdFromHash>
		)

		case finishedEarly(dueToFailure: Bool)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.secureStorageClient) var secureStorageClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.path, action: \.child.path)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			.run { [profileToCheck = state.profileToCheck] send in
				let deviceFactorSources = try profileToCheck.profile()
					.factorSources
					.compactMap(\.asDevice)
					.filter {
						!secureStorageClient.containsMnemonicIdentifiedByFactorSourceID($0.id)
					}
					.asIdentified()

				await send(.internal(.loadedToImport(deviceFactorSources)))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.delegate(.finishedEarly(dueToFailure: true)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedToImport(toImport):
			guard !toImport.isEmpty else {
				return .send(.delegate(.finishedImportingMnemonics(imported: [])))
			}
			state.factorSourcesToImport = toImport
			state.path.append(
				.importMnemonic(.init(
					isAllowedToSkip: true,
					deviceFactorSource: state.factorSourcesToImport.removeFirst(),
					profileToCheck: state.profileToCheck
				))
			)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: _, action: .importMnemonic(.delegate(action)))):
			switch action {
			case .closed:
				return .send(.delegate(.finishedEarly(dueToFailure: false)))
			case let .imported(fs):
				state.imported.insert(fs.id)
			case .skipped:
				break
			}

			guard !state.factorSourcesToImport.isEmpty else {
				return .send(.delegate(.finishedImportingMnemonics(imported: state.imported)))
			}

			state.path.append(
				.importMnemonic(.init(
					isAllowedToSkip: true,
					deviceFactorSource: state.factorSourcesToImport.removeFirst(),
					profileToCheck: state.profileToCheck
				))
			)
			return .none

		default:
			return .none
		}
	}
}

extension ProfileToCheck {
	func profile() throws -> Profile {
		switch self {
		case let .specific(profile):
			profile
		case .current:
			try SargonOS.shared.profile()
		}
	}
}
