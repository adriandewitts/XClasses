//
//  GoogleSpeechController.swift
//  Bookbot
//
//  Created by Adrian on 30/7/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//

import UIKit
import Speech
import AudioKit
import AssistantKit

class GoogleSpeechController: NSObject {
    let microphone: AKMicrophone?
    var response: (_ transcription: String) -> Void = {_ in}
    let host = "speech.googleapis.com"
    var apiKey: String {
        return "API_KEY"
    }

    // MARK: Setup

    override init() {
        AKSettings.audioInputEnabled = true
        AKSettings.sampleRate = 32000
        AKSettings.channelCount = 1
        microphone = AKMicrophone()

        // Use front microphone or default
        if Device.isDevice, var device: AKDevice = AudioKit.inputDevices?.first {
            for d in AudioKit.inputDevices! {
                if d.deviceID.contains("Front") {
                    device = d
                }
            }
            try? microphone?.setDevice(device)
        }

        super.init()
    }

    func start(context: [String] = [], response: @escaping (_ transcription: String) -> Void) {
        self.response = response
        configureRecogniser(context: context)
        microphone?.avAudioNode.installTap(onBus: 0, bufferSize: 1024, format: AudioKit.format) { buffer, time in
            //self.speechRecognition.append(buffer)
        }

        AudioHelper.start()
    }

    /// Stops audio input and speech recognition
    func stop() {
        AudioHelper.stop()
        microphone?.avAudioNode.removeTap(onBus: 0)
        //speechRecognition.endAudio()
    }

    // TODO: Respond with human readable errors for authorisations

    class func authoriseMicrophone() {
        _ = AKMicrophone()
    }

    func configureRecogniser(context: [String])
    {

    }
}
