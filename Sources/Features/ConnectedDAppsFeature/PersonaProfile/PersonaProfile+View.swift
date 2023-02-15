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
		let personaName: String
	}
}

// MARK: - Body

public extension PersonaProfile.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					InfoSection(store: store.actionless)

					Button(L10n.PersonaProfile.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.radix)
					.frame(width: 250)
					.padding(.vertical, .large3)

					AccountSection(store: store)
						.background(.app.gray5)

					Button(L10n.PersonaProfile.disconnectPersona) {
						viewStore.send(.disconnectPersonaTapped)
					}
					.buttonStyle(.destructive)
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
				}
			}
			.navBarTitle(viewStore.personaName)
		}
	}
}

// MARK: - Extensions

private extension PersonaProfile.State {
	var viewState: PersonaProfile.ViewState {
		.init(personaName: personaName)
	}
}

// MARK: - PersonaProfile.View.InfoSection
extension PersonaProfile.View {
	@MainActor
	struct InfoSection: View {
		let store: Store<PersonaProfile.State, Never>

		struct ViewState: Equatable {
			let dAppName: String
			let personaName: String
			let firstName: String
			let secondName: String
			let streetAddress: String
			let twitterName: String
		}

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(spacing: .medium1) {
					PersonaThumbnail(.placeholder, size: .veryLarge)

					VStack(spacing: .small2) {
						LeadingText(sectionHeading: L10n.PersonaProfile.personaNameHeading)
						LeadingText(dataItem: viewStore.personaName)
					}

					LeadingText(L10n.PersonaProfile.personalDataSharingDescription(viewStore.dAppName))

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
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}

private extension PersonaProfile.State {
	var infoSectionViewState: PersonaProfile.View.InfoSection.ViewState {
		.init(dAppName: dAppName,
		      personaName: personaName,
		      firstName: firstName,
		      secondName: secondName,
		      streetAddress: streetAddress,
		      twitterName: twitterName)
	}
}

// MARK: - PersonaProfile.View.AccountSection
extension PersonaProfile.View {
	@MainActor
	struct AccountSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let sharingAccounts: [NamedAccount]
		}

		let store: StoreOf<PersonaProfile>

		var body: some View {
			WithViewStore(store, observe: \.accountSectionViewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					LeadingText(L10n.PersonaProfile.accountSharingDescription(viewStore.dAppName))
						.padding(.vertical, .medium2)
						.padding(.horizontal, .medium1)

					VStack(spacing: .medium3) {
						ForEach(viewStore.sharingAccounts, id: \.name) { account in
							AccountButton(account.name, address: account.address.address, gradient: account.gradient) {
								viewStore.send(.appeared)
							}
						}
					}
					.padding(.horizontal, .medium3)

					Button(L10n.PersonaProfile.editAccountSharing) {
						viewStore.send(.editAccountSharingTapped)
					}
					.buttonStyle(.radix)
					.frame(width: 250)
					.padding(.vertical, .large3)
				}
			}
		}
	}
}

private extension PersonaProfile.State {
	var accountSectionViewState: PersonaProfile.View.AccountSection.ViewState {
		.init(dAppName: dAppName,
		      sharingAccounts: [
		      	.init(name: "My account", gradient: .init(colors: [.green, .yellow]), address: try! .init(address: "account_d_827m9765")),
		      	.init(name: "My second account", gradient: .init(colors: [.purple, .red]), address: try! .init(address: "account_d_8223445")),
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
