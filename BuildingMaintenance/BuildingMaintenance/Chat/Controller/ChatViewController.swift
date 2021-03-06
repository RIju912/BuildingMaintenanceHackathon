//
//  ChatViewController.swift
//  BuildingMaintenance
//
//  Created by Banerjee, Subhodip on 26/07/18.
//  Copyright © 2018 Subhodip. All rights reserved.
//

import ApiAI
import JSQMessagesViewController
import UIKit
import Speech

class ChatViewController: JSQMessagesViewController {
    
    let initialStatement = "Say something, I'm listening!"
    var problemStatement = ""
    private let senderIdentifier = "Buildings chat"
    private let displayName = "Building Team"
    private let userId = "userId"
    private let userName = "user_name"
    private var finalIndex: Int = 0
    private var dialogflowMessages: [[String: Any]] = []
    private var category: String = ""
    private var productName: String = ""
    private var timer: Timer?
    private var index = 0
    private var initialMessages: [Any] = ["Do you need a help from me?"]
    private var endIndex = 0
    
    var messages = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    private var micButton: UIButton!
    private var tapped = false {
        didSet {
            tapped ? micButton?.setTitle("Stop", for: .normal): micButton?.setTitle("Speech", for: .normal)
            tapped ? SpeechManager.shared.startRecording() : SpeechManager.shared.stopRecording()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = senderIdentifier
        self.senderDisplayName = displayName
        
        SpeechManager.shared.delegate = self
        addMicButton()
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
        
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            self?.populateWithWelcomeMessage()
        })
    }

    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }
    
    func addMicButton() {
        let height = self.inputToolbar.contentView.leftBarButtonContainerView.frame.size.height
        micButton = UIButton(type: .custom)
        micButton?.setTitle("Speech", for: .normal)
        micButton?.frame = CGRect(x: 0, y: 0, width: 70, height: height)
        micButton.setTitleColor(.red, for: .normal)
        
        inputToolbar.contentView.leftBarButtonItemWidth = 70
        inputToolbar.contentView.leftBarButtonContainerView.addSubview(micButton)
        inputToolbar.contentView.leftBarButtonItem.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(gesture:)))
        micButton?.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        tapped = !tapped
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.item]
        return message.senderId == senderId ? OutgoingAvatar(): IncomingAvatar()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell else { return UICollectionViewCell() }
        let message = messages[indexPath.item]
        cell.textView?.textColor = message.senderId == senderId ? UIColor.white: UIColor.black
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        addMessage(withId: userId, name: userName, text: text!)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        performQuery(senderId: userId, name: userName, text: text!)
        tapped = false
        inputToolbar.contentView.textView.text = ""
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        performQuery(senderId: userId, name: userName, text: "Multimedia")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        //think here
        //bguard let test = self.messages[indexPath.row].media, let photoItem = test as? JSQPhotoMediaItem,
//            let selectedImage = photoItem.image, !productName.isEmpty,!category.isEmpty, let departmanet = ProductDepartment(rawValue: category.lowercased()) else { return }
//        let wishList = WishList(prodName: productName, category: category, image: selectedImage)
//
//        StoreModel.shared.shoppingList[departmanet]!.append(wishList)
//        addImageMedia(image: #imageLiteral(resourceName: "addCart"))
//        addMessage(withId: senderId, name: displayName, text: "\(productName) added to your shopping list.")
    }
    
}

extension ChatViewController {
    
    func populateWithWelcomeMessage() {
        addMessage(withId: senderId, name: senderDisplayName, text: problemStatement)
        endIndex = initialMessages.count
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ChatViewController.showInitialiseMessage), userInfo: nil, repeats: true)
    }
    
    @objc func showInitialiseMessage() {
        if index == endIndex {
            SpeechManager.shared.speak(text: problemStatement)
            SpeechManager.shared.speak(text: "Do you need help from me?")
            timer?.invalidate()
            timer = nil
        } else {
            let message = initialMessages[index]
            if let message = message as? String {
                addMessage(withId: senderId, name: senderDisplayName, text: message)
            } else if let image = message as? UIImage {
                addImageMedia(image: image)
            }
            index += 1
        }
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
            finishSendingMessage()
        }
    }
    
    private func addImageMedia(image: UIImage) {
        if let media = JSQPhotoMediaItem(image: image), let message = JSQMessage(senderId: senderIdentifier, displayName: displayName, media: media) {
            messages.append(message)
            finishSendingMessage()
        }
    }
    
    private func addMedia(imageUrl: String, callBack: @escaping (() -> ()) ) {
        guard let url = URL(string: imageUrl) else { return }
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, err) in
            if let data = data {
                DispatchQueue.main.async { [weak self] in
                    if let image = UIImage(data: data) {
                        self?.addImageMedia(image: image)
                        callBack()
                    }
                }
            } else {
                callBack()
            }
        }
        dataTask.resume()
    }
    
    func performQuery(senderId:String,name:String,text:String) {
        guard !text.isEmpty else { return }
        let request = ApiAI.shared().textRequest()
        request?.query = text
        
        request?.setMappedCompletionBlockSuccess({ [weak self] (request, response) in
            
            guard let response = response as? AIResponse, let strongSelf = self, let action = response.result.action else { return }
            switch action { 
            case "input.ahu": print("here")
            default: strongSelf.defaultHandling(response: response)
                
            }
            
            }, failure: { (request, error) in
                print(error?.localizedDescription ?? "")
        })
        ApiAI.shared().enqueue(request)
    }
    
    private func defaultHandling(response: AIResponse) {
        guard let textResponse = response.result.fulfillment.speech else { return }
        SpeechManager.shared.speak(text: textResponse)
        addMessage(withId: senderId, name: senderDisplayName, text: textResponse)
    }
    
}

// MARK: Speech Manager delegate

extension ChatViewController:SpeechManagerDelegate {
    func didStartedListening(status:Bool) {
        if status {
            self.inputToolbar.contentView.textView.text = initialStatement
        }
    }
    
    func didReceiveText(text: String) {
        self.inputToolbar.contentView.textView.text = text
        if text != initialStatement {
            self.inputToolbar.contentView.rightBarButtonItem.isEnabled = true
        }
    }
}
