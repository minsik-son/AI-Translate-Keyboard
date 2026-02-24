import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let mainVC = MainViewController()
        let nav = UINavigationController(rootViewController: mainVC)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url, nav: nav)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        guard let nav = window?.rootViewController as? UINavigationController else { return }
        handleURL(url, nav: nav)
    }

    private func handleURL(_ url: URL, nav: UINavigationController) {
        guard url.scheme == "translatorkeyboard", url.host == "settings" else { return }
        nav.popToRootViewController(animated: false)
        nav.pushViewController(SettingsViewController(), animated: true)
    }
}
