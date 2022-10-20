import ComposableArchitecture
import SwiftUI
import DesignSystem

public extension ChooseAccounts.Row {
    struct View: SwiftUI.View {
        private let store: StoreOf<ChooseAccounts.Row>
        @SwiftUI.State private var isSelected = false

        public init(store: StoreOf<ChooseAccounts.Row>) {
            self.store = store
        }
    }
}

public extension ChooseAccounts.Row.View {
    var body: some View {
        WithViewStore(
            store,
            observe: ViewState.init(state:),
            send: ChooseAccounts.Row.Action.init
        ) { viewStore in
            HStack {
                VStack(alignment: .leading, spacing: 14) {
                    Text("My main account")
                        .foregroundColor(.app.white)
                        .textStyle(.body1Header)
                    
                    Text("acct...q2qgtxg")
                        .foregroundColor(.app.white.opacity(0.8))
                        .textStyle(.body2HighImportance)
                }
                
                Spacer()
                
                CheckmarkView(isChecked: viewStore.isSelected)
            }
            .padding(24)
            .background(Color.app.green1.opacity(isSelected ? 0.8 : 1))
            .cornerRadius(12)
            .onTapGesture {
                viewStore.send(.accountTapped)
            }
        }
    }
}

extension ChooseAccounts.Row.View {
    enum ViewAction: Equatable {
        case accountTapped
    }
}

extension ChooseAccounts.Row.Action {
    init(action: ChooseAccounts.Row.View.ViewAction) {
        switch action {
        case .accountTapped:
            self = .internal(.user(.accountTapped))
        }
    }
}

extension ChooseAccounts.Row.View {
    struct ViewState: Equatable {
        let isSelected: Bool
        
        init(state: ChooseAccounts.Row.State) {
            isSelected = state.isSelected
        }
    }
}

struct Row_Preview: PreviewProvider {
    static var previews: some View {
        registerFonts()
        
        return ChooseAccounts.Row.View(
            store: .init(
                initialState: .placeholder,
                reducer: ChooseAccounts.Row()
            )
        )
    }
}
