import ComposableArchitecture
import SwiftUI

// MARK: - DisplayMnemonic
public struct DisplayMnemonic: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let deviceFactorSource: DeviceFactorSource

		public var exportMnemonic: ExportMnemonic.State?

		public init(deviceFactorSource: DeviceFactorSource) {
			self.deviceFactorSource = deviceFactorSource
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum ChildAction: Sendable, Equatable {
		case exportMnemonic(ExportMnemonic.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToLoad
		case doneViewing(isBackedUp: Bool, factorSourceID: FactorSource.ID.FromHash)
	}

	@Dependency(\.secureStorageClient) var secureStorageClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.exportMnemonic, action: /Action.child .. ChildAction.exportMnemonic) {
				ExportMnemonic()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			exportMnemonic(
				factorSourceID: state.deviceFactorSource.id
			) {
				state.exportMnemonic = .export($0)
			} onErrorAction: { _ in
				.send(.delegate(.failedToLoad))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .exportMnemonic(.delegate(.doneViewing(markedMnemonicAsBackedUp))):
			let isBackedUp = markedMnemonicAsBackedUp ?? true
			state.exportMnemonic = nil
			return .send(
				.delegate(
					.doneViewing(
						isBackedUp: isBackedUp,
						factorSourceID: state.deviceFactorSource.id
					)
				)
			)
		default: return .none
		}
	}
}
