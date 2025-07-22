import ComposableArchitecture
import Sargon

extension AddFactorSource {
	enum Context: Sendable, Hashable {
		case newFactorSource
		case recoverFactorSource(isOlympia: Bool)
	}

	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			enum Mode {
				case preselectedKind(FactorSourceKind)
				case toSelectFromKinds([FactorSourceKind])
			}

			@Shared(.deviceMnemonicBuilder) var deviceMnemonicBuilder
			var kind: FactorSourceKind?

			var root: Root.State
			var path: StackState<Path.State>

			let context: Context

			init(mode: Mode, context: Context) {
				switch mode {
				case let .preselectedKind(factorSourceKind):
					self.kind = factorSourceKind
					self.root = .intro(.init(kind: factorSourceKind))
				case let .toSelectFromKinds(kinds):
					self.kind = nil
					self.root = .selectKind(.init(kinds: kinds))
				}
				self.context = context
				self.path = .init()
			}
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro(AddFactorSource.Intro)
			case deviceSeedPhrase(AddFactorSource.DeviceSeedPhrase)
			case confirmSeedPhrase(AddFactorSource.ConfirmSeedPhrase)
			case nameFactorSource(AddFactorSource.NameFactorSource)
		}

		@Reducer
		struct Root {
			@CasePathable
			@ObservableState
			enum State: Hashable, Sendable {
				case selectKind(AddFactorSource.SelectKind.State)
				case intro(AddFactorSource.Intro.State)
			}

			@CasePathable
			enum Action: Equatable, Sendable {
				case selectKind(AddFactorSource.SelectKind.Action)
				case intro(AddFactorSource.Intro.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.selectKind, action: \.selectKind) {
					AddFactorSource.SelectKind()
				}

				Scope(state: \.intro, action: \.intro) {
					AddFactorSource.Intro()
				}
			}
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Root.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished(FactorSource)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Root()
			}

			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .root(.selectKind(.delegate(.completed(selectedKind)))):
				state.kind = selectedKind
				state.path.append(.intro(.init(kind: selectedKind)))
				return .none

			case .root(.intro(.delegate(.completed))), .path(.element(id: _, action: .intro(.delegate(.completed)))):
				state.path.append(.deviceSeedPhrase(.init(context: state.context)))
				return .none

			case let .root(.intro(.delegate(.completedWithLedgerDeviceInfo(ledger)))),
			     let .path(.element(id: _, action: .intro(.delegate(.completedWithLedgerDeviceInfo(ledger))))):
				let ledgerFS = LedgerHardwareWalletFactorSource.from(device: ledger, name: "")
				state.path.append(.nameFactorSource(.init(context: state.context, factorSource: ledgerFS.asGeneral)))

				return .none

			case let .root(.intro(.delegate(.completeWithArculusCardInfo(arculus)))),
			     let .path(.element(id: _, action: .intro(.delegate(.completeWithArculusCardInfo(arculus))))):
				state.path.append(.deviceSeedPhrase(.init(context: state.context)))
				return .none

			case let .path(.element(id: _, action: .deviceSeedPhrase(.delegate(.completed(withCustomSeedPhrase))))):
				if withCustomSeedPhrase {
					state.path.append(.nameFactorSource(.init(context: state.context, factorSource: createFS(state: state))))
				} else {
					state.path.append(.confirmSeedPhrase(.init(factorSourceKind: state.kind!)))
				}
				return .none

			case .path(.element(id: _, action: .confirmSeedPhrase(.delegate(.validated)))):
				state.path.append(.nameFactorSource(.init(context: state.context, factorSource: createFS(state: state))))
				return .none

			case let .path(.element(id: _, action: .nameFactorSource(.delegate(.saved(fs))))):
				// Reset
				state.$deviceMnemonicBuilder.withLock { builder in
					builder = DeviceMnemonicBuilder()
				}
				return .send(.delegate(.finished(fs)))

			default:
				return .none
			}
		}

		func createFS(state: State) -> FactorSource {
			let mwp = state.deviceMnemonicBuilder.getMnemonicWithPassphrase()

			switch state.kind {
			case .device:
				let factorType: DeviceFactorSourceType = switch state.context {
				case .newFactorSource:
					.babylon
				case let .recoverFactorSource(isOlympia):
					isOlympia ? .olympia : .babylon
				}
				return SargonOS.shared.createDeviceFactorSource(mnemonicWithPassphrase: mwp, factorType: factorType).asGeneral

			case .arculusCard:
				let mwp = state.deviceMnemonicBuilder.getMnemonicWithPassphrase()
				let fsId = newFactorSourceIdFromHashFromMnemonicWithPassphrase(factorSourceKind: .arculusCard, mnemonicWithPassphrase: mwp)
				return ArculusCardFactorSource(id: fsId, common: .babylon(), hint: .init(label: "", model: .arculusColdStorageWallet)).asGeneral

			default:
				fatalError("Called with invalid kind")
			}
		}
	}
}
