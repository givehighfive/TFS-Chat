//
//  ImagesCollectionViewController.swift
//  TFS Chat
//
//  Created by dmitry on 17.11.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import UIKit

class ImageCollectionViewController: UIViewController {
    
    private let sectionInsets = UIEdgeInsets(top: 50.0,
                                             left: 20.0,
                                             bottom: 50.0,
                                             right: 20.0)
    private let itemsPerRow: CGFloat = 3
    private var data: DataModel?
    var setAvatarBlock: ((UIImage) -> Void)?
    let animationLayer = CAEmitterLayer()
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var networkService: NetworkServiceProtocol!
    
    func injectDependencies(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        networkService.loadImagesData { [weak self] result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self?.data = data
                    self?.collectionView.reloadData()
                    self?.activityIndicator.stopAnimating()
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.showErrorAlert()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustViewForCurrentTheme()
    }
    
    @IBAction func longPressedAction(_ sender: UILongPressGestureRecognizer) {
        showTinkoffAnimation(sender: sender, layer: animationLayer)
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Error occured during loading.\n Please try again", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            self.dismiss(animated: true)
        })
        self.present(alert, animated: true)
    }
}

extension ImageCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return data?.hits.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionCell else { return UICollectionViewCell() }
        guard let previewURL = data?.hits[indexPath.row].previewURL else { return UICollectionViewCell() }
        let placeholder = UIImage(named: "profile")
        cell.setImage(placeholder)
        
        networkService.loadImage(url: previewURL) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    cell.setImage(image)
                }
            case .failure: break
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let webformatURL = data?.hits[indexPath.row].webformatURL else { return }
        
        networkService.loadImage(url: webformatURL) { [weak self] result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self?.setAvatarBlock?(image)
                    self?.dismiss(animated: true)
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.showErrorAlert()
                }
            }
        }
    }
}

extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
}

extension ImageCollectionViewController: Themable {
    
    func adjustViewForCurrentTheme() {
        let theme = ThemeManager.instance.currentTheme
        collectionView.backgroundColor = theme.navigationBarColor
    }
}
