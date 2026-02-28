import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let tabBarController = TabBarController()
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        // 라이트/다크 모드 적용
        let isDark = UserDefaults(suiteName: AppConstants.appGroupIdentifier)?.bool(forKey: AppConstants.UserDefaultsKeys.appDarkMode) ?? false
        window?.overrideUserInterfaceStyle = isDark ? .dark : .light

        // 온보딩: 첫 실행 시 표시
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) ?? UserDefaults.standard
        if !defaults.bool(forKey: AppConstants.UserDefaultsKeys.hasCompletedOnboarding) {
            let onboardingVC = OnboardingViewController()
            onboardingVC.modalPresentationStyle = .fullScreen
            tabBarController.present(onboardingVC, animated: false)
        }

        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url, tabBar: tabBarController)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        guard let tabBar = window?.rootViewController as? TabBarController else { return }
        handleURL(url, tabBar: tabBar)
    }

    private func handleURL(_ url: URL, tabBar: TabBarController) {
        guard url.scheme == "translatorkeyboard", url.host == "settings" else { return }
        tabBar.selectedIndex = 4 // Settings tab
    }
}
