import ComposableArchitecture
import Sargon

// MARK: - AddressBook
@Reducer
struct AddressBook: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		var entries: [AddressBookEntry] = []

		@Presents
		var destination: Destination.State? = nil

		init() {}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case task
		case addButtonTapped
		case editTapped(AddressBookEntry)
		case deleteTapped(AddressBookEntry)
	}

	enum InternalAction: Equatable {
		case loadedEntries([AddressBookEntry])
		case deletedEntry
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case addEntry(AddressBookEntryForm.State)
			case editEntry(AddressBookEntryForm.State)
			case deleteAlert(AlertState<DeleteAlert>)
		}

		@CasePathable
		enum Action: Equatable {
			case addEntry(AddressBookEntryForm.Action)
			case editEntry(AddressBookEntryForm.Action)
			case deleteAlert(DeleteAlert)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addEntry, action: \.addEntry) {
				AddressBookEntryForm()
			}
			Scope(state: \.editEntry, action: \.editEntry) {
				AddressBookEntryForm()
			}
		}

		enum DeleteAlert: Hashable {
			case confirmTapped(Address)
			case cancelTapped
		}
	}

	@Dependency(\.addressBookClient) var addressBookClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return loadEntries()

		case .addButtonTapped:
			state.destination = .addEntry(.init(mode: .add))
			return .none

		case let .editTapped(entry):
			state.destination = .editEntry(.init(mode: .edit(entry)))
			return .none

		case let .deleteTapped(entry):
			state.destination = .deleteAlert(.init(
				title: { TextState(L10n.AddressBook.deleteAlertTitle) },
				actions: {
					ButtonState(role: .cancel, action: .cancelTapped) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(role: .destructive, action: .confirmTapped(entry.address)) {
						TextState(L10n.AddressBook.delete)
					}
				},
				message: { TextState(L10n.AddressBook.deleteAlertMessage) }
			))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedEntries(entries):
			state.entries = entries.sortedForDisplay()
			return .none

		case .deletedEntry:
			state.destination = nil
			return loadEntries()
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .addEntry(.delegate(.saved)),
		     .editEntry(.delegate(.saved)):
			state.destination = nil
			return loadEntries()

		case let .deleteAlert(.confirmTapped(address)):
			return .run { send in
				_ = try await addressBookClient.deleteEntry(address)
				await send(.internal(.deletedEntry))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .deleteAlert(.cancelTapped):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}

	private func loadEntries() -> Effect<Action> {
		.run { send in
			let entries = try addressBookClient.entriesOnCurrentNetwork()
			await send(.internal(.loadedEntries(entries)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}
