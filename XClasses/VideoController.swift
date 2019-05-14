//
//  VideoController.swift
//  Bookbot
//
//  Created by Adrian on 14/3/18.
//  Copyright © 2018 Bookbot. All rights reserved.
//

import UIKit
import AVKit

/// Video controller is a full screen video controller that plays automatically. On completion will call the closure, so you can clean it up.
class VideoController: UIViewController {
    var resource: URL?
    var backgroundColour = UIColor.black
    var completion: () -> Void = {}

    var player = AVPlayer()
    var skipImage: UIImage?
    var skipButton: UIButton?

    convenience init(video: URL, backgroundColour: UIColor = UIColor.black, skipImage: UIImage? = nil, completion: @escaping () -> Void = {}) {
        self.init()
        self.resource = video
        self.backgroundColour = backgroundColour
        self.completion = completion
        self.skipImage = skipImage
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColour
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.moviePlayback, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.view.backgroundColor = backgroundColour
        
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame

        let asset = AVAsset(url: resource!)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        if let image = skipImage {
            let button = UIButton(type: .custom)
            skipButton = button
            button.setImage(image, for: .normal)
            view.addSubview(button)
            button.addTarget(self, action: #selector(self.skip(_:)), for: .touchUpInside)
            button.frame.size = CGSize(width: 60.0, height: 60.0)
            showSkipButton()
            view.bringSubviewToFront(button)
        }
    }
    
    func showSkipButton(screenSize: CGSize = screenSize()) {
        guard let button = skipButton else {
            return
        }
        
        button.frame.origin = CGPoint(x: screenSize.width - button.frame.size.width - 10.0, y: screenSize.height - button.frame.size.height - 20.0)
        button.isHidden = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showSkipButton(screenSize: size)
    }
    
    @objc func skip(_ sender: UIButton) {
        player.pause()
        playerDidFinishPlaying()
    }

    @objc func playerDidFinishPlaying() {
        if let controller = navigationController {
            controller.popViewController(animated: false)
        }
        else {
            dismiss(animated: false)
        }
        completion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        player.play()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}
