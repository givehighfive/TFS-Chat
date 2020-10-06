//
//  ConversationsListViewController.swift
//  TFS Chat
//
//  Created by dmitry on 29.09.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import UIKit

class ConversationsListViewController: UITableViewController {
    
    @IBOutlet var profileLogoView: ProfileLogoView!
    
    let data = FakeData.conversationListData;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeTheme(to: ThemesViewController.currentTheme)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        if section == 0 {
            title = "Online"
        } else if section == 1 {
            title = "History"
        }
        return title
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationListCell", for: indexPath) as? ConversationListCell else { return UITableViewCell() }
        
        let cellModel = data[indexPath.section][indexPath.row]
        cell.configure(with: cellModel)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let target = segue.destination as? ConversationViewController {
            guard let selectedPath = tableView.indexPathForSelectedRow else { return }
            target.title = data[selectedPath.section][selectedPath.row].name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        } else if let target = segue.destination as? ThemesViewController {
            target.title = "Settings"
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Chat", style: .plain, target: nil, action: nil)
            target.themesDelegate = self
        }
        segue.destination.navigationItem.largeTitleDisplayMode = .never
    }
    
    @IBAction func unwindToConversationList(segue: UIStoryboardSegue) {
    }
    
    private func setNavBarAppearance(backgroundColor: UIColor, textColor: UIColor) {
        navigationController?.navigationBar.barTintColor = backgroundColor
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: textColor]
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.backgroundColor = backgroundColor
            navBarAppearance.titleTextAttributes = [.foregroundColor: textColor]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        //TODO test for ios<13
    }
    
}

extension ConversationsListViewController: ThemesPickerDelegate {
    
    func changeTheme(to theme: Theme) {
        switch theme {
        case .classic:
            let grayNavBarColor = UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1)
            setNavBarAppearance(backgroundColor: grayNavBarColor, textColor: UIColor.black)
            tableView.backgroundColor = UIColor.white
        case .day:
            let color = UIColor.blue //TODO
        case .night:
            let blackNavBar = UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1)
            setNavBarAppearance(backgroundColor: blackNavBar, textColor: UIColor.white)
            tableView.backgroundColor = UIColor.black
        }
        
        self.tableView.reloadData()
    }
    
}
