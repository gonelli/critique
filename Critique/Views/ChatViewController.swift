//
//  ChatViewController.swift
//  Critique
//
//  Created by James Jackson on 7/23/19.
//  Copyright © 2019 Andrew Cramer Tony Gonelli James Jackson Ameya Joshi. All rights reserved.
//

import UIKit
import MessageKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import InputBarAccessoryView

class ChatViewController: MessagesViewController, MessagesDataSource {
  
  var db: Firestore!
  var chat: Chat? = nil
  var snapshotListener:ListenerRegistration! = nil
  
  var current: MockUser {
    return MockUser(senderId: "\(chat?.criticIDs.firstIndex(of: Auth.auth().currentUser!.uid) ?? 0)", displayName: "todo")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initializeFirestore()
    configureMessageCollectionView()
    configureMessageInputBar()
    chat?.getTitle() { title in
        self.title = title
    }
  }
    
    override func viewDidAppear(_ animated: Bool) {
        snapshotListener = db.collection("chats").document(chat!.chatID).addSnapshotListener() { document, error in
            if let raw =  document?.data()?["messages"] as? [[String: Any]] {
                var messages: [MockMessage] = []
                var i = 0
                for message in raw {
                    i += 1
                    let text = message["body"] as! String
                    let user = MockUser(senderId: "\(message["from"] as! Int)", displayName: "TODO")
                    let timestamp = (message["time"] as! Timestamp).dateValue()
                    messages.append(MockMessage(text: text, user: user, messageId: "\(i)", date: timestamp))
                }
                self.chat!.messages = messages
            }
            self.messagesCollectionView.reloadDataAndKeepOffset()
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    snapshotListener.remove()
  }
  
  func initializeFirestore() {
    let settings = FirestoreSettings()
    Firestore.firestore().settings = settings
    db = Firestore.firestore()
  }
  
  func configureMessageCollectionView() {
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messageCellDelegate = self
    scrollsToBottomOnKeyboardBeginsEditing = true // default false
    maintainPositionOnKeyboardFrameChanged = true // default false
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
  }
  
  func configureMessageInputBar() {
    messageInputBar.delegate = self
    messageInputBar.inputTextView.placeholder = "Text Message"
    messageInputBar.inputTextView.tintColor = .primaryColor
    messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
    messageInputBar.sendButton.setTitleColor(UIColor.primaryColor.withAlphaComponent(0.3), for: .highlighted)
  }
  
  func insertMessage(_ message: MockMessage) {
    // Reload last section to update header/footer labels and insert a new one
    messagesCollectionView.performBatchUpdates({
      messagesCollectionView.insertSections([chat!.messages.count - 1])
      if chat!.messages.count >= 2 {
        messagesCollectionView.reloadSections([chat!.messages.count - 2])
      }
    }, completion: { [weak self] _ in
      if self?.isLastSectionVisible() == true {
        self?.messagesCollectionView.scrollToBottom(animated: true)
      }
    })
  }
  
  func isLastSectionVisible() -> Bool {
    guard !chat!.messages.isEmpty else { return false }
    let lastIndexPath = IndexPath(item: 0, section: chat!.messages.count - 1)
    return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
  }
  
  func currentSender() -> SenderType {
    return current
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return chat!.messages[indexPath.section]
  }
  
  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return chat!.messages.count
  }
  
}

extension ChatViewController: MessageCellDelegate {
  
  func didTapAvatar(in cell: MessageCollectionViewCell) {
    print("Avatar tapped")
  }
  
  func didTapMessage(in cell: MessageCollectionViewCell) {
    print("Message tapped")
  }
  
  func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
    print("Top cell label tapped")
  }
  
  func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
    print("Bottom cell label tapped")
  }
  
  func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
    print("Top message label tapped")
  }
  
  func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
    print("Bottom label tapped")
  }
  
  func didTapAccessoryView(in cell: MessageCollectionViewCell) {
    print("Accessory view tapped")
  }
  
}

extension ChatViewController: MessageLabelDelegate {
  
