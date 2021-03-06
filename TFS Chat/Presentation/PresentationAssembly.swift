//
//  PresentationAssembly.swift
//  TFS Chat
//
//  Created by dmitry on 12.11.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import UIKit

protocol PresentationAssemblyProtocol {
    
    func rootController() -> UINavigationController
    
    func messageListControler(channelId: String, title: String) -> MessageListViewController
    
    func profileController(delegate: AvatarUpdaterDelegate) -> UINavigationController
    
    func themesController() -> ThemesViewController
    
    func imageCollectionController(setAvatarBlock: @escaping (UIImage) -> Void) -> ImageCollectionViewController
}

class PresentationAssembly: PresentationAssemblyProtocol {
    
    private let serviceAssembly: ServiceAssemblyProtocol
    
    init(serviceAssembly: ServiceAssemblyProtocol) {
        self.serviceAssembly = serviceAssembly
    }
    
    func rootController() -> UINavigationController {
        guard let navController = loadVCFromStoryboard(name: "ChannelListViewController", identifier: "ChannelListViewController") as? UINavigationController,
              let channelListViewController = navController.children.first as? ChannelListViewController else {
            fatalError("Unable to load ChannelListViewController")
        }
        
        channelListViewController.injectDependencies(
            presentationAssembly: self,
            storageService: serviceAssembly.storageService,
            apiService: serviceAssembly.apiService,
            gcdDataManager: serviceAssembly.fileStorageGCDService)
        
        return navController
    }
    
    func messageListControler(channelId: String, title: String) -> MessageListViewController {
        guard let controller = loadVCFromStoryboard(name: "MessageListViewController", identifier: "MessageListViewController") as? MessageListViewController else {
            fatalError("Unable to load MessageListViewController") }
        controller.injectDependencies(storageService: serviceAssembly.storageService, apiService: serviceAssembly.apiService)
        controller.title = title
        controller.channelId = channelId
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }
    
    func profileController(delegate: AvatarUpdaterDelegate) -> UINavigationController {
        guard let navController = loadVCFromStoryboard(name: "ProfileViewController", identifier: "ProfileViewController") as? UINavigationController,
              let profileController = navController.children.first as? ProfileViewController else {
            fatalError("Unable to load ProfileViewController")
        }
        
        profileController.injectDependencies(
            presentationAssembly: self,
            gcdDataManager: serviceAssembly.fileStorageGCDService,
            operationDataManager: serviceAssembly.fileStorageOperationService)
        profileController.avatarUpdaterDelegate = delegate
        profileController.navigationItem.largeTitleDisplayMode = .never
        return navController
    }
    
    func themesController() -> ThemesViewController {
        guard let controller = loadVCFromStoryboard(name: "ThemesViewController", identifier: "ThemesViewController") as? ThemesViewController else {
            fatalError("Unable to load ThemesViewController") }
        controller.applyThemeBlock = { theme in
            ThemeManager.instance.applyTheme(theme)
        }
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }
    
    func imageCollectionController(setAvatarBlock: @escaping (UIImage) -> Void) -> ImageCollectionViewController {
        guard let controller = loadVCFromStoryboard(name: "ImageCollectionViewController", identifier: "ImageCollectionViewController") as? ImageCollectionViewController else {
            fatalError("Unable to load ImageCollectionViewController") }
        controller.injectDependencies(networkService: serviceAssembly.networkService)
        controller.setAvatarBlock = setAvatarBlock
        
        return controller
    }
    
    private func loadVCFromStoryboard(name: String, identifier: String) -> UIViewController {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: identifier)
    }
    
}
