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

			var isSharingSomething: Bool {
				firstName != nil || lastName != nil || email != nil || zipCode != nil || personalIdentificationNumber != nil
			}
		}

		let store: Store<PersonaDetails.State, Never>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					InfoPair(heading: L10n.PersonaDetails.personaNameHeading,
					         item: viewStore.personaName)

					Separator()

					if viewStore.isSharingSomething {
						Text(L10n.PersonaDetails.personalDataSharingDescription(viewStore.dAppName))
							.textBlock
					} else {
						Text(L10n.PersonaDetails.notSharingAnything(viewStore.dAppName))
							.textBlock
					}

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
			let sharingAccounts: OrderedSet<OnNetwork.AccountForDisplay>
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
							AccountButton(account.label.rawValue,
							              address: account.address.address,
							              gradient: .init(account.appearanceID)) {
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
		.init(dAppName: dAppName, sharingAccounts: persona.simpleAccounts ?? [])
	}
}

// MARK: - InfoPair
public struct InfoPair: View {
	let heading: String
	let item: String

	public init(heading: String, item: String) {
		self.heading = heading
		self.item = item
	}

	public var body: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(heading)
				.sectionHeading
			Text(item)
				.infoItem
		}
	}
}