  func didSelectAddress(_ addressComponents: [String: String]) {
    print("Address Selected: \(addressComponents)")
  }
  
  func didSelectDate(_ date: Date) {
    print("Date Selected: \(date)")
  }
  
  func didSelectPhoneNumber(_ phoneNumber: String) {
    print("Phone Number Selected: \(phoneNumber)")
  }
  
  func didSelectURL(_ url: URL) {
    print("URL Selected: \(url)")
  }
  
  func didSelectTransitInformation(_ transitInformation: [String: String]) {
    print("TransitInformation Selected: \(transitInformation)")
  }
  
  func didSelectHashtag(_ hashtag: String) {
    print("Hashtag selected: \(hashtag)")
  }
  
  func didSelectMention(_ mention: String) {
    print("Mention selected: \(mention)")
  }
  
  func didSelectCustom(_ pattern: String, match: String?) {
    print("Custom data detector patter selected: \(pattern)")
  }
  
}

extension ChatViewController: InputBarAccessoryViewDelegate {
  
  func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
    // Here we can parse for which substrings were autocompleted
    let attributedText = messageInputBar.inputTextView.attributedText!
    let range = NSRange(location: 0, length: attributedText.length)
    attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
      let substring = attributedText.attributedSubstring(from: range)
      let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
      print("Autocompleted: `", substring, "` with context: ", context ?? [])
    }
    let components = inputBar.inputTextView.components
    messageInputBar.inputTextView.text = String()
    messageInputBar.invalidatePlugins()
    // Send button activity animation
    messageInputBar.sendButton.startAnimating()
    messageInputBar.inputTextView.placeholder = "Sending..."
    if let messageText = components[0] as? String {
      let message = MockMessage(text: messageText, user: current, messageId: UUID().uuidString, date: Date())
      chat!.messages.append(message)
      insertMessage(message)
      
      /// !!!!!
      
      db.collection("chats").document(chat!.chatID).setData(["messages": encode(messages: chat!.messages)], merge: true) { (error) in
        if let error = error {
          fatalError(error.localizedDescription) // FIX
        }
        self.messageInputBar.sendButton.stopAnimating()
        self.messageInputBar.inputTextView.placeholder = "Text Message"
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
  
  func encode(messages: [MockMessage]) -> [[String: Any]] {
    var encoded: [[String: Any]] = []
    for message in messages {
      encoded.append(message.encode())
    }
    return encoded
  }
}

extension UIColor {
  static let primaryColor = UIColor(red:0.89, green:0.16, blue:0.08, alpha:1.0)
}

struct MockUser: SenderType, Equatable {
  var senderId: String
  var displayName: String
}

struct MockMessage: MessageType {
  
  var messageId: String
  var sender: SenderType {
    return user
  }
  var sentDate: Date
  var kind: MessageKind
  
  var user: MockUser
  
  var text: String = ""
  
  private init(kind: MessageKind, user: MockUser, messageId: String, date: Date) {
    self.kind = kind
    self.user = user
    self.messageId = messageId
    self.sentDate = date
  }
  
  init(text: String, user: MockUser, messageId: String, date: Date) {
    self.init(kind: .text(text), user: user, messageId: messageId, date: date)
    self.text = text
  }
  
}

extension ChatViewController: MessagesDisplayDelegate {
  
  // MARK: - Text Messages
  
  func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? .white : .darkText
  }
  
  func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
    switch detector {
    case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
    default: return MessageLabel.defaultAttributes
    }
  }
  
  func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
    return []
  }
  
  // MARK: - All Messages
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? .primaryColor : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(tail, .curved)
  }
  
  func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
      layout.setMessageIncomingAvatarSize(.zero)
      layout.setMessageOutgoingAvatarSize(.zero)
    }
  }
  
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {
  
  func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 18
  }
  
  func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 17
  }
  
  func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 20
  }
  
  func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 16
  }
  
}

extension MockMessage {
  
  func encode() -> [String : Any] {
    return ["body": self.text, "from": Int(self.user.senderId), "time": self.sentDate]
  }
  
}
