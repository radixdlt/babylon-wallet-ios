import Dependencies
import UIKit
import SwiftUI
import AsyncExtensions

extension BannerClient: DependencyKey {
        public static let liveValue: Self = {
                let bannerChannel = AsyncPassthroughSubject<Banner>()
                var isPresented = Binding(get: {
                        true
                }) { value, tr in
                        let x = 10
                }


                Task {
                        for await banner in bannerChannel {
                                switch banner {
                                case let .toast(text):
                                        showToast(text, isPresented: isPresented)
                                case let .error(error):
                                        showErrorAlert(error) {
                                                window?.rootViewController = nil
                                        }
                                        break
                                }
                        }
                }

                @MainActor
                func showToast(_ text: String, isPresented: Binding<Bool>) {
                        showView(EmptyView().toast(isPresented: isPresented, content: {
                                Text(text)
                        }))
                }

                @MainActor
                func showErrorAlert(_ error: Error, onDismiss: () -> Void) {
                        guard let window else { return }
                        let isPresented = Binding {
                                true
                        } set: { value, tr in
                                let x = value
                                window.rootViewController = nil
                                window.isUserInteractionEnabled = false
                        }

                        showView(AnyView(EmptyView().alert(error.localizedDescription, isPresented: isPresented, actions: {
                                Text("Ok")
                        })), allowsInteraction: true)
                }


                @MainActor
                func showView(_ view: AnyView, allowsInteraction: Bool = true) {
                        guard let window else { return }
                        window.rootViewController = UIHostingController(
                                rootView: view
                        )
                        window.rootViewController?.view.backgroundColor = .clear
                        window.isUserInteractionEnabled = allowsInteraction
                }



                return .init(
                        setWindowScene: { windowScene in
                                scene = windowScene
                                window = UIWindow(windowScene: windowScene)
                                window?.windowLevel = .normal + 1
                                window?.isUserInteractionEnabled = false
                                window?.makeKeyAndVisible()
                        },
                        presentBanner: { text in
                                guard let bannerWindow = window else { return }
                                bannerWindow.rootViewController = UIHostingController(
                                        rootView: EmptyView().toast(isPresented: .constant(true), onTap: {
                                                bannerWindow.rootViewController = nil
                                        }, content: {
                                                Text("Hello")
                                        })
                                )
                                bannerWindow.rootViewController?.view.backgroundColor = .clear
                        },
                        presentErorrAllert: { text in

                        },
                        schedule: { banner in
                                bannerChannel.send(banner)
                        }
                )
        }()
}
