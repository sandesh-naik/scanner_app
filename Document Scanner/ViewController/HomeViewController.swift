//
//  HomeViewController.swift
//  Document Scanner
//
//  Created by Sandesh on 04/03/21.
//

import UIKit
import Hero

protocol HomeVC: DocumentScannerViewController {
    var delegate: HomeViewControllerDelegate? { get set }
    var allDocuments: [Document] { get }
    var filteredDocuments: [Document] { get }
}

protocol HomeViewControllerDelegate: class {
    func scanNewDocument(_ controller: HomeVC)
    func pickNewDocument(_ controller: HomeVC)
    func showSettings(_ controller: HomeVC)
    func viewDocument(_ controller: HomeVC, document: Document)
}

@available(iOS 13.0, *)
class HomeViewController: DocumentScannerViewController, HomeVC {
    
    weak var delegate: HomeViewControllerDelegate?
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Document>
    typealias SnapShot = NSDiffableDataSourceSnapshot<Int, Document>
    
    private lazy var dateSource = _getDocumentCollectionViewDataSource()
    
    var allDocuments: [Document] = [Document]()
    var filteredDocuments: [Document]  = [Document]()
    
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var documentsCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _setupViews()
        _setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        _getDocuments()
    }

    func _getDocuments() {
        let documents: [Document] = UserDefaults.standard.fetch(forKey: Constant.DocumentScannerDefaults.documentsListKey) ?? []
        self.allDocuments = documents
        self.filteredDocuments = documents
        applySnapshot(animatingDifferences: true)
    }
    
    private func _setupViews() {
        //headerLabel.font = UIFont.font(style: .largeTitle)
        configureUI(title: "My Documents")
        footerView.hero.id = Constant.HeroIdentifiers.footerIdentifier
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.tintColor = .text
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.placeholder = "Search Document"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func _setupCollectionView() {
        documentsCollectionView.isHeroEnabled = true
        documentsCollectionView.hero.modifiers = [.cascade]
        documentsCollectionView.register(UINib(nibName: DocumentCollectionViewCell.identifier, bundle: nil),
                                         forCellWithReuseIdentifier: DocumentCollectionViewCell.identifier)
        documentsCollectionView.collectionViewLayout = _collectionViewLayout()
        documentsCollectionView.delegate = self
        applySnapshot()
    }
    
    private func _collectionViewLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func _getDocumentCollectionViewDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: documentsCollectionView) { (collectionView, indexPath, document) -> UICollectionViewCell? in
            guard let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentCollectionViewCell.identifier, for: indexPath) as? DocumentCollectionViewCell else {
                fatalError("ERROR: Unable to find and dequeue cell with identifier \(DocumentCollectionViewCell.identifier)")
            }
            collectionViewCell.document = document
            return collectionViewCell
        }
        return dataSource
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapShot = SnapShot()
        snapShot.appendSections([0])
        snapShot.appendItems(filteredDocuments)
        dateSource.apply(snapShot, animatingDifferences: animatingDifferences)
    }
    
    
    @IBAction func didTapPickImageButton(_ sender: FooterButton) {
        delegate?.pickNewDocument(self)
    }
    
    @IBAction func didTapScanButton(_ sender: FooterButton) {
        delegate?.scanNewDocument(self)
    }
    
    @IBAction func didTapSettingsButton(_ sender: FooterButton) {
        delegate?.showSettings(self)
    }

}

@available(iOS 13.0, *)
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let document = filteredDocuments[indexPath.row]
        delegate?.viewDocument(self, document: document)
    }

}

@available(iOS 13.0, *)
extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        
        if searchText == nil || searchText!.isEmpty {
            filteredDocuments = allDocuments
            applySnapshot()
        } else {
            filteredDocuments = allDocuments.filter { $0.name.lowercased().contains(searchText!.lowercased()) }
            applySnapshot()
        }
    }
    
}
