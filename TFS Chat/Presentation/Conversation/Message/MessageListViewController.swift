//
//  ConversationViewController.swift
//  TFS Chat
//
//  Created by dmitry on 29.09.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import UIKit
import CoreData

class MessageListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var messageTextField: UITextField!
    @IBOutlet var messageView: UIView!
    var channelId: String?
    let senderID = UIDevice.current.identifierForVendor?.uuidString
    
    var fetchedResultsController: NSFetchedResultsController<MessageDb>!
    var apiService: ApiServiceProtocol!
    var storageService: StorageServiceProtocol!
    let animationLayer = CAEmitterLayer()
    
    func injectDependencies(storageService: StorageServiceProtocol, apiService: ApiServiceProtocol) {
        self.storageService = storageService
        self.apiService = apiService
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        messageTextField.delegate = self
        setupMessageTextField()
        if let channelId = channelId {
            fetchedResultsController = storageService.getMessagesFRC(channelId: channelId)
            fetchedResultsController.delegate = self
            storageService.performFetch(for: fetchedResultsController)
            apiService.subscribeOnMessagesChanges(channelId: channelId) { messages in
                self.storageService.saveMessages(messageModels: messages, channelId: channelId)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustViewForCurrentTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToBottom()
    }
    
    @IBAction func longPressedAction(_ sender: UILongPressGestureRecognizer) {
        showTinkoffAnimation(sender: sender, layer: animationLayer)
    }
    
    @objc func sendButtonPressed() {
        guard let channelId = channelId else { return }
        guard let senderID = senderID else { return }
        guard let content = messageTextField.text, content != "" else { return }
        let message = MessageDataModel(content: content, created: Date(), senderId: senderID, senderName: "Dmitry Akatev")
        apiService.addMessage(channelId: channelId,
                              message: message,
                              completion: { [weak self] in
                                self?.dismissKeyboard()
                                self?.messageTextField.text = ""
                              })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: messageView.frame.size.height))
        return footerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = fetchedResultsController.object(at: indexPath).toMessageModel()
        
        if cellModel.senderId == senderID {
            return configureCell(indexPath: indexPath, identifier: "SentMessageCell", model: cellModel)
        } else {
            return configureCell(indexPath: indexPath, identifier: "RecievedMessageCell", model: cellModel)
        }
    }
    
    private func configureCell(indexPath: IndexPath, identifier: String, model: MessageDataModel) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MessageViewCell else { return UITableViewCell()}
        cell.setColor(for: identifier)
        cell.configure(with: model)
        return cell
    }
    
    private func scrollToBottom() {
        if let messagesCount = self.fetchedResultsController.sections?[0].numberOfObjects, messagesCount != 0 {
            let indexPath = IndexPath(row: messagesCount - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
    
    deinit {
        apiService.unsubscribeFromMessagesChanges()
    }
    
}

extension MessageListViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupMessageTextField() {
        let iconView = UIImageView(frame: CGRect(x: 0, y: 5, width: 32, height: 32))
        iconView.image = UIImage(named: "send")
        iconView.tintColor = UIColor.systemBlue
        let iconContainerView: UIView = UIView(frame: CGRect(x: 32, y: 0, width: 40, height: 40))
        iconContainerView.addSubview(iconView)
        messageTextField.rightView = iconContainerView
        messageTextField.rightViewMode = .always
        
        let sendButtonTap = UITapGestureRecognizer(target: self, action: #selector(sendButtonPressed))
        iconContainerView.addGestureRecognizer(sendButtonTap)
        let dissmissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dissmissKeyboardTap)
        
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        messageTextField.leftView = leftPaddingView
        messageTextField.leftViewMode = .always
        
        messageTextField.layer.borderColor = UIColor.lightGray.cgColor
        messageTextField.layer.borderWidth = 0.5
        messageTextField.layer.cornerRadius = 16
        messageTextField.attributedPlaceholder = NSAttributedString(string: "Your message here...",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemGray])
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
}

extension MessageListViewController: Themable {
    func adjustViewForCurrentTheme() {
        let theme = ThemeManager.instance.currentTheme
        tableView.backgroundColor = theme.messageListViewBackgroundColor
        messageView.backgroundColor = theme.navigationBarColor
        messageTextField.backgroundColor = theme.messageListViewBackgroundColor
        messageTextField.textColor = theme.recievedMessageTextColor
        tableView.tableFooterView?.backgroundColor = theme.messageListViewBackgroundColor
        tableView.reloadData()
    }
}

extension MessageListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            guard let path = newIndexPath else { return }
            tableView.insertRows(at: [path], with: .automatic)
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
