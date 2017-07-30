//
//  SpeechController.swift
//  Bookbot
//
//  Created by Adrian on 26/5/17.
//  Copyright © 2017 Adrian DeWitts. All rights reserved.
//
import UIKit
import Speech
import AudioKit
import AssistantKit

class SpeechController: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, SFSpeechRecognitionTaskDelegate {
    let microphone: AKMicrophone
    var speechRecognition: SFSpeechAudioBufferRecognitionRequest!
    var response: (_ transcription: String) -> Void = {_ in}

    // MARK: Setup

    override init() {
        AKSettings.audioInputEnabled = true
        AKSettings.sampleRate = 44100
        AKSettings.numberOfChannels = 1
        SpeechController.authoriseSpeech()
        microphone = AKMicrophone()

        // Use front microphone or default
        if Device.isDevice, var device: AKDevice = AudioKit.inputDevices?.first {
            for d in AudioKit.inputDevices! {
                if d.deviceID.contains("Front") {
                    device = d
                }
            }
            try? microphone.setDevice(device)
        }

        super.init()
    }

    func start(context: [String] = [], response: @escaping (_ transcription: String) -> Void) {
        self.response = response
        configureRecogniser(context: context)
        microphone.avAudioNode.installTap(onBus: 0, bufferSize: 1024, format: AudioKit.format) { buffer, time in
            self.speechRecognition.append(buffer)
        }

        AudioKit.start()
    }

    /// Stops audio input and speech recognition
    func stop() {
        AudioKit.stop()
        microphone.avAudioNode.removeTap(onBus: 0)
        speechRecognition.endAudio()
    }

    // TODO: Respond with human readable errors for authorisations

    class func authoriseMicrophone() {
        _ = AKMicrophone()
    }

    class func authoriseSpeech()
    {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Authorised")
                // Do nothing
            case .denied:
                print("User denied access to speech recognition")
                // Modal
            case .notDetermined:
                print("Speech recognition not yet authorized")
                // Send error to logs
            case.restricted:
                print("User Authorization Issue.")
                // Send error to logs
            }
        }
    }

    func configureRecogniser(context: [String] = [])
    {
        // TODO: If locale language is different from book - set to en_EN
        let recogniser = SFSpeechRecognizer()!
        speechRecognition = SFSpeechAudioBufferRecognitionRequest()
        speechRecognition.taskHint = .dictation
        if context.count > 0 {
            speechRecognition.contextualStrings = context
        }

        recogniser.recognitionTask(with: speechRecognition, delegate: self)
    }


    // MARK: Callback

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription)
    {
        response(transcription.formattedString)
    }


    // TODO: Cleanup
//    func transcribeSpeechFromFile(url: URL, response: @escaping (_ transcription: String) -> Void)
//    {
//        guard let recogniser = SFSpeechRecognizer() else
//        {
//            // A recognizer is not supported for the current locale
//            return
//        }
//        if !recogniser.isAvailable
//        {
//            // The recognizer is not available right now
//            return
//        }
//
//        let request = SFSpeechURLRecognitionRequest(url: url)
//        recogniser.recognitionTask(with: request) { (result, error) in
//            guard let result = result else
//            {
//                // Recognition failed, so check error for details and handle it
//                return
//            }
//            //print("\(result.bestTranscription.formattedString)")
//
//            result.bestTranscription.formattedString
//
////            for segment in result.bestTranscription.segments
////            {
////                print("------------------------------------------------------")
////                print("'\(segment.substring)'\n duration: \(segment.duration) confidence: \(segment.confidence) ts: \(segment.timestamp) range: \(segment.substringRange)")
////            }
//        }
//    }
}
