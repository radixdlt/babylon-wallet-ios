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

	public struct ViewState: Equatable {
		let url: URL
		let personaLabel: String
	}
}

// MARK: - Body

extension PersonaDetails.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView(showsIndicators: false) {
				VStack(spacing: 0) {
					PersonaThumbnail(viewStore.url, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoSection(store: store.actionless)

					Button(L10n.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					AccountSection(store: store)
						.background(.app.gray5)

					Button(L10n.PersonaDetails.deauthorizePersona) {
						viewStore.send(.deauthorizePersonaTapped)
					}
					.buttonStyle(.primaryRectangular(isDestructive: true))
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .large2)
				}
			}
			.navigationTitle(viewStore.personaLabel)
			.alert(store: store.confirmForgetAlert)
		}
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(url: .init(string: "placeholder")!, personaLabel: persona.displayName.rawValue)
	}
}

private extension PersonaDetails.Store {
	var confirmForgetAlert: AlertPresentationStore<PersonaDetails.ViewAction.ConfirmForgetAlert> {
		scope(state: \.$confirmForgetAlert) { .view(.confirmForgetAlert($0)) }
	}
}

// MARK: - PersonaDetails.View.InfoSection
extension PersonaDetails.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let personaLabel: String
			let isSharingAnything: Bool
			let givenName: String?
			let familyName: String?
			let emailAddress: String?
			let phoneNumber: String?
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					InfoPair(heading: L10n.PersonaDetails.personaLabelHeading, item: viewStore.personaLabel)

					Separator()

					if viewStore.isSharingAnything {
						Text(L10n.PersonaDetails.personaDataSharingDescription(viewStore.dAppName))
							.textBlock
					} else {
						Text(L10n.PersonaDetails.notSharingAnything(viewStore.dAppName))
							.textBlock
					}

					if let givenName = viewStore.givenName {
						InfoPair(heading: L10n.PersonaDetails.givenNameHeading, item: givenName)
					}

					if let familyName = viewStore.familyName {
						InfoPair(heading: L10n.PersonaDetails.familyNameHeading, item: familyName)
					}

					if let emailAddress = viewStore.emailAddress {
						InfoPair(heading: L10n.PersonaDetails.emailAddressHeading, item: emailAddress)
					}

					if let phoneNumber = viewStore.phoneNumber {
						InfoPair(heading: L10n.PersonaDetails.phoneNumberHeading, item: phoneNumber)
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}

private extension PersonaDetails.State {
	var infoSectionViewState: PersonaDetails.View.InfoSection.ViewState {
		.init(
			dAppName: dAppName,
			personaLabel: persona.displayName.rawValue,
			isSharingAnything: !persona.fields.isEmpty,
			givenName: persona.fields[kind: .givenName],
			familyName: persona.fields[kind: .familyName],
			emailAddress: persona.fields[kind: .emailAddress],
			phoneNumber: persona.fields[kind: .phoneNumber]
		)
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		struct ViewState: Equatable {
			let dAppName: String
			let sharingAccounts: OrderedSet<Profile.Network.AccountForDisplay>
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
						ForEach(viewStore.sharingAccounts) { account in
							AccountButton(
								account.label.rawValue,
								address: account.address.address,
								gradient: .init(account.appearanceID)
							) {
								viewStore.send(.accountTapped(account.address))
							}
						}
					}
					.padding(.horizontal, .medium3)

					Button(L10n.PersonaDetails.editAccountSharing) {
						viewStore.send(.editAccountSharingTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)
				}
			}
		}
	}
}

private extension PersonaDetails.State {
	var accountSectionViewState: PersonaDetails.View.AccountSection.ViewState {
		.init(dAppName: dAppName, sharingAccounts: persona.simpleAccounts ?? [])
	}
}

// MARK: Extensions

extension IdentifiedArrayOf<Profile.Network.Persona.Field> {
	subscript(kind kind: Profile.Network.Persona.Field.Kind) -> String? {
		first { $0.kind == kind }?.value.rawValue
	}
}
