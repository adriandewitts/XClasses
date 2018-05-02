//
//  VideoController.swift
//  Bookbot
//
//  Created by Adrian on 14/3/18.
//  Copyright © 2018 Bookbot. All rights reserved.
//

import UIKit
import AVKit

class VideoController: UIViewController {
    var resource: URL?
    var backgroundColour = UIColor.black
    var completion: () -> Void = {}

    var playerLayer: AVPlayerLayer!
    var player = AVPlayer()

    convenience init(video: URL, backgroundColour: UIColor = UIColor.black, completion: @escaping () -> Void = {}) {
        self.init()
        self.resource = video
        self.backgroundColour = backgroundColour
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColour
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        playerLayer = AVPlayerLayer(player: player)
        view.layer.insertSublayer(playerLayer, at: 0)

        let asset = AVAsset(url: resource!)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)

        NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
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
        playerLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}
