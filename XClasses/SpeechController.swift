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

class SpeechController: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, SFSpeechRecognitionTaskDelegate
{
    let microphone = AKMicrophone()
    var speechRecognition: SFSpeechAudioBufferRecognitionRequest!
    var response: (_ transcription: String) -> Void = {_ in}

    // MARK: Setup

    override init()
    {
        AKSettings.audioInputEnabled = true
        AKSettings.sampleRate = 44100
        AKSettings.numberOfChannels = 1
        SpeechController.authoriseSpeech()

        super.init()
    }

    func start(context: [String] = [], response: @escaping (_ transcription: String) -> Void)
    {
        self.response = response
        self.prepareRecogniser(context: context)
        self.microphone.avAudioNode.installTap(onBus: 0, bufferSize: 1024, format: AudioKit.format, block: { buffer, time in
            self.speechRecognition.append(buffer)
        })

        AudioKit.start()
    }

    func stop()
    {
        AudioKit.stop()
        self.microphone.avAudioNode.removeTap(onBus: 0)
        speechRecognition.endAudio()
    }

    // TODO: Respond with human readable errors for authorisations

    class func authoriseMicrophone()
    {
        _ = AKMicrophone()
    }

    class func authoriseSpeech()
    {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                print("Authorised")
            case .denied:
                print("User denied access to speech recognition")
            case .notDetermined:
                print("Speech recognition not yet authorized")
            case.restricted:
                print("User Authorization Issue.")
            }
        }
    }

    func prepareRecogniser(context: [String])
    {
        // TODO: Get locale from current user settings
        let locale = NSLocale(localeIdentifier: "en_EN")
        let recogniser = SFSpeechRecognizer(locale: locale as Locale)!

        self.speechRecognition = SFSpeechAudioBufferRecognitionRequest()
        self.speechRecognition.taskHint = .dictation
        self.speechRecognition.contextualStrings = context

        recogniser.recognitionTask(with: self.speechRecognition, delegate: self)
    }


    // MARK: Callback

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription)
    {
        self.response(transcription.formattedString)
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
