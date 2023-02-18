import FeaturePrelude

// MARK: - View

extension PersonaDetails {
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

public extension PersonaDetails.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					PersonaThumbnail(.placeholder, size: .veryLarge)
						.padding(.vertical, .large2)
						.border(.green)

					InfoSection(store: store.actionless)

					Button(L10n.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.radix)
					.frame(width: .standardButtonWidth)
					.padding(.vertical, .large3)

					AccountSection(store: store)
						.background(.app.gray5)

					Button(L10n.PersonaDetails.disconnectPersona) {
						viewStore.send(.disconnectPersonaTapped)
					}
					.buttonStyle(.destructive)
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
				}
			}
			.navigationTitle(viewStore.personaName)
		}
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(personaName: persona.displayName.rawValue)
	}
}

// MARK: - PersonaDetails.View.InfoSection
extension PersonaDetails.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let personaName: String
			let firstName: String?
			let lastName: String?
			let email: String?
			let zipCode: String?
			let personalIdentificationNumber: String?
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					InfoPair(heading: L10n.PersonaDetails.personaNameHeading,
					         item: viewStore.personaName)

					Separator()

					Text(L10n.PersonaDetails.personalDataSharingDescription(viewStore.dAppName))
						.textBlock

					if let firstName = viewStore.firstName {
						InfoPair(heading: L10n.PersonaDetails.firstNameHeading, item: firstName)
					}

					if let lastName = viewStore.lastName {
						InfoPair(heading: L10n.PersonaDetails.secondNameHeading, item: lastName)
					}

					if let email = viewStore.email {
						InfoPair(heading: L10n.PersonaDetails.emailHeading, item: email)
					}

					if let zipCode = viewStore.zipCode {
						InfoPair(heading: L10n.PersonaDetails.zipCodeHeading, item: zipCode)
					}
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
					.sectionHeading
				Text(item)
					.infoItem
			}
		}
	}
}

private extension PersonaDetails.State {
	var infoSectionViewState: PersonaDetails.View.InfoSection.ViewState {
		.init(dAppName: dAppName,
		      personaName: persona.displayName.rawValue,
		      firstName: persona.fields[kind: .firstName]?.rawValue,
		      lastName: persona.fields[kind: .lastName]?.rawValue,
		      email: persona.fields[kind: .email]?.rawValue,
		      zipCode: persona.fields[kind: .zipCode]?.rawValue,
		      personalIdentificationNumber: persona.fields[kind: .personalIdentificationNumber]?.rawValue)
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let sharingAccounts: [NamedAccount]
		}

		let store: StoreOf<PersonaDetails>

		var body: some View {
			WithViewStore(store, observe: \.accountSectionViewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.PersonaDetails.accountSharingDescription(viewStore.dAppName))
						.textBlock
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

					Button(L10n.PersonaDetails.editAccountSharing) {
						viewStore.send(.editAccountSharingTapped)
					}
					.buttonStyle(.radix)
					.frame(width: .standardButtonWidth)
					.padding(.vertical, .large3)
				}
			}
		}
	}
}

private extension PersonaDetails.State {
	var accountSectionViewState: PersonaDetails.View.AccountSection.ViewState {
		.init(dAppName: dAppName,
		      sharingAccounts: [
		      	.init(name: "My account", gradient: .init(colors: [.app.account1pink, .app.account11blue1]), address: try! .init(address: "account_d_827m9765")),
		      	.init(name: "My second account", gradient: .init(colors: [.app.account5blue, .app.account6green]), address: try! .init(address: "account_d_8223445")),
		      	.init(name: "My savings account", gradient: .init(colors: [.app.account0green, .app.account9green1]), address: try! .init(address: "account_d_82734975")),
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
