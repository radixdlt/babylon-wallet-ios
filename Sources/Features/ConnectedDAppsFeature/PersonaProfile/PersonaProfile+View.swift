import FeaturePrelude

// MARK: - View

extension PersonaProfile {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let dAppName: String
		let personaName: String
		let firstName: String
		let secondName: String
		let streetAddress: String
		let twitterName: String
	}
}

// MARK: - Body

public extension PersonaProfile.View {
	var body: some View {
		WithViewStore(store.actionless, observe: \.viewState) { viewStore in
			ScrollView {
				VStack(spacing: .medium1) {
					PersonaThumbnail(.placeholder, size: .veryLarge)

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.personaNameHeading)
						LeadingText(dataItem: viewStore.personaName)
					}

					Separator()

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.firstNameHeading)
						LeadingText(dataItem: viewStore.firstName)
					}

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.secondNameHeading)
						LeadingText(dataItem: viewStore.secondName)
					}

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.addressHeading)
						LeadingText(dataItem: viewStore.streetAddress)
					}

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.twitterNameHeading)
						LeadingText(dataItem: viewStore.twitterName)
					}

					ActionZone(store: store)
				}
				.padding(.horizontal, .medium1)
			}
			.navBarTitle(viewStore.personaName)
		}
	}
}

// MARK: - Extensions

private extension PersonaProfile.State {
	var viewState: PersonaProfile.ViewState {
		.init(dAppName: dAppName,
		      personaName: personaName,
		      firstName: firstName,
		      secondName: secondName,
		      streetAddress: streetAddress,
		      twitterName: twitterName)
	}
}

// MARK: - PersonaProfile.View.ActionZone
extension PersonaProfile.View {
	@MainActor
	struct ActionZone: View {
		struct ViewState: Equatable {
			let dAppName: String
			let sharingAccounts: [NamedAccount]
		}

		let store: StoreOf<PersonaProfile>

		var body: some View {
			WithViewStore(store, observe: \.actionZoneViewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					LeadingText(L10n.PersonaProfile.accountSharingDescription(viewStore.dAppName))
						.padding(.vertical, .medium2)
					ForEach(viewStore.sharingAccounts, id: \.address.id) { account in
						RadixButton(account.name, account: account.address.address, gradient: account.gradient) {
							viewStore.send(.appeared)
						}
					}
				}
			}
		}
	}
}

private extension PersonaProfile.State {
	var actionZoneViewState: PersonaProfile.View.ActionZone.ViewState {
		.init(dAppName: self.viewState.dAppName,
		      sharingAccounts: [
		      	.init(name: "My main account", gradient: .init(colors: [.green, .yellow]), address: try! .init(address: "account_d_82734975")),
		      	.init(name: "My savings account", gradient: .init(colors: [.blue, .orange]), address: try! .init(address: "account_d_82734975")),
		      ])
	}
}

// MARK: - NamedAccount
// TODO: • Generally useful, find similar or move to Prelude

public struct NamedAccount: Equatable, Sendable {
	public let name: String
	public let gradient: Gradient
	public let address: AccountAddress

	public init(name: String, gradient: Gradient, address: AccountAddress) {
		self.name = name
		self.gradient = gradient
		self.address = address
	}
}
