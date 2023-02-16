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
					PersonaThumbnail(.placeholder, size: .veryLarge)
						.padding(.vertical, .large2)

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
		.init(personaName: persona.displayName.rawValue)
	}
}

// MARK: - PersonaProfile.View.InfoSection
extension PersonaProfile.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let personaName: String
			let firstName: String = "Matt"
			let secondName: String = "Smith"
			let streetAddress: String = "45 Hornhill Road, Texas 23918"
			let twitterName: String = "@radmatt"
		}

		let store: Store<PersonaProfile.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					InfoPair(heading: L10n.PersonaProfile.personaNameHeading,
					         item: viewStore.personaName)

					Separator()

					Text(L10n.PersonaProfile.personalDataSharingDescription(viewStore.dAppName))
						.textType(.textBlock)

					InfoPair(heading: L10n.PersonaProfile.firstNameHeading,
					         item: viewStore.firstName)

					InfoPair(heading: L10n.PersonaProfile.secondNameHeading,
					         item: viewStore.secondName)

					InfoPair(heading: L10n.PersonaProfile.addressHeading,
					         item: viewStore.streetAddress)

					InfoPair(heading: L10n.PersonaProfile.twitterNameHeading,
					         item: viewStore.twitterName)
				}
				.padding(.horizontal, .medium1)
			}
		}
	}

	private struct InfoPair: View {
		let heading: String
		let item: String

		var body: some View {
			VStack(alignment: .leading, spacing: .small2) {
				Text(heading)
					.textType(.sectionHeading)
				Text(item)
					.textType(.infoItem)
			}
		}
	}
}

private extension PersonaProfile.State {
	var infoSectionViewState: PersonaProfile.View.InfoSection.ViewState {
		.init(dAppName: dAppName,
		      personaName: persona.displayName.rawValue)
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
					Text(L10n.PersonaProfile.accountSharingDescription(viewStore.dAppName))
						.textType(.textBlock)
						.flushedLeft
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
